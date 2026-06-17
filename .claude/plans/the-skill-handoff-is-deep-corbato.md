# Plan: Add missing handoff skill symlinks

## Context

The `/handoff` skill exists at `.shared/agent/skills/handoff/SKILL.md` but is **not symlinked** into either `.claude/skills/` or `.github/skills/`. The other four skills (commit, pane-capture, pane-logs, stow-deploy) all have symlinks in both directories. Without the symlink, the handoff skill may not be discoverable by Claude Code's skill loader (which scans `.claude/skills/`).

This is a simple one-task fix — create the missing symlinks matching the existing pattern.

## Proposed Change

Create two symlinks following the exact relative pattern already used by the four existing skills:

1. **`.claude/skills/handoff/`** → create directory, then symlink `SKILL.md` to `../../../.shared/agent/skills/handoff/SKILL.md`
2. **`.github/skills/handoff/`** → create directory, then symlink `SKILL.md` to `../../../.shared/agent/skills/handoff/SKILL.md`

The relative path `../../../.shared/agent/skills/<name>/SKILL.md` matches the convention used by all other skills (verified via `readlink -f`).

## Files to Modify

- `mkdir -p .claude/skills/handoff/` + symlink
- `mkdir -p .github/skills/handoff/` + symlink

## Verification

- Run `readlink -f .claude/skills/handoff/SKILL.md` — should resolve to the repo root's `.shared/agent/skills/handoff/SKILL.md`
- Same for `.github/skills/handoff/SKILL.md`
- Restart/reload Claude Code session (or trigger skill discovery) — `/handoff` should appear as an available skill
