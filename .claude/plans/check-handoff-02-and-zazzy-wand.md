# Test Plan: install-dependencies.sh (Docker-based)

## Context

Handoff 02 rewrote `install.sh` → `install-dependencies.sh` with restructured arrays, new package categories, and an 8-step fallback chain. Handoff 03 tuned it up: implemented `install_via_script_install`, silenced cargo errors on failure, and improved rustup/uv detection. Both are now committed.

Testing should run in Docker containers across distros to validate the fallback chain and detection logic without touching the host machine.

## Distro Matrix

Spin up containers for each primary PM type (non-interactive, no TTY needed):

| Distro | PM | Tests Focus |
|--------|----|-------------|
| archlinux:latest | pacman | Full fallback chain, PACKAGE_OVERRIDES (nvim→neovim, stow→gnu-stow) |
| ubuntu:24.04 | apt | COMMAND_NAMES (bat→batcat, rg→ripgrep), OVERRIDES (fd→fd-find, batcat, neovim) |
| fedora:latest | dnf | OVERRIDES (neovim, batcat, gnu-stow) |
| alpine:latest | apk | Minimal env — verify script detects apk and uses OVERRIDES (neovim, gnu-stow) |

## Test Categories to Run Per Container

Each container gets the script mounted in, then we run test blocks via `docker exec` or inline in a setup script.

### 1. Syntax & Structure

```bash
bash -n /install-dependencies.sh
```

Run in every container — cheap sanity check.

### 2. Detection Logic

For each distro, source the script and call `is_installed` with:
- Known-installed commands (bash, coreutils)
- COMMAND_NAMES aliases (install `batcat` on ubuntu, check `is_installed bat` returns 0)
- DETECT_COMMANDS: `ohmyzsh` returns 1 initially, `rustup` returns 1 initially
- Non-existent pkg returns 1

### 3. State File

- Create empty `install-state.json` in temp location
- Copy the script, edit `STATE_FILE` to point to temp path
- Run once with missing tools, press `N` → verify file has `"preference": "never"`
- Re-run → verify no install attempt, exits cleanly

### 4. Fallback Chain Per PM

Each container tests PM-specific install:

- **Priority** (rustup/uv/ohmyzsh): verify `install_priority` runs curl | sh for each
- **System PM**: install a missing system tool (e.g., `jq`), verify `install_via_system_pm` succeeds
- **PACKAGE_OVERRIDES**: verify `get_system_package_name pacman nvim` returns `neovim`, `get_system_package_name apt bat` returns `batcat`, etc.
- **Cargo**: install cargo in the container, then test `install_via_cargo` on a small crate (e.g., `argc`)

### 5. Script Download (fzf-tmux)

- Install `fzf` via system PM (so `fzf --version` works)
- Remove `~/.local/bin/fzf-tmux` if it exists
- Run full script → verify fzf-tmux is downloaded and executable at `~/.local/bin/fzf-tmux`

### 6. Git Clone (zsh plugins)

- Create `~/.oh-my-zsh/custom/plugins/` as empty dir
- Run full script → verify `zsh-autosuggestions` and `zsh-syntax-highlighting` are git-cloned into the right paths

### 7. No-op / Idempotency

- Run the script twice in a row on a fully-provisioned container
- First run may install things; second run must exit 0 with no output (no missing tools)
- Verify `$LOG_FILE` content length grows, not truncated

### 8. Interactive Prompt

- Test the `ask` → `always` flow: pipe `A` key to stdin, verify state file saved
- Test the `ask` → `never` flow: pipe `N` key to stdin, verify state file saved and no installs happen

## Implementation

Launch an agent with isolation (worktree) to:

1. Write a test runner script (`test-install-dependencies.sh`) that:
   - Builds each Docker image with the script mounted in
   - Runs test blocks inside each container
   - Collects pass/fail results per category
   - Exports a summary

2. Execute it and report results.

## Container Setup Notes

- Arch: `pacman -Syu --noconfirm bash coreutils curl git jq fzf`
- Ubuntu: `apt-get update && apt-get install -y bash coreutils curl git jq fzf`
- Fedora: `dnf install -y bash coreutils curl git jq fzf`
- Alpine: `apk add bash coreutils curl git jq fzf`

For Cargo tests: install rustup first (which itself tests the priority install path).
For system PM install tests: don't pre-install the test target package.
