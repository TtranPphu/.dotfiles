# Move pane to session with fzf popup

## Status
Completed in this session (commit `fbeb7dc`, `[Tmux] - Move experimental features from M-e/M-x to M-s/M-w`).

## What was done
- Rebound `M-s` → switch-session, `M-w` → window-switch; removed `M-e`/`M-x` bindings
- Updated arrow key hint from `j/k (w/s)` to just `j/k`
- Rewrote `move-to-session.sh`: now shows fzf popup with session list, pre-filled with cwd-derived default; falls back to zoxide for non-matching input
- Fixed line count parsing bug (single-word query had no `$2` for awk)
- Switched to `set -uo pipefail` so fzf Escape doesn't crash

## Goal
Replace the cwd-only `M-m` move-to-session behavior with an fzf popup (like `M-e`/`M-p`), pre-filled with the cwd-derived session name, falling back to zoxide for non-matching input.

## Deliverables

1. **`tmux/.config/tmux/bindings.conf`** — Rebind `M-s` → switch-session, `M-w` → window-switch, remove `M-e`/`M-x`. Update arrow key hint to say `j/k` only.

2. **`tmux/.config/tmux/scripts/control/move-to-session.sh`** — Rewrite to:
   - Show fzf-tmux session list with preview, pre-filled with cwd-derived default
   - If result has >1 line, parse selection (`$2` from formatted line)
   - If result is 1 line (typed input), use whole query as target
   - Existing session → move pane there (original logic)
   - No session → zoxide query → create session → move pane
   - Uses `set -uo pipefail` (no `-e`) so fzf cancellation doesn't crash

## Key Findings

- `switch-session.sh` doesn't use `set -euo pipefail`, while the original `move-to-session.sh` did. The fzf pipeline legitimately returns non-zero on Escape, so `-e` was removed.
- The fzf `--print-query` output format: line 1 = query, line 2+ = selection. When no selection exists, only 1 line is output, so `awk '{print $2}'` fails. Must check line count.
- Scripts live at `~/.config/tmux/scripts/control/` stowed from `tmux/.config/tmux/scripts/control/` (same inode).
- `zoxide query` errors are captured with `2>&1` and displayed via `tmux display-message`.

## Verification
1. `M-m` opens fzf with session list, default query pre-filled from cwd
2. Selecting existing session moves pane there
3. Typing a new name creates session via zoxide and moves pane
4. Escape exits cleanly (no error)
5. `M-e`/`M-x` are unbound (no action)
6. `M-s` runs switch-session, `M-w` runs window-switch
