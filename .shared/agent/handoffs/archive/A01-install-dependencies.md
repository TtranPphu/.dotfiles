# Install-dependencies

## Summary

Rewrote `install.sh` → `install-dependencies.sh` with a structured 8-step fallback chain (cargo → system PM → secondary PM → uv → npm → script install → script download → git clone) for cross-distro tool provisioning. Uses package category arrays, per-PM name overrides, and persistent install state. Tested via Docker across archlinux/ubuntu/fedora/alpine — 60/61 tests pass.

## Files

- `zsh/.local/share/zsh/install-dependencies.sh` — the script (866 lines)
- `zsh/.local/share/zsh/test-install-dependencies.sh` — Docker test runner (660 lines)
- `zsh/.local/share/zsh/install.sh` — original, kept as backup
- `zsh/.zshrc` (lines 125-127) — invokes script on shell start

## Key decisions

- Single-file self-contained script, no external dependencies beyond basic POSIX tools
- Package overrides per PM (`nvim`→`neovim`, `bat`→`batcat`) via associative array, not a case statement
- Duplicate packages across cargo + system PM are intentional (cargo tried first, falls through)
- State file at `~/.local/state/dotfiles/install-state.json` for idempotency (always/never/attempted)
- Wayland, GUI, and terminal packages removed — user installs those manually

## Future iteration notes

- Populate empty stubs: `SECONDARY_PACKAGES`, `UV_PACKAGES`, `SCRIPT_INSTALL_PACKAGES`
- Priority installs (rustup/uv/ohmyzsh) untested in Docker (needs network in container)
- Cargo install test skipped (compilation too slow) — verify via function mock only
- `command -v` vs `is_installed` discrepancy for cargo/npm/uv methods (low priority, no affected packages)
