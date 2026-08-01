#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/mouse-util.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard <tier>"
  exit 1
}

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
cap="${data%% *}"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

case "${1:-}" in
  --display)
    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 100) -lt 100 ]]; then
      printf '󰍽'
    else
      printf '󰍽 %s' "$cap"
    fi
    ;;
  --guard)
    [[ $# -lt 2 ]] && usage
    tier="$2"
    idx=$(( (cap - 1) / 10 ))
    [[ "$idx" -eq "$tier" ]]
    ;;
  *) usage ;;
esac
