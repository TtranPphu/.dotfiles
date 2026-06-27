---
name: tmux-troubleshoot
description: Investigate tmux panes: capture visible output, check saved logs, inspect status lines.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

## Pane capture

First list panes to get the full target:
```
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index}'
```

The user refers to panes by the numeric pane_id (e.g. "pane 5" = pane_id `%5`).
Resolve it by matching the number against `#{pane_id}` (strip the `%` prefix).

Then capture using session:window.pane format:
```
tmux capture-pane -t dotfiles:4.1 -p
```

Save to file: `tmux capture-pane -p > /tmp/pane-capture.txt`

## Pane logs

Auto-logged pane output is stored at `~/.local/state/tmux/pane-logs/`.

List recent logs:
```
ls -lt ~/.local/state/tmux/pane-logs/ | head -10
```

Read a log:
```
tail -30 ~/.local/state/tmux/pane-logs/<id>.log
```

Search logs:
```
grep -l <pattern> ~/.local/state/tmux/pane-logs/*.log
```

## Status lines

The status bar sits at the top of each window (configured in `theme.conf`).

Show rendered status-left and status-right strings:
```
tmux display-message -p '#{status-left}'
tmux display-message -p '#{status-right}'
```

List all windows (includes bell flags, active window markers):
```
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name} #{window_active} #{window_bell_flag}'
```

List sessions with attached status:
```
tmux list-sessions
```

For a full screen capture including the status line, run:
```
tmux capture-pane -t <target> -p
```
or with history:
```
tmux capture-pane -t <target> -p -S -
```
