# Handoff: install-dependencies.sh tune-up

## Context

Completed the 02 handoff: rewrote `install.sh` → `install-dependencies.sh` with renamed arrays, removed Wayland/GUI/terminal packages, added new categories (UV, SECONDARY, GIT, split SCRIPT_INSTALL/SCRIPT_DOWNLOAD), added `PACKAGE_OVERRIDES`, moved ohmyzsh into `PRIORITY_PACKAGES`. Original `install.sh` preserved as backup.

## What's Done

- **Created** `zsh/.local/share/zsh/install-dependencies.sh` (836 lines, 21k)
- **Updated** `zsh/.zshrc` lines 124-127 to reference `install-dependencies.sh`
- **Original** `install.sh` left in place (16k, executable)

## What Could Be Next

### 1. Verify the fallback chain in practice

The 8-step fallback chain (cargo → system PM → secondary PM → uv → npm → script install → script download → git) is implemented but untested on actual machines. The Cargo check iterates `CARGO_PACKAGES` but calls cargo for every matching pkg — cargo itself will fail for packages not in crates.io (e.g. `nvim`), which is fine (it falls through), but noisy. Consider whether failed `cargo install` attempts should suppress the error message and just return 1 silently.

### 2. Populate empty arrays

These arrays are empty stubs:
- `SECONDARY_PACKAGES` — AUR/brew-only packages go here
- `UV_PACKAGES` — `uv tool install` candidates
- `SCRIPT_INSTALL_PACKAGES` — candidates for `curl | sh` (other than prio packages)

### 3. `install_via_script_install` is a no-op

The function at line ~760 always returns 1. It needs to implement the `pipe:` logic from the old `try_install_script()` in `install.sh` (lines 449-505) for `SCRIPT_INSTALL_PACKAGES`. Currently nothing is in that array so it doesn't matter.

### 4. Priority package detection

`DETECT_COMMANDS` for `rustup` and `uv` check the install target path rather than `command -v`. This is correct for initial install (binary isn't in PATH yet) but could be wrong if the user removed the tool dir without cleaning state. Consider adding a PATH check too.

### 5. `command -v` vs `is_installed` consistency

In `install_via_cargo`, `install_via_uv`, `install_via_npm`, the check uses `command -v` directly rather than `is_installed`. This means `DETECT_COMMANDS` custom logic is bypassed for these install methods. Currently none of the cargo/uv/npm packages have custom detect entries so it doesn't matter, but worth noting.
