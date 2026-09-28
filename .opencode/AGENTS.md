### Important Rules

- Execute exactly what the user asked. Do not add, change, or assume beyond the literal instruction.
- Before taking any action not explicitly requested, ask first.
- Track what the user has changed during the session and respect those changes.
- NEVER use `/tmp` in any way — no writing, reading, listing or inspecting files there, debugging spelunking included. Create a temp folder under `.shared/workbench/` for experiments/scripts/logs, then delete it when done. If a tool or script keeps its own state in `/tmp`, leave it alone and ask the user.

### Delegation

- The build agent explores and scopes package work itself, then hands execution
  to the owning subagent: `.opencode/agent/shell-packages.md` for terminal/shell
  packages, `.opencode/agent/system-packages.md` for desktop/system packages.
- Subagents do not commit. After they return their changed-file report, the
  build agent commits with the commit skill.
- Prefer spawning subagents in the background (`background: true`) so the main
  agent stays responsive while package work runs. Pass the parameter explicitly:
  on v1 it is hidden from the tool schema (opencode issue #45345). Use a
  foreground call only when the next step depends on the result, or for a quick
  confirm-and-return task.
- Only run package work directly when the owning subagent cannot handle it.

### What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME`. No build system, tests, or CI. Don't look outside the repo for configs you need — they're already here in the stow tree.

### Communication Style

See [communication style guide](.opencode/docs/communication-style.md).

### Speech Input

See [speech input guide](.opencode/docs/speech-input.md).

### Keywords

See [keywords reference](.opencode/docs/keywords.md).

### Conventions

See [conventions guide](.opencode/docs/conventions.md).

### Shared Agent Resources

Skills and handoffs live under `.opencode/`:
- **Skills** — Slash commands available to all agents ([skills directory](.opencode/skills/))
  - **commit** — Create a git commit following project conventions, one per top-level component.
  - **coordinate** — Message other AI agents across tmux panes via send-keys and shared markdown files.
  - **fire** — Run a long command in a new tmux window with a watchdog that reports completion.
  - **handoff** — Write or archive handoff documents for interrupted or deferred work.
  - **merge** — Merge a feature branch into master with a conventional commit message.
  - **stow-deploy** — Deploy, list, or preview GNU stow packages from this repo.
  - **tmux-troubleshoot** — Investigate tmux panes: capture output, check logs, inspect status lines.
- **Handoffs** — Context documents for multi-session tasks ([handoffs directory](.opencode/handoffs/))

### Config Quick Reference

- **Desktop** (compositors, bars, launchers, themes) — See [desktop.md](.opencode/docs/desktop.md)
- **Terminal** (shell, editor, tmux, tools) — See [terminal.md](.opencode/docs/terminal.md)
