#!/bin/bash

# Starship custom module: OpenCode Go quota usage
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pct=''
rolling_icon='󰃶 '
weekly_icon='󰨳 '
monthly_icon='󰸗 '

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
  printf "%s%s%s %s%s%s %s%s%s" "$rolling_icon" "$ROLLING" "$pct" "$weekly_icon" "$WEEKLY" "$pct" "$monthly_icon" "$MONTHLY" "$pct"
else
  printf "%s%s%s" "$monthly_icon" "$MONTHLY" "$pct"
fi
