---
name: pane-logs
description: Investigate tmux pane output logs. Use when asked about pane logs, debug output, or checking what happened in a terminal.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

List recent logs: `ls -lt ~/.local/state/tmux/pane-logs/ | head -10`
Read a log: `tail -30 ~/.local/state/tmux/pane-logs/<id>.log`
Search logs: `grep -l <pattern> ~/.local/state/tmux/pane-logs/*.log`
