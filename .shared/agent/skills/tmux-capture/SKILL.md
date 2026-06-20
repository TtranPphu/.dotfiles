---
name: tmux-capture
description: Capture what's currently visible in a tmux pane/window. Use when asked to see terminal output, capture a pane, or check what's on screen.
user-invocable: true
allowed-tools: [Bash]
---

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
