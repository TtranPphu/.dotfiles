# General Observations (non-blocking)

## Hyprland

- **Fractional scaling 1.6** on HDMI-A-1 (`monitors.conf:6`) can cause blurry text in XWayland apps.
- **Lock timer comment misleading** — comment says "5 minutes" but actual timeout is ~2.5 min (screensaver reset commented out).
- **`hyprctl keyword env` GDK_SCALE in toggle script** — has no runtime effect (still present, dead code).
- **Hard Omarchy deps** — edit `source = ~/.local/share/omarchy/...` to `source = ~/.config/omarchy/current/...` if theme paths change.

## Tmux

- **`rebalance-layout` heuristic** (comparing `pane_top`/`pane_left` uniqueness) won't fire for irregular grid layouts — exits without applying layout (intended).
- **`session-info` uses bash 4 `mapfile`** — fine on Linux, won't work on macOS bash 3.
- **`status-hint` script** (107 lines) still fully dead code (commented out in tmux.conf).

## Neovim

- **`copilot.lua`** has both `cmp.enabled = true` and `panel.enabled = true` with `suggestion.enabled = false`. Both blink.cmp copilot source and the copilot panel may show suggestions simultaneously.

## Git

- **`defaultBranch = master`** — most modern tools default to `main` now. Preference only.

## Ghostty

- **`font-size = 9`** at 200% scaling renders ~18px effective. At 100% scaling, very small. Worth noting if scaling changes.

## Nvim

- **14 stale lock entries** from old nvim-cmp ecosystem still in `nvim-pack-lock.json`.
- **`<C-\>` mapping** for Neo-tree close may be intercepted by terminal/tmux.

## Yazi / Eza / Bat / GDU / XDG Terminal Exec / Zellij

- No issues in any of these.

## Walker

- CSS `@import` dependency on Omarchy (same pattern as Waybar).
