# Handoff: Claude Project Tracking Setup

## Goal

Document which Claude Code artifacts are tracked in the dotfiles repo and why, so future agents understand the project's Claude footprint.

## What's Tracked

| Artifact | Repo Path | Mechanism |
|----------|-----------|-----------|
| **Project memory** | `.claude/projects/.dotfiles/memory/` | Real directory in repo; symlinked from `~/.claude/projects/-home-ttranpphu--dotfiles/memory/` |
| **Plans** | `.claude/plans/` | Real directory in repo; symlinked from `~/.claude/plans/` |
| **Skills** | `.claude/skills/*/SKILL.md` → `.shared/agent/skills/*/SKILL.md` | Symlinks, tracked in git |
| **CLAUDE.md** | `.claude/CLAUDE.md` | Real file, tracked |
| **Settings** | `.claude/settings.json` | Real file, tracked |
| **Shared agent resources** | `.shared/agent/` (conventions, keywords, communication-style, handoffs, skills) | Real files, tracked |

## What's NOT Tracked

**Session logs** (`~/.claude/projects/-home-ttranpphu--dotfiles/*.jsonl` and session directories) are left local:
- ~39MB total (44 JSONL + 22 session dirs with subagent transcripts)
- Actively written during every Claude session — git would show constant dirty state
- Grows with Claude usage
- Subagent tool-result dirs are bulky cached artifacts, not conversation logs
- Decision: session history is useful but the churn and growth aren't worth tracking in VCS

## Symlink Structure

```
~/.claude/
  plans/                        → ../.dotfiles/.claude/plans/      (repo)
  projects/
    -home-ttranpphu--dotfiles/
      memory/                   → ../../../../.dotfiles/.claude/projects/.dotfiles/memory/  (repo)
      *.jsonl                   ← local only, not tracked
      <uuid>/                   ← local only, not tracked
```

## Key Decision

- **Plans are now project-tracked.** Any future plan written during plan mode lands in `.claude/plans/` in the repo and will appear in git status. This is intentional — plans are design documents worth versioning alongside the code.
- **Session data stays local.** The JSONL transcripts and subagent caches are runtime artifacts. They're useful for debugging but don't belong in the repo.

## Related Files

- `.claude/CLAUDE.md` — main project instructions
- `.claude/.gitignore` — ignores `settings.local.json`
- `./.shared/agent/handoffs/05-ollama-qwen-aichat-integration.md` — references `.claude/plans/`
