---
name: coordinate
description: Coordinate AI agents across tmux panes via natural language. Agents self-identify, chat inline for quick messages, and write shared markdown files for long-form content.
---

## Overview

AI agents (opencode, Claude, Copilot, etc.) communicate with each other by
sending natural language messages across tmux panes. Each agent runs in its own
pane and uses `tmux send-keys` to deliver messages to other panes.

Agents MUST self-identify in every message so recipients can distinguish
between agent-to-agent and user-to-agent traffic.

## Pane layout convention

Agents use the `session-presets` workflow (see `session-presets.zsh`) where
each project window contains separate panes for opencode, nvim, etc. Additional
agent panes can be split from an existing window.

## Message protocol

### Inline messages (short, conversational)

Format:
```
tmux send-keys -t <target-pane-id> "Pane <source-pane-id> agent: <message>" Enter
```

- Every message starts with `Pane %<id> agent:` prefix.
- `<target-pane-id>` is the tmux pane id (`%0`, `%1`, etc.).
- `<source-pane-id>` is the sender's own pane id.
- Target pane ids are discovered via `tmux list-panes -a -F '#{pane_id} #{pane_current_command}'`.

### TUI-specific behavior

Different agent TUIs handle incoming `send-keys` differently.
The general send sequence is:

1. Send `C-c` to cancel any ongoing operation.
2. Send `C-u` to clear any residual text in the prompt.
3. Send the message text.
4. Send the submit key (below).

**opencode TUI** — `Enter` submits directly.

**Claude Code TUI** — `Enter` submits short messages directly. Longer
messages trigger an external editor (nvim by default); the text appears
pre-populated — save/close with `:wq` Enter. Cancel the editor with
`:cq` Enter.

**Copilot TUI** — `Enter` submits fresh messages (typed after `C-c`/`C-u`).
Sending `Enter` alone on pre-existing prompt text does NOT submit — the
`C-c; C-u; text; Enter` sequence must be used every time. May show transient
API errors and retry automatically.

To send a message regardless of length without triggering an editor, write the
content to a shared file in `.shared/agent/messages/` first, then send a short
inline notification referencing it.

Example — opencode in pane `%3` sends to Claude in pane `%2`:
```
tmux send-keys -t %2 "Pane %3 opencode agent: I've updated the API types in types.ts. Can you regenerate the mock data?" Enter
```

### Shared files (detailed, persistent)

For specs, requirements, procedures, or any content longer than a few lines,
agents write markdown files to `.shared/agent/messages/` instead of inline.

After writing, the agent sends an inline notification:
```
tmux send-keys -t %5 "Pane %3 agent: I posted the refactoring plan in .shared/agent/messages/refactoring-plan-2026-07-17.md" Enter
```

#### File naming convention

```
.shared/agent/messages/<topic>-<YYYY-MM-DD>[-<seq>].md
```

Examples:
```
.shared/agent/messages/auth-flow-spec-2026-07-17.md
.shared/agent/messages/deployment-checklist-2026-07-17.md
.shared/agent/messages/refactoring-plan-2026-07-17-2.md
```

#### File format

Each shared message file starts with a header block:

```markdown
# <Title>

**From:** Pane %<id> (<agent-type>)
**To:** Pane %<id> (<agent-type>)
**Date:** <YYYY-MM-DD>

<body>
```

The body can contain any markdown: prose, code blocks, checklists, tables,
diagrams, etc.

### Receiving messages

When an agent receives a message via `tmux send-keys` (i.e. text appears in its
pane), it MUST:

1. Check if the line starts with `Pane %<id> agent:` — if so, it is an
   agent-to-agent message.
2. If the message references a file in `.shared/agent/messages/`, read that
   file for the full content.
3. Respond or act on the message as appropriate.
4. The agent MUST NOT respond to its own messages (identified by its own pane
   id).

## Discovering panes

List all panes and their running commands to identify which pane hosts which
agent:

```
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'
```

This helps resolve which pane id to target. Agents cache this at the start of a
coordination session but should re-check if communication fails.

## User inspection

All shared markdown files in `.shared/agent/messages/` are checked into the
repo (via the `.shared/` stow package). The user can review them at any time.
Agents SHOULD write clear, self-contained messages so the user can follow the
conversation even without the inline chat history.
