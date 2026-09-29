# Tmux move pane to session with fzf popup

## Summary
Replaced the cwd-only `M-m` move-to-session behavior with an fzf popup (like `M-e`/`M-p`), pre-filled with the cwd-derived session name, falling back to zoxide for non-matching input. Rebound `M-s` to switch-session and `M-w` to window-switch; removed `M-e`/`M-x` bindings. Fixed line count parsing bug in fzf `--print-query` output.

## Files
- `tmux/.config/tmux/bindings.conf:93-97` — Key bindings for `M-s`, `M-w`, `M-m`
- `tmux/.config/tmux/scripts/control/move-to-session.sh` — Rewritten fzf-popup move-to-session script

## Key decisions
- Used `set -uo pipefail` (no `-e`) so fzf Escape returns cleanly
- Parsed fzf `--print-query` output by line count: multi-line means selection exists, single line means typed input
- Fallback to zoxide query when no existing session matches; errors displayed via `tmux display-message`

## Future iteration notes
- None; feature is complete as delivered in commit `fbeb7dc`.
