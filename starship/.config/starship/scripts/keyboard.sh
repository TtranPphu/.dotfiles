#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-util.sh"
source "$SCRIPT_DIR/level-color.sh"

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
    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 144) -lt 144 ]]; then
      printf '%s%s\033[0m %s%s\033[0m' \
        "$(level_color "$left")"  \
        "$(level_color "$right")" 
    else
      printf '%s%s%s\033[0m %s%s%s\033[0m' \
        "$(level_color "$left")"  " $left" \
        "$(level_color "$right")"  " $right"
    fi
    ;;
  --guard)
    exit 0
    ;;
  *) usage ;;
esac
