#!/usr/bin/env bash
# User segment: gate + live render. id calls are cheap, so nothing is cached.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/icon.sh"
  source "$script_dir/color.sh"
  local user fg_user icon_user text

  user=$(id -un)
  if [ "$(id -u)" -eq 0 ]; then
    fg_user=$(color_ansi magenta) # root
  else
    fg_user=$(color_ansi cyan)
  fi
  icon_user="$(nerd_font_icon user)"
  text="$icon_user$user"
  reset=$'\033[0m'
  printf '%s%s%s' "$fg_user" "$text" "$reset"
}

case "${1:-}" in
  --display)
    render
    ;;
  --guard)
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
