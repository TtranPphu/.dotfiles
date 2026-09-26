# Desktop Config

Compositors, bars, launchers, file manager, and the theme system. See `terminal.md` for terminal-only tools.

## Compositors

- **Hyprland** (primary) — Modular config sources in `hypr/.config/hypr/`:
  - `hyprland.conf` sources Omarchy defaults first, then local overrides (`monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `windows.conf`, `autostart.conf`, `app.conf`).
  - Don't edit Omarchy-owned paths (`~/.local/share/omarchy/`). Override by sourcing local files.
  - `unbind` before replacing Omarchy keybindings.
  - App rules go in `apps/*.conf`.
  - Additional: `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `xdph.conf`.

## Bars & launchers

- **Walker** — Themes in `themes/omarchy-default/`.

## File manager

- **Yazi** — `keymap.toml` for keybindings, `theme.toml` for theming (Omarchy-integrated).

## Omarchy

Hyprland, Walker, and Yazi integrate with Omarchy (theme system, `omarchy-*` commands). Test against the active Omarchy theme (`~/.local/state/omarchy/current/theme/`) when modifying any of these.
