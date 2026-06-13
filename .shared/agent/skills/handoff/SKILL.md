---
name: handoff
description: Write a handoff document for interrupted or deferred work. Use when work cannot be completed in a single session and needs to be resumed later by another agent.
user-invocable: true
argument-hint: <topic>
allowed-tools: [Read, Write, Bash, Grep]
---

Use this skill when you need to document in-progress work so another agent can pick it up later. A handoff captures what was discovered, what was decided, and what remains to be done.

## Where handoffs live

Handoffs go in `.shared/agent/handoffs/handoff-<topic>.md` relative to the repo root.

## When to write a handoff

- Work was scoped but not yet started (plan is done, implementation is pending)
- Implementation was partially completed and needs to be finished
- Complex findings were uncovered that shouldn't be lost
- A decision was made with rationale that future agents need to understand

## Structure

Every handoff should include these sections when applicable:

**Goal** — What the work aims to accomplish, in one paragraph.

**Deliverables** — Numbered list of files to create or modify, with paths, key content, and exact diffs. Be specific enough that an agent can implement without re-exploring.

**Deployment** — Commands to activate the changes (e.g., stow commands, symlinks, systemctl).

**Key Findings** — Architecture notes, configuration paths, and rationale for decisions made during exploration. This saves the next agent from re-discovering the same things.

**Potential Issues** — Gotchas, edge cases, and risks the next agent should watch for.

**Verification** — Numbered checklist to confirm the work is done correctly.

## Formatting rules

- Use absolute paths `/home/ttranpphu/...` or repo-relative paths from the dotfiles root
- Show exact diffs or code snippets with language hints
- Use `**bold**` for file paths in prose
- Link to any relevant skills, configs, or prior handoffs by path

## Reference

See the existing handoff at `.shared/agent/handoffs/handoff-compositor-switching.md` for a complete example.
