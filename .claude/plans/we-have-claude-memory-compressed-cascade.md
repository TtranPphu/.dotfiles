# Merge local Claude memory into repo-tracked memory, symlink local → repo

## Context

There are two independent Claude memory stores for this dotfiles repo:

| Location | Files | Tracked in git? |
|---|---|---|
| `~/.claude/projects/-home-ttranpphu--dotfiles/memory/` (local) | `feedback_no_auto_commits.md`, `feedback_respect_user_changes.md` | No (outside repo) |
| `.dotfiles/.claude/projects/.dotfiles/memory/` (repo) | `feedback_dont_dismiss_issues.md` | Yes |

The local store was auto-created by Claude Code and lives outside version control. The repo store is the canonical, version-controlled location. We want to consolidate so the repo store is the single source of truth, and the local path points to it via symlink.

## Plan

### Step 1: Copy local memory files into the repo-tracked directory

Copy both files from the local store into `.dotfiles/.claude/projects/.dotfiles/memory/`:

- `feedback_no_auto_commits.md`
- `feedback_respect_user_changes.md`

### Step 2: Merge MEMORY.md indexes

Update `.dotfiles/.claude/projects/.dotfiles/memory/MEMORY.md` to include all three entries:

```markdown
- [No auto-commits](feedback_no_auto_commits.md) — Never create git commits unless explicitly asked
- [Respect user changes](feedback_respect_user_changes.md) — Never overwrite user modifications during the session
- [dont-dismiss-issues](feedback_dont_dismiss_issues.md) — Fix bugs regardless of source, don't dismiss
```

### Step 3: Replace local memory with a symlink

```bash
rm -rf ~/.claude/projects/-home-ttranpphu--dotfiles/memory/
ln -s /home/ttranpphu/.dotfiles/.claude/projects/.dotfiles/memory/ \
      /home/ttranpphu/.claude/projects/-home-ttranpphu--dotfiles/memory/
```

Using an absolute path for the symlink — both locations are under `$HOME`, so it's stable.

### Step 4: Verify

1. Confirm `ls -la ~/.claude/projects/-home-ttranpphu--dotfiles/memory/` shows all 3 `.md` files
2. Confirm `readlink -f ~/.claude/projects/-home-ttranpphu--dotfiles/memory/` resolves to the repo path
3. Confirm `git -C ~/.dotfiles status` shows the two new files as untracked (or staged, if user asks to commit)

## Files modified

- **Added** (2): `.claude/projects/.dotfiles/memory/feedback_no_auto_commits.md`, `.claude/projects/.dotfiles/memory/feedback_respect_user_changes.md`
- **Modified** (1): `.claude/projects/.dotfiles/memory/MEMORY.md` (merged index)
- **Deleted + symlinked** (1): `~/.claude/projects/-home-ttranpphu--dotfiles/memory/` (local dir → symlink to repo dir)
