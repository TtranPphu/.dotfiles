#!/bin/bash

# Starship custom module: OpenCode Go quota usage
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pct=$'\uf295'
icon=$'\U000F11D8'

if [ "${1:-}" = "--guard" ]; then
  [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
  "$SCRIPT_DIR/layout.sh" is narrow && exit 1
  "$SCRIPT_DIR/opencode-quota-util.sh" --values >/dev/null || exit 1
  exit 0
fi

VALUES=$("$SCRIPT_DIR/opencode-quota-util.sh" --values) || exit 1
read -r ROLLING WEEKLY MONTHLY <<<"$VALUES"
SIZE=$("$SCRIPT_DIR/layout.sh" size)
[ "$SIZE" = narrow ] && exit 1
if [ "$SIZE" = wide ]; then
  printf "%s %s%s/%s%s/%s%s" "$icon" "$ROLLING" "$pct" "$WEEKLY" "$pct" "$MONTHLY" "$pct"
else
  printf "%s %s%s" "$icon" "$MONTHLY" "$pct"
fi
