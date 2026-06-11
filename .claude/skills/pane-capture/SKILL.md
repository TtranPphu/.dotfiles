---
name: pane-capture
description: Capture what's currently visible in a tmux pane. Use when asked to see terminal output, capture pane, or check what's on screen.
user-invocable: true
allowed-tools: [Bash]
---

Capture the current tmux pane output:

`tmux capture-pane -p`

To capture a specific pane by index:

`tmux capture-pane -t <index> -p`

To save to a file instead of stdout:

`tmux capture-pane -p > /tmp/pane-capture.txt`
