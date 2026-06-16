# Bell-triggered visual alerts — Implementation

## Context

When an app sends a bell (`\a`) — e.g., Claude Code waiting for approval — the tmux status bar should show visual indicators wherever the window/session appears. The bell flag is tmux-native, auto-clears when the window is focused, and requires no polling.

## Files to modify

| File | Action |
|---|---|
| `tmux/.config/tmux/theme.conf` | Enable `monitor-bell`, add format conditionals |
| `tmux/.config/tmux/scripts/status/session-list.sh` | Per-session bell check, swap icon + green fg |
| `tmux/.config/tmux/scripts/control/switch-session.sh` | Bell check per session, update fzf display + preview cmd |
| `tmux/.config/tmux/scripts/control/window-switch.sh` | Add bell-flat icon to fzf format |

## Changes

### 1. `theme.conf`

After `status-interval 5`:

```tmux
setw -g monitor-bell on
set -g window-status-bell-style "fg=green"
```

Update `window-status-format` (current: `#[fg=brightblack]  #I #W `):

```tmux
set -g window-status-format "\
#{?window_bell_flag,#[fg=green] 󰅸,#[fg=brightblack] } #I #W "
```

No change to `window-status-current-format` — bell auto-clears on window focus.

### 2. `session-list.sh`

Replace the final output loop (lines 33-38). For each session, check if any window has the bell flag, then output with appropriate icon and color:

```bash
for session in "${selected[@]}"; do
  has_bell=$(tmux -S "$socket_path" list-windows -t "$session" \
    -F '#{window_bell_flag}' 2>/dev/null | grep -q 1)
  if [ "$has_bell" ]; then
    printf '#[fg=green]󰅸 %s ' "$session"
  else
    printf '#[fg=brightblack] %s ' "$session"
  fi
done
```

No changes needed to `left.sh` or `right.sh` — their `#[fg=brightblack]` prefix gets overridden by per-session colors inside the output.

### 3. `switch-session.sh`

Two changes:

**Display loop** (lines 14-19): Add icon per session based on bell state.

```bash
    has_bell=$(tmux list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1)
    [ "$has_bell" ] && icon="󰅸" || icon=""
    echo "$icon $s: $windows"
```

**Preview cmd** (line 7): Session name is now field 2 (after icon), so use `awk` instead of `cut`:

```bash
preview_cmd='s=$(echo {} | awk "{print \$2}" | cut -d: -f1); '\
'i=$(tmux list-windows -t "$s" '\
'  2>/dev/null | sort -k1 -rn | head -1 | cut -d" " -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'
```

### 4. `window-switch.sh`

Insert the bell icon into the format (line 8-10). Key extraction via `cut -d" " -f1` is unaffected since the icon goes after the key field.

```bash
win_fmt='#{session_name}:#{window_index} '\
'#{?window_bell_flag,󰅸,} '\
'#{session_name} - #{window_name}: '\
'#{window_panes} #{?#{==:#{window_panes},1},pane,panes}'
```
