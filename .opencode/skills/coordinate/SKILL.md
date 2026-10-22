---
name: coordinate
description: Coordinate AI agents across tmux panes via natural language. Agents self-identify, chat inline for quick messages, and write shared markdown files for long-form content.
---

## Overview

opencode agents communicate with each other by
sending natural language messages across tmux panes. Each agent runs in its own
pane and delivers message text through a tmux paste buffer, reserving
`send-keys` for the submit key.

Agents MUST self-identify in every message so recipients can distinguish
between agent-to-agent and user-to-agent traffic.

## Identifying your own pane

Each agent needs to know its own pane ID to self-identify in messages.
**Do NOT use `tmux display-message -p '#{pane_id}'`** — it returns the tmux
client pane, not the pane where the agent process runs. Instead, find yourself
in the pane list by matching your process name:

```
tmux list-panes -a -F '#{pane_id} #{pane_current_command}' | grep -w <process-name> | awk '{print $1}'
```

For example, opencode would run:

```
tmux list-panes -a -F '#{pane_id} #{pane_current_command}' | grep -w 'opencode' | awk '{print $1}'
```

## Discovering other panes

List all panes to identify which pane hosts which agent:

```
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'
```

Cache this at the start of a coordination session but re-check if
communication fails.

## Message protocol

### Inline messages (short, conversational)

Deliver the message text through a tmux paste buffer, then send the submit key:

```
tmux set-buffer -b msg-<source-pane-id> "This is <name> agent from pane <source-pane-id>: <message>"
tmux paste-buffer -p -b msg-<source-pane-id> -d -t <target-pane-id>
tmux send-keys -t <target-pane-id> Enter
```

- Every message starts with `This is <name> agent from pane <id>:` prefix.
- `<target-pane-id>` is the tmux pane id (`%0`, `%1`, etc.).
- `<source-pane-id>` is the sender's own pane id.
- `<name>` is the agent's name (`opencode`).
- Target pane ids are discovered via `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'`.

Why a paste buffer:

- `send-keys` parses each argument as a tmux key name — a literal word like
  `Enter` or `C-r` becomes that key. `paste-buffer` inserts text as data, so
  nothing is reinterpreted.
- A paste never submits, so `Enter` goes out as a separate call.
- Name the buffer after your own pane (`msg-%3`) so concurrent sends from
  other agents can't collide. `-d` deletes the buffer after pasting; drop it
  to keep the buffer reusable.
- `-p` wraps the text in bracketed-paste codes when the target app supports
  them (zsh, most TUIs), so it lands as one paste rather than keystrokes.
- LFs are sent as CRs by default — each line is submitted. For multiline
  messages use `-p -r`, or prefer a shared file for anything longer.
- `tmux load-buffer -b msg-<source-pane-id> -` fills the buffer from stdin
  (or a file path) instead of `set-buffer`.

### TUI-specific behavior

Send sequence: `C-u` to clear residual text, then deliver the message (paste
buffer or `send-keys`), then the submit key.

**opencode TUI** — `Enter` submits directly.

Example — opencode in pane `%3` sends to opencode in pane `%2`:
```
tmux set-buffer -b msg-%3 "This is opencode agent from pane %3: I've updated the API types in types.ts. Can you regenerate the mock data?"
tmux paste-buffer -p -b msg-%3 -d -t %2
tmux send-keys -t %2 Enter
```

### Shared files (detailed, persistent)

For specs, requirements, procedures, or any content longer than a few lines,
agents write markdown files to `.opencode/messages/` instead of inline.

After writing, the agent sends an inline notification:
```
tmux set-buffer -b msg-%3 "This is opencode agent from pane %3: I posted the refactoring plan in .opencode/messages/2026-07-17-143052-refactoring-plan.md"
tmux paste-buffer -p -b msg-%3 -d -t %5
tmux send-keys -t %5 Enter
```

#### File naming convention

```
.opencode/messages/<YYYY-MM-DD-HHMMSS>-<topic>.md
```

Examples:
```
.opencode/messages/2026-07-17-143052-auth-flow-spec.md
.opencode/messages/2026-07-17-153120-deployment-checklist.md
.opencode/messages/2026-07-21-110435-refactoring-plan.md
```

#### File format

Each shared message file starts with a header block:

```markdown
# <Title>

**From:** <agent-type> (pane %<id>)
**To:** <agent-type> (pane %<id>)
**Date:** <YYYY-MM-DD-HHMMSS>

<body>
```

The body can contain any markdown: prose, code blocks, checklists, tables,
diagrams, etc.

### Receiving messages

When text appears in an agent's pane (delivered via `paste-buffer` or
`send-keys`), it MUST:

1. Check if the line starts with `This is <name> agent from pane <id>:` — if
   so, it is an agent-to-agent message.
2. If the message references a file in `.opencode/messages/`, read that
   file for the full content.
3. Respond or act on the message as appropriate.

## Cross-machine coordination (Tailscale + SSH)

Agents on different machines coordinate the same way, with the tmux commands
wrapped in `ssh`. Peers are usually reachable over Tailscale.

### Find and reach the peer

```
tailscale status
ssh -o BatchMode=yes <host-alias> 'hostname; whoami'
```

- Prefer the `~/.ssh/config` alias; it supplies the remote username. Tailscale
  SSH rejects a guessed user with
  `tailnet policy does not permit you to SSH as user "<user>"`.
- Keep `BatchMode=yes` so a missing key fails fast instead of prompting.

### Discover remote panes

```
ssh <host> 'tmux list-panes -a -F "#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}"'
```

### Deliver a message

```
printf '%s' "This is opencode agent from pane %0 on omarchy-iv: ..." |
  ssh <host> 'tmux send-keys -t %0 C-u;
              tmux load-buffer -b msg-omarchy-iv-%0 -;
              tmux paste-buffer -p -b msg-omarchy-iv-%0 -d -t %0;
              tmux send-keys -t %0 Enter'
```

- Always name the host in the `This is ... from pane ...` prefix: pane ids are
  per machine, so both ends are frequently `%0`.
- Name the buffer `msg-<host>-<pane>` so concurrent senders cannot collide.
- `C-u` clears partial input, the paste inserts text as data, and the separate
  `Enter` submits. opencode queues the message while it is mid-run.
- Piping the text into `tmux load-buffer -` avoids quoting problems through
  `ssh`.

### Replies

Never poll or scrape the peer's pane for answers. The responding agent MUST
push a notification into the requesting agent's pane when it replies:

```
printf '%s' "This is opencode agent from pane %0 on lar-22-403-0107: ..." |
  ssh <peer> 'tmux send-keys -t %0 C-u;
              tmux load-buffer -b msg-lar-%0 -;
              tmux paste-buffer -p -b msg-lar-%0 -d -t %0;
              tmux send-keys -t %0 Enter'
```

For long content, write the file first and notify with its path. `capture-pane`
is only for verifying that a message landed, never for discovering answers.

### Shared files across machines

When SSH works in both directions, write the file directly into the peer's
checkout and send a short inline notice:

```
ssh <peer> 'cat > ~/.dotfiles/.opencode/messages/2026-10-22-150000-topic.md' < local.md
printf '%s' "This is opencode agent from pane %0 on omarchy-iv: I wrote .opencode/messages/2026-10-22-150000-topic.md on your machine; read it." |
  ssh <peer> 'tmux send-keys -t %0 C-u;
              tmux load-buffer -b msg-omarchy-iv-%0 -;
              tmux paste-buffer -p -b msg-omarchy-iv-%0 -d -t %0;
              tmux send-keys -t %0 Enter'
```

- Writing through SSH needs no git sync or branch; the file stays untracked
  in the peer's checkout.
- If files must travel through git instead, use a dedicated branch such as
  `opencode-messages`, never `master` or a feature branch, and commit only
  `.opencode/messages/` there.

### Worked example: remote desktop setup

This channel was first used to set up wayvnc over Tailscale with a WSLg
viewer: one agent created the wayvnc TLS cert, config, and user service on
the desktop, and the other installed `tigervnc-viewer` in WSL and tested the
connection. Split work by machine, let each side own the commands that need
its own sudo, and send credentials over the channel only after the server
validates locally.
