# Bell-triggered visual alerts in tmux

*Handoff documents split into Implementation Plan and Testing Plan below.*

---

## Handoff 1: Implementation Plan

### What & Why

Visual alert when any app sends a bell (`\a`) — e.g., Claude Code waiting for approval. The bell flag is tmux-native, auto-clears when the window is focused, and requires no polling.

### Files to modify

| File | Action |
|---|---|
| `tmux/.config/tmux/theme.conf` | Enable monitoring, add format conditionals |
| `tmux/.config/tmux/scripts/status/session-list.sh` | Per-session bell check, icon + color swap |
| `tmux/.config/tmux/scripts/control/switch-session.sh` | Bell check per session in fzf display |
| `tmux/.config/tmux/scripts/control/window-switch.sh` | Bell flag icon in fzf format |

### 1. `theme.conf`

Add after `status-interval 5`:

```tmux
setw -g monitor-bell on
set -g window-status-bell-style "fg=green"

set -g window-status-format "\
#{?window_bell_flag,#[fg=green] 󰅸,#[fg=brightblack] } #I #W "
```

No change to `window-status-current-format` — bell auto-clears on focus.

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

Two changes: the display loop and the preview command.

**Display loop** (lines 14-19): Add icon per session based on bell state.

```bash
    has_bell=$(tmux list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1)
    [ "$has_bell" ] && icon="󰅸" || icon=""
    echo "$icon $s: $windows"
```

**Preview cmd** (line 7): Session name is now field 2 (after icon), so use `awk` instead of `cut`:

```bash
preview_cmd='s=$(echo {} | awk "{print \$2}" | cut -d: -f1); '\
'...rest unchanged...'
```

### 4. `window-switch.sh`

Insert the bell icon into the format (line 8-10). Key extraction via `cut -d" " -f1` is unaffected since the icon goes after the key field.

```bash
win_fmt='#{session_name}:#{window_index} '\
'#{?window_bell_flag,󰅸,} '\
'#{session_name} - #{window_name}: '\
'#{window_panes} #{?#{==:#{window_panes},1},pane,panes}'
```

---

## Handoff 2: Testing Plan

### Prerequisites

- tmux session running with the updated config
- `tmux source-file ~/.config/tmux/tmux.conf` after edits

### Test 1: Bell triggers window alert

1. Create two windows in the same session, focus window 1
2. In window 2: `echo -e '\a'`
3. **Expected**: Within 5 seconds (status-interval), window 2 in status bar shows `󰅸` in green instead of `` in brightblack

### Test 2: Bell triggers session alert

1. Have at least 2 tmux sessions, each with a few windows
2. In a non-focused window of session B: `echo -e '\a'`
3. Switch to session A
4. **Expected**: Session B name in `status-left`/`status-right` shows `󰅸` in green instead of `` in brightblack

### Test 3: Auto-dismissal on focus

1. Continue from Test 1 — window 2 has bell indicator
2. Switch to window 2
3. **Expected**: Within 5 seconds, window 2 returns to normal `window-status-current-format`, session returns to normal blue

### Test 4: Session switcher (`M-e`)

1. Trigger a bell in a session's window (from another session)
2. Press `M-e` to open session switcher
3. **Expected**: Bell'd session shows `󰅸 session_name: ...`, normal sessions show ` session_name: ...`

### Test 5: Window switcher (`M-x`)

1. Trigger a bell in a non-focused window
2. Press `M-x` to open window switcher
3. **Expected**: Bell'd window shows `󰅸` prefix, normal windows show ``

### Test 6: Combined states (multiple bells)

1. Trigger bells in windows of 2 different sessions
2. **Expected**: Both sessions show green `󰅸`, all bell'd windows show green `󰅸`
3. Visit each bell'd window — they revert one by one

### Test 7: No spurious alerts

1. Run normal commands (no bell) in non-focused windows
2. **Expected**: No icon/color changes (activity alone doesn't trigger)

### Rollback

If something goes wrong:
```bash
cd ~/.config/tmux
git diff                     # review changes
git checkout -- theme.conf   # revert individual file
# OR
git checkout -- .            # revert all changes
tmux source-file ~/.config/tmux/tmux.conf
```
