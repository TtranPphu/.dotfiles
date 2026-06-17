# Plan: Register handoff skill in `.claude/skills/`

## Context

The handoff skill is defined in `.shared/agent/skills/handoff/SKILL.md` with `name: handoff` and `user-invocable: true`. However, it is **missing from `.claude/skills/`**, where all other project skills (commit, pane-capture, pane-logs, stow-deploy) are duplicated. Because the system discovers user-invocable skills from `.claude/skills/`, the handoff skill does not appear in the available skills list and cannot be invoked as `/handoff`.

The user's statement "The skill handoffs should be handoff" confirms:
- The skill name should be **handoff** (singular, not "handoffs")
- The skill needs to be properly registered so it's available

## Changes

**Create** `.claude/skills/handoff/SKILL.md` — an exact copy of `.shared/agent/skills/handoff/SKILL.md` (mirroring how commit, pane-capture, pane-logs, and stow-deploy are duplicated in both directories).

The content is already known:
```yaml
---
name: handoff
description: Write a handoff document for interrupted or deferred work. Use when work cannot be completed in a single session and needs to be resumed later by another agent.
user-invocable: true
argument-hint: <topic>
allowed-tools: [Read, Write, Bash, Grep]
---
```

## Verification

After the change:
1. The file `.claude/skills/handoff/SKILL.md` should exist with the same content as `.shared/agent/skills/handoff/SKILL.md`
2. The skill should appear in the available skills list as `handoff` (discoverable via the Skill tool)
3. No other references to a plural "handoffs" skill name exist in the repo
