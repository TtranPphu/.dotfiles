#!/usr/bin/env bash
# Swap the current pane with its neighbour in direction $1 (L, D, U, R) and
# keep focus on the pane the user started in. tmux's swap-pane only knows
# -U/-D, so move to the neighbour first and swap by pane id.
#
# tmux 3.8 wraps select-pane around the window edge, so check the pane_at_*
# flags first to keep swaps with no neighbour a no-op.

case "${1:-}" in
  L | l)
    dir=-L
    edge=pane_at_left
    ;;
  D | d)
    dir=-D
    edge=pane_at_bottom
    ;;
  U | u)
    dir=-U
    edge=pane_at_top
    ;;
  R | r)
    dir=-R
    edge=pane_at_right
    ;;
  *)
    echo "usage: $(basename "$0") L|D|U|R" >&2
    exit 2
    ;;
esac

current=$(tmux display-message -p '#{pane_id}') || exit 1
[ "$(tmux display-message -p "#{$edge}")" = 1 ] && exit 0

tmux select-pane "$dir" || exit 1
neighbour=$(tmux display-message -p '#{pane_id}') || exit 1
[ "$neighbour" = "$current" ] && exit 0

tmux swap-pane -s "$current" -t "$neighbour" || exit 1
tmux select-pane -t "$current"
