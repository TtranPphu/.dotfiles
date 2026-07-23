## Important Rules

- Execute exactly what the user asked. Do not add, change, or assume beyond the literal instruction.
- Before taking any action not explicitly requested, ask first.
- Track what the user has changed during the session and respect those changes.

## What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME`. No build system, tests, or CI. Don't look outside the repo for configs you need — they're already here in the stow tree.

## Communication Style

See [communication style guide](.shared/agent/communication-style.md).

## Keywords

See [keywords reference](.shared/agent/keywords.md).

## Key Conventions

See [conventions guide](.shared/agent/conventions.md).

## Shared Agent Resources

This repo ships reusable agent resources in `.shared/agent/`:
- **Skills** — Slash commands available to all agents ([skills directory](.shared/agent/skills/))
  - **commit** — Create a git commit following project conventions, one per top-level component.
  - **coordinate** — Message other AI agents across tmux panes via send-keys and shared markdown files.
  - **fire** — Run a long command in a new tmux window with a watchdog that reports completion.
  - **handoff** — Write or archive handoff documents for interrupted or deferred work.
  - **merge** — Merge a feature branch into master with a conventional commit message.
  - **stow-deploy** — Deploy, list, or preview GNU stow packages from this repo.
  - **tmux-troubleshoot** — Investigate tmux panes: capture output, check logs, inspect status lines.
- **Handoffs** — Context handoff documents for multi-session tasks ([handoffs directory](.shared/agent/handoffs/))

## Config Quick Reference

- **Desktop** (compositors, bars, launchers, themes) — See [desktop.md](.shared/agent/desktop.md)
- **Terminal** (shell, editor, tmux, tools) — See [terminal.md](.shared/agent/terminal.md)
