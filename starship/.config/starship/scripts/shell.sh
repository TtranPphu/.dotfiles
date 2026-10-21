#!/usr/bin/env bash
# Shell segment: live render; nothing to fetch or cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."

render() {
  source "$script_dir/nerd-font.sh"
  local shell icon_shell text

  shell="${STARSHIP_SHELL:-unknown-shell}"
  icon_shell="$(nerd_font_icon "shell.$shell")"
  if [[ -n "$icon_shell" ]]; then
    text="$icon_shell$shell"
  else
    text="$shell"
  fi
  printf '%s' "$text"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    :
    exit 0
    ;;
  *) exit 2 ;;
esac
