---
name: pane-logs
description: Investigate tmux pane output logs.
---

List recent logs: `ls -lt ~/.local/state/tmux/pane-logs/ | head -10`
Read a log: `tail -30 ~/.local/state/tmux/pane-logs/<id>.log`
Search logs: `grep -l <pattern> ~/.local/state/tmux/pane-logs/*.log`
