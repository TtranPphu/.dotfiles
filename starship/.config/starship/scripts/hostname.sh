#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"
QUALITY="$SCRIPT_DIR/ssh-quality-util.sh"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/icons.sh"

case "${1:-}" in
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    [ -n "${SSH_CONNECTION:-}" ] || [ -f /.dockerenv ] || exit 1
    exit 0
    ;;
esac

size=$("$SCRIPT_DIR/layout.sh" size)
[[ $size == narrow ]] && exit 1

data=$("$UTIL") || exit 1
[[ -z "$data" ]] && exit 1

# Over SSH color the host with the connection quality ramp (10 = green, 1 = red);
# medium drops the name. Without SSH the module only shows in wide.
if level=$("$QUALITY" level 2>/dev/null); then
  ramp=$((level * 10))
  icon=$("$QUALITY" signal 2>/dev/null)
  if [[ $size == wide ]]; then
    printf '%s%s %s %s\033[0m' "$(level_color "$ramp")" "$icon" "$(icon host)" "$data"
  else
    printf '%s%s\033[0m' "$(level_color "$ramp")" "$icon"
  fi
else
  [[ $size == wide ]] || exit 1
  printf '%s %s' "$(icon host)" "$data"
fi
