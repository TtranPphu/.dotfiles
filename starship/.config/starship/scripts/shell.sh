#!/usr/bin/env bash
# Shell segment: live render; nothing to fetch or cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."

render() {
  source "$script_dir/nerd-font.sh"
  local shell icon

  shell="${STARSHIP_SHELL:-unknown-shell}"
  icon="$(nerd_font_icon "shell.$shell")"
  if [[ -n "$icon" ]]; then
    printf '%s%s' "$icon" "$shell"
  else
    printf '%s' "$shell"
  fi
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
