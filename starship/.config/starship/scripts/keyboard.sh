#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-util.sh"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/icons.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard"
  exit 1
}

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
left="${data%% *}"
right="${data##* }"
[[ -z "$left" ]] && exit 1

case "${1:-}" in
  --display)
    if [[ "$("$SCRIPT_DIR/layout.sh" size)" != wide ]]; then
      printf '%s%s\033[0m %s%s\033[0m' \
        "$(level_color "$left")" "$(icon keyboard)" \
        "$(level_color "$right")" "$(icon keyboard)"
    else
      printf '%s%s%s\033[0m %s%s%s\033[0m' \
        "$(level_color "$left")" "$(icon keyboard)" " $left$(icon plug)" \
        "$(level_color "$right")" "$(icon keyboard)" " $right$(icon plug)"
    fi
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *) usage ;;
esac
