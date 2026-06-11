---
name: commit
description: Create a git commit following project conventions. Use when the user asks to commit changes.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

## Rules

- Only commit when explicitly asked. Never auto-commit.
- Format: `[Component] - Summary`
- Component in title-case square brackets: `[Hypr]`, `[Nvim]`, `[Tmux]`, `[Zsh]`, `[Starship]`
- Body ends with blank line then `Claude - <model>` matching the system prompt
  Example: `Claude - deepseek-v4-flash[1m]`
- Do NOT use `Co-Authored-By` or other signatures

## Procedure

1. Run `git status`, `git diff`, and `git log -5` to understand state and style
2. Stage specific files (never `git add -A`)
3. Create the commit via `git commit -m "$(cat <<'EOF'"`
