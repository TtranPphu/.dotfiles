# Handoff: Compositor Switching (Niri / Hyprland)

## Goal

Allow the user to switch between Niri and Hyprland compositors at session start. Currently SDDM auto-logins into `omarchy` (uwsm-managed Hyprland). Niri is installed with a full config but no way to select it without manually editing `/etc/sddm.conf.d/autologin.conf`.

## Deliverables

### 1. `session-switch` script

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
- Print a reminder about reboot or pressing Escape at SDDM after changing

### 2. Niri-specific waybar config

**Path:** `waybar/.config/waybar/config-niri.jsonc`

Copy of `config.jsonc` with two changes:
- `modules-left`: `"hyprland/workspaces"` → `"niri/workspaces"`
- `"hyprland/workspaces"` block → `"niri/workspaces"` block. Key difference: `"focused"` icon key instead of Hyprland's `"active"`. Niri also supports `"urgent"`.

### 3. Niri config updates

**Path:** `niri/.config/niri/config.kdl`

Three changes:

a) **Waybar spawn** (line 277):
   ```
   spawn-at-startup "waybar"
   ```
   → 
   ```
   spawn-at-startup "waybar" "-c" "/home/ttranpphu/.config/waybar/config-niri.jsonc"
   ```
   Must use absolute path — niri's `spawn-at-startup` passes args to `execvp` without shell expansion.

b) **Cursor theme** (after `prefer-no-csd`, around line 6):
   ```
   cursor-theme {
       name "capitaine-cursors"
       size 25
   }
   ```
   Under niri (started directly by SDDM, not uwsm), `XCURSOR_THEME`/`XCURSOR_SIZE` env vars aren't available. Niri sets cursor natively in KDL.

c) **Startup services** (after the waybar spawn):
   ```
   spawn-at-startup "mako"
   spawn-at-startup "swaybg" "-i" "/home/ttranpphu/.config/omarchy/current/background" "-m" "fill"
   spawn-at-startup "fcitx5" "--disable" "notificationitem"
   spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
   spawn-at-startup "hypridle"
   ```
   These match Omarchy's Hyprland autostart services that work under Niri. Skipped: `uwsm-app` wrappers (Niri doesn't use uwsm), `omarchy-hyprland-monitor-watch` (Hyprland-specific).

## Deployment

```bash
stow zsh -d ~/.dotfiles -t ~
stow waybar -d ~/.dotfiles -t ~
stow niri -d ~/.dotfiles -t ~
```

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
