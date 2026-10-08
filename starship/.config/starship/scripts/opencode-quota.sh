#!/bin/bash

# Starship custom module: OpenCode Go quota usage
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/nerd-font.sh"

if [ "${1:-}" = "--guard" ]; then
  [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
  "$SCRIPT_DIR/layout.sh" is narrow && exit 1
  "$SCRIPT_DIR/opencode-quota-util.sh" --values >/dev/null || exit 1
  exit 0
fi

VALUES=$("$SCRIPT_DIR/opencode-quota-util.sh" --values) || exit 1
read -r ROLLING _ MONTHLY <<<"$VALUES"
SIZE=$("$SCRIPT_DIR/layout.sh" size)
[ "$SIZE" = narrow ] && exit 1

pct="$(nerd_font_icon percent)"
icon="$(nerd_font_icon opencode)"
[[ -n "$icon" ]] && icon="$icon "

# Rolling quota drives the foreground: low usage green, near limit red.
printf '%s%s%s%s\033[0m' "$(level_color "$ROLLING")" "$icon" "$MONTHLY" "$pct"
