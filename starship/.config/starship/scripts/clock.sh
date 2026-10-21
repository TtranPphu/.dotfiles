#!/usr/bin/env bash
# Clock segment: gate + live render. A date call is cheap, so nothing is cached.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local hour time icon_clock text

  hour=$((10#$(date +%-I)))
  time="$(date +'%I:%M %p')"
  icon_clock="$(nerd_font_icon "clock.$hour")"
  if [[ -n "$icon_clock" ]]; then
    text="$icon_clock$time"
  else
    text="$time"
  fi
  printf '%s' "$text"
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
