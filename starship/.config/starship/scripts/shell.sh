#!/usr/bin/env bash
# Shell segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local shell icon

  shell="${STARSHIP_SHELL:-unknown-shell}"
  icon="$(nerd_font_icon "shell.$shell")"
  if [[ -n "$icon" ]]; then
    printf '%s%s\n' "$icon" "$shell"
  else
    printf '%s\n' "$shell"
  fi
}

case "${1:-}" in
  --display | "")
    cache_file=$(starship_cache_path shell "$(starship_cache_client).${STARSHIP_SHELL:-unknown}")
    cache_display "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  --refresh)
    cache_refresh "${2:?}" render
    ;;
  --guard)
    cache_file=$(starship_cache_path shell "$(starship_cache_client).${STARSHIP_SHELL:-unknown}")
    cache_gate "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  *) exit 2 ;;
esac
