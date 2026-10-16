#!/usr/bin/env bash
# Clock segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local hour time icon

  hour=$((10#$(date +%-I)))
  time="$(date +'%I:%M %p')"
  icon="$(nerd_font_icon "clock.$hour")"
  if [[ -n "$icon" ]]; then
    printf '%s%s\n' "$icon" "$time"
  else
    printf '%s\n' "$time"
  fi
}

case "${1:-}" in
  --display | "")
    cache_file=$(starship_cache_path clock "$(starship_cache_client)")
    cache_display "$cache_file" 15 "$0" --refresh "$cache_file"
    ;;
  --refresh)
    cache_refresh "${2:?}" render
    ;;
  --guard)
    "$script_dir/layout.sh" is narrow && exit 1
    cache_file=$(starship_cache_path clock "$(starship_cache_client)")
    cache_gate "$cache_file" 15 "$0" --refresh "$cache_file"
    ;;
  *) exit 2 ;;
esac
