# Plan: install-dependencies.sh tune-up handoff

## Context

The rewrite from handoff 02 is done. Handoff 03 lists 5 follow-up items. Three are worth implementing: the script-install pipe function is a no-op, cargo install errors are noisy in the fallback chain, and priority detection for rustup/uv could miss PATH-installed versions. One item (command -v vs is_installed) is not actually a bug.

## Item-by-item analysis

### 1. `install_via_script_install` is a no-op (line 559-564)

**Real issue.** The function returns 1 unconditionally. The old `install.sh` `try_install_script()` (lines 449-505) has the pipe logic with:
- `pipe:` prefix detection
- `curl -fsSL <url>` fetch + pipe through `sh`
- `{version}` placeholder resolution from parent tool

**Fix**: Add `SCRIPT_INSTALL_URLS` associative array (like `SCRIPT_DOWNLOAD_URLS`), implement `install_via_script_install` with the pipe logic from the old script. Currently no packages use it (SCRIPT_INSTALL_PACKAGES is empty), but the function should be ready.

### 2. Cargo error noise in fallback chain

**Minor issue.** `install_via_cargo` shows a red "Failed" message when cargo install fails. In the fallback chain this is normal — system PM is the next step. The message is misleading.

**Fix**: In `install_via_cargo`, suppress the error message on failure (just `return 1` silently). Log still captures details. Or downgrade to yellow info message.

### 3. Populate empty arrays (stubs)

**No action.** SECONDARY_PACKAGES, UV_PACKAGES, SCRIPT_INSTALL_PACKAGES are for future use.

### 4. Priority detection (rustup/uv)

**Real issue.** `DETECT_COMMANDS` checks rustup at `~/.rustup/rustup-init` and uv at `~/.local/bin/uv`. If the user already has rustup/uv in PATH (via system PM or manual install), the path check misses it.

`is_installed()` checks DETECT_COMMANDS first and returns immediately — never falls through to `command -v`.

**Fix**: Update the detect commands to also check `command -v`:
```
[rustup]="command -v rustup &>/dev/null || test -x \"\$HOME/.rustup/rustup-init\""
[uv]="command -v uv &>/dev/null || test -x \"\$HOME/.local/bin/uv\""
```

Or swap the order in `is_installed` to check `command -v` before DETECT_COMMANDS. But ohmyzsh needs DETECT_COMMANDS first (it's not a command). Safer to just update rustup/uv detect strings.

### 5. `command -v` vs `is_installed` consistency

**Not an issue.** The `install_via_cargo/npm/uv` functions use `command -v cargo/npm/uv` to check if the INSTALL TOOL exists, not the target package. This is correct. The target package is checked via `is_installed` in the main loop (line 743). Close as won't fix.

## Handoff update

Update `03-install-dependencies-tuneup.md` in-place — append a **"## Solutions"** section with fix details for each actionable item (1, 2, 4). Item 5 gets noted as closed. No new handoff file needed.

1. **Script install pipe** — add `SCRIPT_INSTALL_URLS` array, implement `install_via_script_install` with curl | sh pipe logic from old `try_install_script()`
2. **Cargo error suppression** — downgrade or suppress the "Failed to install via cargo" red message
3. **Priority detection** — update rustup/uv `DETECT_COMMANDS` to also check `command -v`
4. **Item 5** — note as closed, no change needed

## Files to change

- `zsh/.local/share/zsh/install-dependencies.sh`
