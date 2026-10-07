#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

case "${1:-}" in
  --display)
    if [[ "$("$SCRIPT_DIR/layout.sh" size)" == wide ]]; then
      text="$(date '+%y-%m-%d %a')"
    else
      day=$(date +%-d)
      case "$day" in
        1 | 21 | 31) suffix='st' ;;
        2 | 22) suffix='nd' ;;
        3 | 23) suffix='rd' ;;
        *) suffix='th' ;;
      esac
      text="${day}${suffix}"
    fi
    icon="$(nerd_font_icon date)"
    if [[ -n "$icon" ]]; then
      printf '%s %s' "$icon" "$text"
    else
      printf '%s' "$text"
    fi
    ;;
  --guard)
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *) usage ;;
esac
