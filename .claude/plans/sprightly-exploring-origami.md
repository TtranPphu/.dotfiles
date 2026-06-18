# Plan: Add aichat option to zsh welcome prompt

## Context

The zsh welcome prompt (when both tmux and zellij are installed) lets the
user pick a multiplexer — Tmux, Zellij, or None. The user wants `A` as an
additional option to launch aichat directly.

## Change

**File:** `zsh/.zshrc` (lines 130-137)

- Add `A` (aichat) to the prompt message
- Add `a|A)` case to the case statement: `exec aichat`

## Verification

1. Start a shell outside tmux/zellij with both installed
2. Prompt should show `A` as aichat
3. Pressing `a` or `A` should launch aichat
