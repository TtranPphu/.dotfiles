# Tmux auto-split layout issue

## Goal
Fix wrong pane layout when recreating a session on a portrait monitor (117×84). The `auto-split.sh` W > 2*H heuristic produces horizontal-first layout (opencode left, claude+pi stacked right) instead of vertical-first (opencode top, claude+pi side-by-side bottom) on portrait screens.

## Key findings
- `new-session -d` creates at `default-size 80×24` when no other sessions exist (kill → recreate flow). At 80×24, W > 2*H is true (80 > 48) → horizontal split. On attach, session resizes to 117×84 but split decisions are already baked in.
- The `$TARGET_FLAG="-t $TARGET"` expansion in `auto-split.sh` passes `-t` and `%N` as separate args to tmux, but sometimes yields empty width/height reads in certain contexts, causing wrong split direction fallback.
- `session:window.pane` targeting is ambiguous (floating-point window parse issue). Current code uses pane_id (`%N`) format.

## Current state
- `auto-split.sh`: supports `-t TARGET` flag, uses `$TARGET_FLAG` string for tmux arg passing.
- `session-presets.zsh`: uses auto-split with pane_id targeting, no `select-layout` (delegates to auto-split), no explicit session size.

## Potential fixes to explore
1. Pass `-x W -y H` to `new-session -d` using client terminal size so auto-split sees the correct dimensions.
2. Use `${TARGET:+-t} ${TARGET:+"$TARGET"}` expansion in auto-split instead of combined `$TARGET_FLAG` string.
3. Defer splits until after `attach-session` (session is at terminal size after attach).

## Verification
- Kill dotfiles session, recreate via picker → window 2 should show opencode(117×41), claude(58×42), pi(58×42).
- Landscape screens should still produce horizontal-first (correct for those dimensions).
