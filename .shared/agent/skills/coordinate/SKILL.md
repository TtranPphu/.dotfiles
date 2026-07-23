---
name: coordinate
description: Coordinate AI agents across tmux panes via natural language. Agents self-identify, chat inline for quick messages, and write shared markdown files for long-form content.
---

## Overview

AI agents (opencode, claude, copilot, pi, etc.) communicate with each other by
sending natural language messages across tmux panes. Each agent runs in its own
pane and uses `tmux send-keys` to deliver messages to other panes.

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

For example, pi would run:

```
tmux list-panes -a -F '#{pane_id} #{pane_current_command}' | grep -w 'pi' | awk '{print $1}'
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

Format:
```
tmux send-keys -t <target-pane-id> "This is <name> agent from pane <source-pane-id>: <message>" Enter
```

- Every message starts with `This is <name> agent from pane <id>:` prefix.
- `<target-pane-id>` is the tmux pane id (`%0`, `%1`, etc.).
- `<source-pane-id>` is the sender's own pane id.
- `<name>` is the agent's name (opencode, claude, copilot, pi, etc.).
- Target pane ids are discovered via `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'`.

### TUI-specific behavior

Different agents handle `send-keys` differently. Send sequence: `C-u` to clear residual text, then the message, then the submit key.

**opencode TUI** — `Enter` submits directly.

**claude TUI** — `Enter` submits directly. For longer content, write a
shared file instead of inline.

**pi TUI** — `Enter` does not always register on the first send; send the message text followed by two `Enter` keys (text + Enter + Enter) to ensure submission.

**copilot TUI** — Not working at the moment.

Example — opencode in pane `%3` sends to claude in pane `%2`:
```
tmux send-keys -t %2 "This is opencode agent from pane %3: I've updated the API types in types.ts. Can you regenerate the mock data?" Enter
```

### Shared files (detailed, persistent)

For specs, requirements, procedures, or any content longer than a few lines,
agents write markdown files to `.shared/agent/messages/` instead of inline.

After writing, the agent sends an inline notification:
```
tmux send-keys -t %5 "This is opencode agent from pane %3: I posted the refactoring plan in .shared/agent/messages/2026-07-17-143052-refactoring-plan.md" Enter
```

#### File naming convention

```
.shared/agent/messages/<YYYY-MM-DD-HHMMSS>-<topic>.md
```

Examples:
```
.shared/agent/messages/2026-07-17-143052-auth-flow-spec.md
.shared/agent/messages/2026-07-17-153120-deployment-checklist.md
.shared/agent/messages/2026-07-21-110435-refactoring-plan.md
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

When an agent receives a message via `tmux send-keys` (i.e. text appears in its
pane), it MUST:

1. Check if the line starts with `This is <name> agent from pane <id>:` — if
   so, it is an agent-to-agent message.
2. If the message references a file in `.shared/agent/messages/`, read that
   file for the full content.
3. Respond or act on the message as appropriate.
