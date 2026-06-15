# Handoff: Compositor Switching (Niri / Hyprland)

## Goal

Allow the user to switch between Niri and Hyprland compositors at session start. Currently SDDM auto-logins into `omarchy` (uwsm-managed Hyprland). Niri is installed with a full config but no way to select it without manually editing `/etc/sddm.conf.d/autologin.conf`.

## Deliverables — Done

### 1. `session-switch` script ✅

**Path:** `zsh/.local/bin/session-switch`

CLI tool to change SDDM autologin session. Goes in the `zsh` stow package — `~/.local/bin/` is already in PATH (confirmed by `env.zsh` sourcing it).

Behaviors:
- `session-switch` — prints current session + usage
- `session-switch niri` — writes `Session=niri` to `/etc/sddm.conf.d/autologin.conf`
- `session-switch omarchy` — writes `Session=omarchy`
- `session-switch --menu` — interactive fzf selection
- Idempotent: no-op if already set to target
- Preserves `[Theme] Current=omarchy` line
- Must use `sudo tee` to write (file is root-owned, shell redirect with sudo fails)
- **Added `Timeout=10`** to `[Autologin]` section so SDDM shows a countdown, giving time to press Escape and select a different session.

### 2. Niri-specific waybar config ✅

**Path:** `waybar/.config/waybar/config-niri.jsonc`

Copy of `config.jsonc` with two changes:
- `modules-left`: `"hyprland/workspaces"` → `"niri/workspaces"`
- `"hyprland/workspaces"` block → `"niri/workspaces"` block. Key difference: `"focused"` icon key instead of Hyprland's `"active"`. Niri also supports `"urgent"`.

### 3. Niri config updates ✅

**Path:** `niri/.config/niri/config.kdl`

a) **Cursor theme** — Fixed syntax from `cursor-theme { name ... size ... }` to correct `cursor { xcursor-theme "..." xcursor-size ... }` (Niri 26.04 doesn't support the former).

b) **Output configuration** — Both displays explicitly configured:
   - `HDMI-A-1` (external): scale 1.6, position x=0 y=0
   - `eDP-2` (internal): scale 2, position x=435 y=900 (centered below external)

c) **Startup services** — Added: mako, swaybg, fcitx5, polkit-gnome, hypridle, elephant, `walker --gapplication-service`

d) **Keybindings** — Fully ported from Hyprland to Niri (see Keybindings section below).

e) **Window rules** — Added `open-maximized false` + `default-column-width { proportion 0.8; }` for Chromium to prevent full-width on launch. General rule applies `default-column-width { proportion 0.8; }` to all windows.

### 4. Display toggle script ✅

**Path:** `niri/.config/niri/scripts/toggle-internal-display.sh`

`Super + Ctrl + Delete` toggles the internal laptop display (eDP-2) on/off. Only toggles if another display is active (won't leave you without a screen). After turning off the internal display, focuses the first non-empty workspace (mimics Hyprland behavior).

## Keybindings (Ported from Hyprland)

| Category | Key | Action |
|---|---|---|
| Launcher | `Super+Space`, `Super+Alt+Space` | Walker (app launcher) |
| Terminal | `Super+Return` | Ghostty |
| Browser | `Super+Shift+Return`, `Super+Shift+B` | Chromium |
| Browser (private) | `Super+Shift+Alt+B` | Chromium incognito |
| File manager | `Super+Shift+F` | Yazi |
| Editor | `Super+Shift+E`, `Super+Shift+C` | VS Code |
| Neovim | `Super+Shift+N` | Ghostty + nvim |
| Obsidian | `Super+Shift+O` | Obsidian |
| Telegram | `Super+Shift+M` | Telegram |
| GitHub | `Super+Shift+G` | Chromium → GitHub |
| YouTube | `Super+Shift+Y` | Chromium → YouTube |
| 1Password | `Super+Slash` | 1Password |
| Clipboard | `Super+Ctrl+V` | Walker clipboard mode |
| Symbols | `Super+Ctrl+E` | Walker symbols mode |
| **Workspace nav** | `Super+W/K` | Focus workspace up |
| | `Super+S/J` | Focus workspace down |
| **Column nav** | `Super+A/H` | Focus column left |
| | `Super+D/L` | Focus column right |
| **Move window** | `Super+Shift+W/K` | Move window/or-to-workspace up |
| | `Super+Shift+S/J` | Move window/or-to-workspace down |
| | `Super+Shift+A/H` | Swap window left |
| | `Super+Shift+D/L` | Swap window right |
| Close window | `Super+Q` | Close window |
| Toggle float | `Super+T` | Toggle window floating |
| Fullscreen | `Super+F` | Fullscreen window |
| Maximize column | `Super+Ctrl+F` | Maximize column |
| Overview | `Super+O` | Toggle overview |
| Tabbed | `Super+G` | Toggle column tabbed display |
| Volume | `XF86AudioRaise/Lower/Mute` | `volume-active-sink.sh` (same as Hyprland) |
| Brightness | `XF86MonBrightnessUp/Down` | `brightnessctl` |
| Display toggle | `Super+Ctrl+Delete` | Toggle internal display |

## Deployment

```bash
stow zsh -d ~/.dotfiles -t ~
stow waybar -d ~/.dotfiles -t ~
stow niri -d ~/.dotfiles -t ~
```

## Ongoing Issues

1. **Walker desktop applications** — Walker (Super+Space) previously showed no results because the `elephant` backend was missing the `desktopapplications` provider config. Fixed by running `elephant generate config` which created `/home/ttranpphu/.config/elephant/desktopapplications.toml`. Need to verify `Super+Space` now shows apps.

2. **XDG_DATA_DIRS in Niri session** — Niri started directly by SDDM (without uwsm) may not have `XDG_DATA_DIRS` properly set. The terminal shows it as empty, which may affect app detection by Walker and other tools. If issues persist, add `systemctl --user set-environment XDG_DATA_DIRS=/usr/share:/usr/local/share` to startup.

3. **Missing `NIRI_SOCKET` env var** — The `NIRI_SOCKET` environment variable can get stale when switching terminal sessions. When running `niri msg` commands from a terminal that predates the current Niri instance, use `NIRI_SOCKET=$(ls -t /run/user/1000/niri* | head -1)` or find the socket manually.

4. **Hyprland-specific commands** — `omarchy-menu`, `omarchy-menu-keybindings`, `omarchy-launch-walker`, and other `omarchy-*` commands are not available in Niri (uwsm-dependent). Walker replaces the launcher role.

## Known Differences from Hyprland

- **No `layoutmsg togglesplit`** — Niri uses columns natively, no split-toggling concept.
- **No `hyprctl keyword env`** — Use `systemctl --user set-environment` instead for runtime env changes.
- **No `code:61` key name** — Niri uses XKB key names, not scan codes. The key below Escape can't be bound by scan code.

## Key Findings from Exploration

### Session management architecture
- **Display manager:** SDDM with autologin (`/etc/sddm.conf.d/autologin.conf` sets `Session=omarchy`)
- **Active session:** `/usr/local/share/wayland-sessions/omarchy.desktop` runs `uwsm start -g -1 -e -D Hyprland hyprland.desktop`
- **Niri session:** `/usr/share/wayland-sessions/niri.desktop` runs `/usr/bin/niri` (no uwsm)
- SDDM shows session menu if you press Escape during the autologin countdown

### Waybar config split
- Current `config.jsonc` uses `hyprland/workspaces` — won't work under Niri
- `style.css` is compositor-agnostic — no changes needed

### Omarchy autostart services (for reference)
The Omarchy Hyprland autostart spawns via `exec-once`:
```
uwsm-app -- hypridle
uwsm-app -- mako
uwsm-app -- waybar
uwsm-app -- fcitx5
uwsm-app -- swaybg
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
omarchy-first-run
omarchy-powerprofiles-init
uwsm-app -- omarchy-hyprland-monitor-watch
systemctl --user import-environment ...
dbus-update-activation-environment --systemd --all
sleep 2 && omarchy-hook post-boot
```
Not all of these translate to Niri — the handoff plan above covers the relevant subset.

### Niri's config already references
- `hyprlock` (for screen locking, line 445)
- `makoctl` (notification dismissal, lines 440-443)
- Walker, ghostty, etc. — all compositor-agnostic

### What was NOT changed / why
- **Hyprland configs:** Untouched (hyprland.conf, autostart.conf, bindings.conf, etc.)
- **Walker:** Compositor-agnostic, works under both
- **SDDM theme:** `Current=omarchy` kept regardless of compositor selection
- **omarchy.desktop:** Left as-is — it's the Hyprland session entry

## Potential Issues

1. **Environment variables:** Niri (started directly by SDDM, not uwsm) won't have Wayland env vars set by `hyprland.conf`. If apps run under XWayland instead of native Wayland, need `~/.config/environment.d/wayland.conf` (systemd user-level, compositor-agnostic).
2. **`hypridle` under Niri:** `hypridle` is a Hyprland project tool but works standalone as a D-Bus service. It reads `~/.config/hypr/hypridle.conf` which already exists and should work. If issues arise, `swayidle` is the more compositor-agnostic alternative.
3. **swaybg wallpaper path:** The path uses the Omarchy background. If Omarchy changes or isn't installed, this will fail to find an image. The user may want to adjust later.
4. **Stow conflicts:** If `~/.config/waybar/config-niri.jsonc` or `~/.local/bin/session-switch` already exist as regular files (not stow symlinks), stow will refuse. Pre-check with `ls -la` and remove orphaned files after verifying content.

## Verification

1. `ls -la ~/.local/bin/session-switch` — symlink to dotfiles
2. `ls -la ~/.config/waybar/config-niri.jsonc` — symlink to dotfiles
3. `session-switch` — prints current session
4. `session-switch niri` — changes autologin; verify with `grep ^Session /etc/sddm.conf.d/autologin.conf`
5. `session-switch omarchy` — changes back
6. `session-switch --menu` — interactive fzf
7. Reboot or logout, press Escape at SDDM, select Niri session
8. In Niri: verify waybar shows workspaces, mako running, hypridle running
