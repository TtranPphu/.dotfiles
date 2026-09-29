# Agent Tracking

## Summary

Which agent artifacts (opencode and Claude) are tracked in the dotfiles repo. Agent configs, skills, handoffs, plans, and memory are all tracked in git. Session logs and runtime caches are left local.

## Files

- `.opencode/AGENTS.md` — opencode project instructions
- `opencode/.config/opencode/opencode.json` — opencode config (stow package)
- `.claude/CLAUDE.md` — Claude project instructions
- `.claude/.gitignore` — ignores `settings.local.json`
- `.claude/plans/` — design documents versioned in repo
- `.claude/projects/.dotfiles/memory/` — project memory, symlinked
- `.shared/agent/` — conventions, keywords, communication-style, skills, handoffs

## Key decisions

- Plans and handoffs are versioned as design documents worth keeping
- Session data (JSONL transcripts, subagent caches) stays local — too much churn
- Symlinks connect `~/.claude/` paths to repo paths
- Handoffs numbered sequentially, archived under `archive/` with an `NN-topic.md` pattern

## Future iteration notes

- No automated cleanup of old session logs
