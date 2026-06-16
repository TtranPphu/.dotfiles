# Bell-triggered visual alerts — Testing

## Prerequisites

- tmux session running with the updated config
- `tmux source-file ~/.config/tmux/tmux.conf` after edits

## Test 1: Bell triggers window alert

1. Create two windows in the same session, focus window 1
2. In window 2: `echo -e '\a'`
3. **Expected**: Within 5 seconds (status-interval), window 2 in status bar shows `󰅸` in green instead of `` in brightblack

## Test 2: Bell triggers session alert

1. Have at least 2 tmux sessions, each with a few windows
2. In a non-focused window of session B: `echo -e '\a'`
3. Switch to session A
4. **Expected**: Session B name in `status-left`/`status-right` shows `󰅸` in green instead of `` in brightblack

## Test 3: Auto-dismissal on focus

1. Continue from Test 1 — window 2 has bell indicator
2. Switch to window 2
3. **Expected**: Within 5 seconds, window 2 returns to normal `window-status-current-format`, session returns to normal blue

## Test 4: Session switcher (`M-e`)

1. Trigger a bell in a session's window (from another session)
2. Press `M-e` to open session switcher
3. **Expected**: Bell'd session shows `󰅸 session_name: ...`, normal sessions show ` session_name: ...`

## Test 5: Window switcher (`M-x`)

1. Trigger a bell in a non-focused window
2. Press `M-x` to open window switcher
3. **Expected**: Bell'd window shows `󰅸` prefix, normal windows show ``

## Test 6: Combined states (multiple bells)

1. Trigger bells in windows of 2 different sessions
2. **Expected**: Both sessions show green `󰅸`, all bell'd windows show green `󰅸`
3. Visit each bell'd window — they revert one by one

## Test 7: No spurious alerts

1. Run normal commands (no bell) in non-focused windows
2. **Expected**: No icon/color changes (activity alone doesn't trigger)

## Rollback

If something goes wrong:
```bash
cd ~/.config/tmux
git diff                     # review changes
git checkout -- theme.conf   # revert individual file
# OR
git checkout -- .            # revert all changes
tmux source-file ~/.config/tmux/tmux.conf
```
