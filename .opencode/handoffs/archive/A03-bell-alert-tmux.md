# Bell-Triggered Visual Alerts

## Summary

Implemented bell-triggered visual indicators across tmux status bar, session switcher, and window switcher. When an app sends `\a` (bell), tmux's native `monitor-bell` flags the window, and all display surfaces show a green `󰅸` icon that auto-clears on focus. Also enabled Claude Code's terminal bell notification channel.

## Files

- `tmux/.config/tmux/theme.conf` — `setw -g monitor-bell on`, `window-status-bell-style fg=green`, window-status-format conditional (green `󰅸` / brightblack ``)
- `tmux/.config/tmux/scripts/status/session-list.sh` — Per-session bell check → green `󰅸` or ``
- `tmux/.config/tmux/scripts/status/right.sh` — Rewrote reversed session list: direct tmux iteration (was causing double-icon with bell sessions)
- `tmux/.config/tmux/scripts/control/switch-session.sh` — Session icon + bell in fzf display, preview cmd uses `awk` for field-2 extraction
- `tmux/.config/tmux/scripts/control/window-switch.sh` — Bell icon in fzf format, per-session loop, `--with-nth=2..` display
- `~/.claude/settings.json` — `preferredNotifChannel: "terminal_bell"`

## Key decisions

- Uses tmux-native `monitor-bell` and `window_bell_flag` — no polling, auto-clears on window focus
- fzf switchers show icons per session/window rather than a single global bell indicator
- Bell icon `󰅸` in green everywhere; normal sessions use `` (status) or `` (window tabs)
- Claude Code bell channel set but not confirmed working via DeepSeek API proxy — further debugging needed

## Future iteration notes

- Claude Code bell not firing despite `preferredNotifChannel: "terminal_bell"` — suspect DeepSeek proxy strips the notification signal. Could strace/tmux monitor to confirm `\a` emission
- No native `session_bell_flag` in tmux format — session-level bell in window-switch is static `` (workaround via shell loop removed for simplicity)
- Could track bell state externally (file/journal) for delayed review if auto-clear is too aggressive
- Consider distinct `bell-action` and `bell-on-alert` for different bell types
