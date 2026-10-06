#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

case "${1:-}" in
  --display)
    if [[ "$("$SCRIPT_DIR/layout.sh" size)" == wide ]]; then
      date '+%y-%m-%d %a'
    else
      day=$(date +%-d)
      case "$day" in
        1 | 21 | 31) suffix='st' ;;
        2 | 22) suffix='nd' ;;
        3 | 23) suffix='rd' ;;
        *) suffix='th' ;;
      esac
      printf '%s%s' "$day" "$suffix"
    fi
    ;;
  --guard)
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *) usage ;;
esac
