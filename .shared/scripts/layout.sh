#!/usr/bin/env bash
# Single source of truth for terminal-width layout thresholds.
#
#   narrow : width <  88   (hide optional modules)
#   medium : 88 <= width < 144
#   wide   : width >= 144
#
# CLI:
#   layout.sh width [w]        -> detected width
#   layout.sh size  [w]        -> narrow | medium | wide
#   layout.sh is narrow|medium|wide [w]   -> exit 0 when it matches
#
# Sourced from bash it defines layout_width / layout_size.
# Width resolution: $1, then $STATUS_WIDTH (tmux), then the controlling tty,
# then $COLUMNS, then tput. Unknown width is treated as "medium".
set -u

LAYOUT_NARROW=88
LAYOUT_WIDE=144

layout_width() {
  local w="${1:-${STATUS_WIDTH:-}}"
  if [ -z "$w" ]; then
    w=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')
  fi
  if [ -z "$w" ]; then
    w="${COLUMNS:-}"
  fi
  if [ -z "$w" ] && command -v tput >/dev/null 2>&1; then
    w=$(tput cols 2>/dev/null) || w=""
  fi
  printf '%s' "$w"
}

layout_size() {
  local w
  w=$(layout_width "${1:-}")
  if [ -z "$w" ]; then
    printf medium
  elif [ "$w" -lt "$LAYOUT_NARROW" ]; then
    printf narrow
  elif [ "$w" -lt "$LAYOUT_WIDE" ]; then
    printf medium
  else
    printf wide
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    width) shift; layout_width "${1:-}" ;;
    size) shift; layout_size "${1:-}" ;;
    is)
      want="${2:?usage: layout is narrow|medium|wide [width]}"
      [ "$(layout_size "${3:-}")" = "$want" ]
      ;;
    *)
      echo "usage: layout.sh width|size|is <narrow|medium|wide> [width]" >&2
      exit 2
      ;;
  esac
fi
