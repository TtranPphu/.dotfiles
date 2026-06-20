# AGENTS.md

### Important Rules

- Never create git commits unless explicitly asked. Use the `/commit` skill when ready.
- Add files under the stow package that owns the target path — don't create ad-hoc relocation scripts.
- Always mind the changes the user made during the session before making your own.

### Communication Style

See [communication style guide](.shared/agent/communication-style.md).

### Keywords

See [keywords reference](.shared/agent/keywords.md).

### Conventions

See [conventions guide](.shared/agent/conventions.md).

### Shared Agent Resources

Skills and handoffs live in `.shared/agent/`:
- **Skills** — `/commit`, `/stow-deploy`, `/pane-capture`, `/pane-logs`, `/handoff` ([skills directory](.shared/agent/skills/))
- **Handoffs** — Context documents for multi-session tasks ([handoffs directory](.shared/agent/handoffs/))

### What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME`. No build system, tests, or CI.

### Config Quick Reference

- **Desktop** (compositors, bars, launchers, themes) — See [desktop.md](.shared/agent/desktop.md)
- **Terminal** (shell, editor, tmux, tools) — See [terminal.md](.shared/agent/terminal.md)

### Session Permissions

`.claude/settings.json` sets default mode to `plan`. Writes allowed only to `.claude/plans/` unless explicitly granted.
