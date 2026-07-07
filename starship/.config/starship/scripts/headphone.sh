#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/headphone-util.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard <tier>"
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
    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 120) -lt 120 ]]; then
      printf '%s' "$NARROW_ICON"
    else
      printf '%s %s' "$WIDE_ICON" "$val"
    fi
    ;;
  --guard)
    [[ $# -lt 2 ]] && usage
    tier="$2"
    idx=$(( (val - 1) / 10 ))
    [[ "$idx" -eq "$tier" ]]
    ;;
  *) usage ;;
esac
