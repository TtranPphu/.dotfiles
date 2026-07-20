---
name: fire
description: Fire a long-running command in a new tmux window, monitor it with a PID-based watchdog, and get notified when it completes. The watchdog self-identifies so the receiving agent can handle the result.
---

## Overview

Use when you need to run a slow command (build, test, lint, etc.) without
blocking your own session. The skill:

1. Fires the command wrapped to write its PID to a temp file.
2. Launches a background watchdog that waits for that PID to exit.
3. Returns control immediately — the watchdog handles the wait.
4. When the process exits, the watchdog sends a self-identifying message
   back so the initiating agent can pick up the result.

## Workflow

### 1. Fire the command

Create a new window with a shell, then `send-keys` the wrapped command.
This keeps the shell alive after the command finishes for result inspection.

```
tmux new-window -n "<label>" -c <working-dir>
tmux send-keys -t <pane-id> "sh -c 'echo \$\$ > /tmp/fire-<label>.pid; exec <command>'" Enter
```

If the user specified a pane, send directly to that pane instead:

```
tmux send-keys -t <pane-id> "sh -c 'echo \$\$ > /tmp/fire-<label>.pid; exec <command>'" Enter
```

If the targeted pane is busy (not a shell), create a new window instead.

### 2. Find the target pane and launch the watchdog

Get the target pane ID for the new window:

```
tmux list-panes -F '#{pane_id} #{window_name}' | grep "<label>" | awk '{print $1}'
```

Then launch the watchdog:

```
.shared/agent/scripts/fire-watchdog.sh /tmp/fire-<label>.pid <initiator-pane-id> "<label>" <target-pane-id> [interval] & disown
```

`interval` is the polling rate in seconds (default: 1). The watchdog waits
up to 5s for the PID file to appear, then polls `kill -0` until the process
exits.

### 3. Receiving the notification

```
Pane %1 watchdog: "build" completed in pane %6. Inspect the results. Over.
```

Inspect results with:
- `tmux capture-pane -t <pane> -p -S -50` — scrollback from the target pane
- File system artifacts or logs

## Watchdog script

`.shared/agent/scripts/fire-watchdog.sh`

| Parameter | Description |
|-----------|-------------|
| `$1`      | Path to PID file (written by the command) |
| `$2`      | Pane ID to notify |
| `$3`      | Label |
| `$4`      | Target pane ID (included in notification) |
| `$5`      | Polling interval in seconds (default: 1) |

## Notes

- The command **must** write its PID to the file before the watchdog starts
  polling. The wrapper `sh -c 'echo $$ > <file>; exec <cmd>'` does this.
- The watchdog cleans up the PID file after the process exits.
- It's a detached background process; it survives the initiating agent
  exiting.
