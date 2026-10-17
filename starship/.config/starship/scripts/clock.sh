#!/usr/bin/env bash
# Clock segment: gate + live render. A date call is cheap, so nothing is cached.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local hour time icon

  hour=$((10#$(date +%-I)))
  time="$(date +'%I:%M %p')"
  icon="$(nerd_font_icon "clock.$hour")"
  if [[ -n "$icon" ]]; then
    printf '%s%s' "$icon" "$time"
  else
    printf '%s' "$time"
  fi
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
