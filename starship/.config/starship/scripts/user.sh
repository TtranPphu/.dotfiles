#!/usr/bin/env bash
# User segment: gate + live render. id calls are cheap, so nothing is cached.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local user color icon

  user=$(id -un)
  if [ "$(id -u)" -eq 0 ]; then
    color=$'\033[35m' # root
  else
    color=$'\033[36m'
  fi
  icon="$(nerd_font_icon user)"
  printf '%s%s%s\033[0m' "$color" "$icon" "$user"
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
