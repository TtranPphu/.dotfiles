---
name: pane-capture
description: Capture what's visible in a tmux pane.
---

Capture current pane: `tmux capture-pane -p`
Capture specific pane: `tmux capture-pane -t <index> -p`
Save to file: `tmux capture-pane -p > /tmp/pane-capture.txt`
