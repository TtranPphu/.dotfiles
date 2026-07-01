#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-battery-util.sh"

usage() {
  echo "Usage: $(basename "$0") --display <left|right> | --guard <tier> <left|right>"
  exit 1
}

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
left="${data%% *}"
right="${data##* }"
[[ -z "$left" ]] && exit 1

case "${1:-}" in
  --display)
    [[ $# -lt 2 ]] && usage
    if [[ "$2" == "left" ]]; then
      printf ' %s' "$left"
    elif [[ "$2" == "right" ]]; then
      printf ' %s' "$right"
    else
      usage
    fi
    ;;
  --guard)
    [[ $# -lt 3 ]] && usage
    tier="$2"
    if [[ "$3" == "left" ]]; then
      val="$left"
    elif [[ "$3" == "right" ]]; then
      val="$right"
    else
      usage
    fi
    idx=$(( (val - 1) / 10 ))
    [[ "$idx" -eq "$tier" ]]
    ;;
  *) usage ;;
esac
