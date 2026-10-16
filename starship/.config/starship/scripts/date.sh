#!/usr/bin/env bash
# Date segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/nerd-font.sh"
  local size=${1:-$("$script_dir/layout.sh" size)}
  local text day suffix icon

  if [[ "$size" == wide ]]; then
    text="$(date '+%y-%m-%d %a')"
  else
    day=$(date +%-d)
    case "$day" in
      1 | 21 | 31) suffix='st' ;;
      2 | 22) suffix='nd' ;;
      3 | 23) suffix='rd' ;;
      *) suffix='th' ;;
    esac
    text="${day}${suffix}"
  fi

  icon="$(nerd_font_icon date)"
  if [[ -n "$icon" ]]; then
    printf '%s%s' "$icon" "$text"
  else
    printf '%s' "$text"
  fi
}

case "${1:-}" in
  --display)
    # The refresher is setsid-detached and loses the tty, so it cannot resolve
    # the layout itself — the display pass resolves it and passes it along.
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    cache_file=$(starship_cache_path date "$(starship_cache_client).$size")
    cache_display "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  --refresh)
    cache_refresh "${2:?}" render "${3:-}"
    ;;
  --guard)
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path date "$(starship_cache_client).$size")
    cache_gate "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  *) usage ;;
esac
