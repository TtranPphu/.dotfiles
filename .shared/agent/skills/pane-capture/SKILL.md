---
name: pane-capture
description: Capture what's currently visible in a tmux pane. Use when asked to see terminal output, capture pane, or check what's on screen.
user-invocable: true
allowed-tools: [Bash]
---

Capture current pane: `tmux capture-pane -p`
Capture specific pane: `tmux capture-pane -t <index> -p`
Save to file: `tmux capture-pane -p > /tmp/pane-capture.txt`
