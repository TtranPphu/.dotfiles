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

WIDE_ICON='󰎇'
NARROW_ICON='󰎇'

case "${1:-}" in
  --display)
    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 144) -lt 144 ]]; then
      text="$NARROW_ICON"
    else
      text="$WIDE_ICON $val"$'\uf295'
    fi
    printf '%s%s\033[0m' "$(level_color "$val")" "$text"
    ;;
  --guard)
    exit 0
    ;;
  *) usage ;;
esac
