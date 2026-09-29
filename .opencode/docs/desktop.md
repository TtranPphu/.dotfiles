# Desktop Config

Compositors, bars, launchers, file manager, and the theme system. See `terminal.md` for terminal-only tools.

## Compositors

- **Hyprland** (primary) — Lua config in `hypr/.config/hypr/`, loaded after Omarchy's defaults:
  - `hyprland.lua` loads the Omarchy defaults, then the rest of the user files.
  - User files: `bindings.lua`, `looknfeel.lua`, `monitors.lua`, `input.lua`, `autostart.lua`.
  - Also `hyprsunset.conf` (night light — apply with `omarchy restart hyprsunset`) and `xdph.conf` (screen sharing — applies when the portal restarts).
  - `hypr-legacy/` holds the retired `.conf` config. Reference only: do not edit or deploy it.
  - Unbind before replacing an Omarchy binding: `hl.unbind(key)` then `o.bind(key, desc, command)` or `hl.bind(key, hl.dsp.*, opts)`.
  - Never edit Omarchy-owned paths (`/usr/share/omarchy/`) — reading them is fine. Override in the user files.
  - Validate every change with `hyprctl reload` then `hyprctl configerrors`.
  - Omarchy persists per-workspace layouts under `~/.local/state/omarchy/workspace-layouts/`; those rules override `general.layout`.

## Bars & launchers

- **Omarchy shell** (Quickshell) — the bar and its widgets. Bar layout lives in `~/.config/omarchy/shell.json`, which hot-reloads on save.
  - Never edit the built-in plugins under `/usr/share/omarchy/shell/plugins/`. Clone one first (`omarchy plugin clone omarchy.workspaces`), which switches the bar to the clone, then edit the clone under `~/.config/omarchy/plugins/`.
  - Clones are tracked by the `omarchy` stow package, so they survive updates and are version-controlled.
- **Walker** — Themes in `themes/omarchy-default/`.

## File manager

- **Yazi** — `keymap.toml` for keybindings, `theme.toml` for theming (Omarchy-integrated). Its UI draws from the ANSI palette, so it follows the terminal and Omarchy theme.

## Omarchy

Hyprland, the Omarchy shell, Walker, and Yazi integrate with Omarchy (theme system, `omarchy-*` commands). Test against the active Omarchy theme (`~/.local/state/omarchy/current/theme/`) when modifying any of these. Run `omarchy commands` to discover the CLI.
