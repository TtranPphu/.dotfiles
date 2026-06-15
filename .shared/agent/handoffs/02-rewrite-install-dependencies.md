# Handoff: Rewrite install.sh → install-dependencies.sh

## Context

Rewrite `zsh/.local/share/zsh/install.sh` into `zsh/.local/share/zsh/install-dependencies.sh` with clearer structure. Original `install.sh` stays as backup (not deleted).

## What changed conceptually

- **Renamed** `*_TOOLS` → `*_PACKAGES` everywhere
- **Removed** Wayland (`hyprland`, `waybar`, `walker`, `niri`), GUI, and terminal (`ghostty`) — user installs those manually
- **Added** `UV_PACKAGES`, `SECONDARY_PACKAGES` (AUR/brew), `SCRIPT_DOWNLOAD_PACKAGES`, `GIT_PACKAGES`
- **Split** script packages into `SCRIPT_INSTALL_PACKAGES` (curl | sh pipe) and `SCRIPT_DOWNLOAD_PACKAGES` (curl → `~/.local/bin`)
- **Added** `PACKAGE_OVERRIDES` associative array for per-PM package names (replaces old `get_package_name()` case statement)
- **ohmyzsh** moved into `PRIORITY_PACKAGES` with explicit curl | sh logic

## Package category arrays

| Priority | Array | Method | Contents |
|----------|-------|--------|----------|
| 1 | `PRIORITY_PACKAGES` | Custom curl \| sh + setup | `rustup`, `uv`, `ohmyzsh` |
| 2 | `CARGO_PACKAGES` | `cargo install` | `bat`, `eza`, `starship`, `fd`, `ripgrep`, `aichat`, `zoxide`, `zellij`, `nu`, `argc` |
| 3 | `SYSTEM_PACKAGES` | Primary PM (pacman > apt > dnf > zypper > apk) | `tmux`, `nvim`→neovim, `zsh`, `yazi`, `gdu`, `fzf`, `lazygit`, `lazydocker`, `stow`→gnu-stow, `jq`, `bat`, `eza`, `ripgrep`, `zoxide` |
| 4 | `SECONDARY_PACKAGES` | 2nd-class PM (yay > paru > brew) | *(AUR/brew alternatives)* |
| 5 | `UV_PACKAGES` | `uv tool install` | *(future)* |
| 6 | `NPM_PACKAGES` | `npm install -g` | `neovim` |
| 7 | `SCRIPT_INSTALL_PACKAGES` | curl \| sh (pipe) | *(future)* |
| 8 | `SCRIPT_DOWNLOAD_PACKAGES` | curl → `~/.local/bin` + chmod | `fzf-tmux` |
| 9 | `GIT_PACKAGES` | `git clone <url> <dir>` | `zsh-autosuggestions`, `zsh-syntax-highlighting` |

## Auxiliary arrays

- `COMMAND_NAMES` — `command -v` aliases: `bat`→`batcat`, `ripgrep`→`rg`
- `DETECT_COMMANDS` — custom detection: `ohmyzsh`→`test -d ~/.oh-my-zsh`
- `PACKAGE_OVERRIDES` — per-PM package names: `[apt:bat]="batcat"`, `[apt:fd]="fd-find"`
  - `get_system_package_name(pm, tool)` checks overrides first, then `SYSTEM_PACKAGES`, then tool key

## Install method fallback chain

Priority packages run FIRST. For each remaining missing package, try:

1. **Cargo** — if in `CARGO_PACKAGES`
2. **Primary PM** — if in `SYSTEM_PACKAGES` (sudo for non-brew)
3. **2nd-class PM** — if in `SECONDARY_PACKAGES`
4. **UV** — if in `UV_PACKAGES`
5. **NPM** — if in `NPM_PACKAGES`
6. **Script install** — if in `SCRIPT_INSTALL_PACKAGES`
7. **Script download** — if in `SCRIPT_DOWNLOAD_PACKAGES`
8. **Git clone** — if in `GIT_PACKAGES`

## Script flow

1. Detect primary PM (pacman > apt > dnf > zypper > apk; fallback brew)
2. Detect 2nd-class PM (yay > paru > brew when not primary)
3. Init/read state (`~/.local/state/dotfiles/install-state.json`)
4. Collect missing packages across all arrays
5. Prompt user (y/n/A/N single-key)
6. Install priority packages (rustup, uv, ohmyzsh)
7. For each remaining missing package: try methods 1-8
8. Report results

## State management

Reuse existing `install.sh` logic: `init_state()`, `get_preference()`, `update_preference()`, `add_attempted()`. State file at `~/.local/state/dotfiles/install-state.json`.

## Files to change

| File | Action |
|------|--------|
| `zsh/.local/share/zsh/install.sh` | Keep as backup |
| `zsh/.local/share/zsh/install-dependencies.sh` | **Create** |
| `zsh/.zshrc` line 125-127 | `install.sh` → `install-dependencies.sh` |

## Build from

Read `zsh/.local/share/zsh/install.sh` for existing infra (state management, prompting, colors, logging, sudo handling, cargo/npm install functions). Most of it is reusable with renamed arrays.
