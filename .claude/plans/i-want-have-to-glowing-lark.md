# Compositor Switching: Niri / Hyprland

## Context

Currently SDDM auto-logins into `omarchy` (uwsm-managed Hyprland). Niri is installed with a full config but no way to switch to it at login without manually editing `/etc/sddm.conf.d/autologin.conf`. The goal is to make switching between compositors trivial — both from the command line and via SDDM's built-in session menu.

## Steps

### 1. Create `session-switch` CLI script

**New file:** `zsh/.local/bin/session-switch`

A CLI tool that reads/writes `/etc/sddm.conf.d/autologin.conf` (needs sudo for write). Goes in the `zsh` stow package (`.local/bin/` is already in PATH).

Behaviors:
- `session-switch` — prints current session and usage
- `session-switch niri` — writes `Session=niri`
- `session-switch omarchy` — writes `Session=omarchy`
- `session-switch --menu` — interactive fzf selection
- Idempotent: no-op if already set to target
- Preserves `[Theme] Current=omarchy` line
- Uses `sudo tee` to write the config
- Prints reminder about reboot or Escape-at-SDDM

### 2. Split waybar config for Niri

**New file:** `waybar/.config/waybar/config-niri.jsonc`

Based on current `config.jsonc` with these changes:
- `modules-left`: `"hyprland/workspaces"` → `"niri/workspaces"`
- `"hyprland/workspaces"` block → `"niri/workspaces"` block with `"focused"` (not `"active"`)
- Everything else identical — all other modules, CSS, and `style.css` are compositor-agnostic

**File modified:** `niri/.config/niri/config.kdl` (line 277)
- Change `spawn-at-startup "waybar"` → `spawn-at-startup "waybar" "-c" "/home/ttranpphu/.config/waybar/config-niri.jsonc"`
- Must use absolute path (no tilde expansion in `spawn-at-startup`)

### 3. Add missing startup services to Niri config

**File modified:** `niri/.config/niri/config.kdl` — add after the waybar line:

```kdl
spawn-at-startup "mako"
spawn-at-startup "swaybg" "-i" "/home/ttranpphu/.config/omarchy/current/background" "-m" "fill"
spawn-at-startup "fcitx5" "--disable" "notificationitem"
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "hypridle"
```

Rationale: matches the Omarchy Hyprland autostart services that make sense under Niri. Skipping `uwsm-app` (Niri doesn't use uwsm) and `omarchy-hyprland-monitor-watch` (Hyprland-specific).

### 4. Add cursor theme to Niri config

**File modified:** `niri/.config/niri/config.kdl` — add after `prefer-no-csd`:

```kdl
cursor-theme {
    name "capitaine-cursors"
    size 25
}
```

Under Niri (started directly by SDDM, not via uwsm), the `XCURSOR_THEME`/`XCURSOR_SIZE` env vars from Hyprland's config aren't available. Niri handles cursors natively in KDL.

## Deployment

```bash
stow zsh -d ~/.dotfiles -t ~
stow waybar -d ~/.dotfiles -t ~
stow niri -d ~/.dotfiles -t ~
```

## Verification

1. Check symlinks: `ls -la ~/.local/bin/session-switch ~/.config/waybar/config-niri.jsonc ~/.config/niri/config.kdl`
2. Test script: `session-switch` (shows current), `session-switch niri` (verify with `grep ^Session /etc/sddm.conf.d/autologin.conf`), `session-switch omarchy` (switch back)
3. Test interactive: `session-switch --menu`
4. Reboot/logout and verify SDDM shows both options (press Escape at autologin countdown)
5. Log into Niri, verify waybar works with workspace display, check mako/hypridle/swaybg are running
