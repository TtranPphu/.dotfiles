#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"
source "$SCRIPT_DIR/icons.sh"

case "${1:-}" in
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    [ -n "${SSH_CONNECTION:-}" ] || [ -f /.dockerenv ] || exit 1
    exit 0
    ;;
esac

data=$("$UTIL") || exit 1
[[ -z "$data" ]] && exit 1

printf '%s %s' "$(icon host)" "$data"
