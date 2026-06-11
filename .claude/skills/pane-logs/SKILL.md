---
name: pane-logs
description: Investigate tmux pane output logs. Use when asked about pane logs, debug output, or checking what happened in a terminal.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

## List recent pane logs

Run `ls -lt ~/.local/state/tmux/pane-logs/ | head -10` to find recent logs by modification time.

## Read a specific log

Tail the end of a pane log to see recent output:

`tail -30 ~/.local/state/tmux/pane-logs/<id>.log`

## Search across logs

`grep -l <pattern> ~/.local/state/tmux/pane-logs/*.log`
