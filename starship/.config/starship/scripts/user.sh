#!/usr/bin/env bash
# User segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

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
    cache_file=$(starship_cache_path user "$(starship_cache_client)")
    cache_display "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  --refresh)
    cache_refresh "${2:?}" render
    ;;
  --guard)
    "$script_dir/layout.sh" is narrow && exit 1
    cache_file=$(starship_cache_path user "$(starship_cache_client)")
    cache_gate "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  *) exit 2 ;;
esac
