# Repository Overview

This is a GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose directory structure mirrors the final target paths in `$HOME`. For example, `hypr/.config/hypr` deploys to `~/.config/hypr`, `nvim/.config/nvim` to `~/.config/nvim`, and `zsh/.zshrc` to `~/.zshrc`.

**Core principle:** Keep new files inside the existing package structure so they can be deployed with `stow <package-name>` without requiring additional relocation logic.

## Desktop Environment

**Hyprland** (`hypr/`) is the main desktop entrypoint. Configuration is layered in this order:
1. Omarchy defaults from `~/.local/share/omarchy/default`
2. Active Omarchy theme from `~/.config/omarchy/current/theme`
3. Local overrides from this repo (`monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`)
4. Runtime toggle fragments from `~/.local/state/omarchy/toggles/hypr/*.conf`

Keep edits in local override files, not in Omarchy-owned paths. App-specific Hypr rules belong in `hypr/.config/hypr/apps/*.conf` and are sourced via `app.conf`, not mixed into `hyprland.conf`.

**Niri** (`niri/`) is an alternative compositor config in `niri/.config/niri/config.kdl`. Maintain separate window manager configs; the active one is set at system startup.

## UI and Theming

**Waybar** (`waybar/`) is the system taskbar. Its config integrates with Omarchy:
- `config.jsonc` uses `omarchy-*` commands for menu, updates, Wi-Fi, audio, idle, notifications, and screen recording
- `style.css` imports the current Omarchy theme CSS
- Preserve these integrations unless intentionally replacing the Omarchy workflow

**Walker** (`walker/`) is the application launcher. Themes are stored in `walker/.config/walker/themes/omarchy-default/` to integrate with Omarchy theme switching.

**Yazi** (`yazi/`) is the file manager with keybinds in `keymap.toml` and theme in `theme.toml`. Theming typically matches the active Omarchy theme.

## Shell and Prompts

**Zsh** (`zsh/`) is the primary shell. Startup sequence:
1. `zsh/.zshrc` loads Oh My Zsh first
2. Then initializes Starship and sets `STARSHIP_CONFIG` to `starship/.config/starship/starship.toml`
3. Modular Zsh configs are in `zsh/.config/zsh/` (e.g., `eza.zsh`)

**bat vs batcat:** On Debian/Ubuntu the command is `batcat`. Check for both in scripts.

## Editors and Tools

**Neovim** (`nvim/`) is a Kickstart-based distribution:
- Only work in `lua/custom/plugins/*.lua`. Don't touch `init.lua`.
- Plugin versions are pinned in `nvim-pack-lock.json`
- Stylua style: 2-space indent, single quotes, omit call parens where valid

**Bat** (`bat/`) — syntax-highlighting pager. Config in `bat/.config/bat/config`.

**Eza** (`eza/`) — modern `ls` replacement. Theme in `eza/.config/eza/theme.yml`.

## Other Utilities

- **Ghostty** (`ghostty/`) — Terminal emulator config at `ghostty/.config/ghostty/config`
- **Gdu** (`gdu/`) — Disk usage analyzer configured in `gdu/.gdu.yaml`
- **Starship** — Helper scripts beside `starship.toml`, sourced via `$STARSHIP_CONFIG`-relative resolution

## Key Conventions

- **Top-level package structure is stow-friendly.** Add files under the package that owns their final target path.
- Mirror the structure: `<package>/.config/<tool>/` → `~/.config/<tool>/`.
- Each package is independently deployable via `stow <package>` from the dotfiles root.
- **Shell scripts:** Bash shebang, 2-space indentation. Format with `shfmt -i 2`.
- **Never auto-commit.** Only commit when explicitly asked.

## Hyprland

- Override Omarchy defaults by sourcing local files; do not edit Omarchy-owned paths.
- When replacing an Omarchy keybinding, `unbind` the original first.
- App rules in `hypr/.config/hypr/apps/*.conf`, sourced via `app.conf`.

## Neovim

- Only work in `lua/custom/plugins/*.lua`. Do not edit `init.lua`.
- Each file is a plugin spec loaded via `require 'custom.plugins'` in `init.lua`.
- Plugin versions pinned in `nvim-pack-lock.json`. Update via `:lua vim.pack.update()` inside Nvim.

## Tmux

- Config in `tmux/.config/tmux/tmux.conf` sourcing `bindings.conf` and `theme.conf`.
- Helper scripts in `scripts/`. Pane output auto-logs to `~/.local/state/tmux/pane-logs/`.
- Gate `extended-keys-format` behind tmux >= 3.5.

## Starship

- Main config in `starship/.config/starship/starship.toml`.
- Helper scripts in `starship/.config/starship/` (battery helpers, compress-path, compress-date).
- Scripts sourced relative to `$STARSHIP_CONFIG`; keep them beside `starship.toml`.

## Zsh

- `zsh/.zshrc` loads Oh My Zsh, then modular configs in `zsh/.config/zsh/*.zsh` → Starship.
- Oh My Zsh theme is disabled; Starship is the primary prompt.
- Auto-attaches tmux on login if not already in a tmux session.

## Omarchy Integration

Hyprland, Waybar, Walker, and Yazi integrate with Omarchy theme and commands:
- **Hyprland:** Layers Omarchy defaults, local overrides, app rules
- **Waybar:** Uses `omarchy-*` commands for dynamic features; imports theme CSS
- **Walker:** Themes in `omarchy-default/` for consistency
- **Yazi:** Typically matches active Omarchy theme

When modifying these, test against the active Omarchy theme and preserve command/path references unless intentionally replacing the workflow.
