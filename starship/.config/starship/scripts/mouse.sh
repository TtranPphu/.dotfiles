#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/mouse-util.sh"
source "$SCRIPT_DIR/level-color.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard"
  exit 1
}

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
cap="${data%% *}"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

case "${1:-}" in
  --display)
    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 144) -lt 144 ]]; then
      text="󰍽"
    else
      text="󰍽 $cap"$'\uf295'
    fi
    printf '%s%s\033[0m' "$(level_color "$cap")" "$text"
    ;;
  --guard)
    exit 0
    ;;
  *) usage ;;
esac
