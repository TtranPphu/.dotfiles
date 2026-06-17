# Track Plans in the Dotfiles Repo

## Context

Claude Code writes plan files during plan mode to `~/.claude/plans/` — these are project-relevant design documents that should be version-controlled alongside the code they describe. Currently they live only on the local filesystem outside the repo, so they aren't shared, backed up, or visible in git history.

The Claude project's `memory/` directory is already symlinked into the repo (at `.claude/projects/.dotfiles/memory/`). We want the same treatment for plans.

## What Gets Tracked vs What Stays Local

**`~/.claude/projects/-home-ttranpphu--dotfiles/`** stores:
- `memory/` → symlink TO the repo (already tracked)
- Session `.jsonl` files and subagent directories → **runtime artifacts, stay local** (not suitable for VCS)

**`~/.claude/plans/`** stores 7 existing plan files (3.2 KB total) — these are design documents worth tracking.

## Implementation

1. **Create `.claude/plans/` in the repo** as a real directory
2. **Move the 7 existing plan files** from `~/.claude/plans/` into `.claude/plans/`
3. **Replace `~/.claude/plans/`** with a symlink pointing to the repo's `.claude/plans/`
4. **Stage and commit** (if the user wants) the new directory with its initial content

The symlink direction follows the existing pattern used by `memory/`:
- Real files live in the repo: `.dotfiles/.claude/plans/`
- Global location points there: `~/.claude/plans/` → `../../dotfiles/.claude/plans/`

## Verification

- Run `ls -la ~/.claude/plans/` — should show a symlink, not a directory
- Run `ls ~/.claude/plans/` — should show the same files as `ls .claude/plans/` in the repo
- Open a plan file to confirm content matches
- In a future Claude session, confirm new plan mode writes land in `.claude/plans/`
