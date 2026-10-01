#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/headphone-util.sh"
source "$SCRIPT_DIR/level-color.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard"
  exit 1
}

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
[[ -z "$data" || "$data" -eq 0 ]] && exit 1
val="$data"

WIDE_ICON='󱡏'
NARROW_ICON='󰎇'

case "${1:-}" in
  --display)
    if [[ "$("$SCRIPT_DIR/layout.sh" size)" != wide ]]; then
      text="$NARROW_ICON"
    else
      text="$WIDE_ICON $val"
    fi
    printf '%s%s\033[0m' "$(level_color "$val")" "$text"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *) usage ;;
esac
