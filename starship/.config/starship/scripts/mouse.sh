#!/usr/bin/env bash
# Bluetooth mouse battery segment, rendered through the two-pass cache
# (cache.sh): the prompt only reads the cache; the util's DBus/SSH reads run
# in a detached refresher when the entry is stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard"
  exit 1
}

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$("$script_dir/layout.sh" size)}
  local data cap text

  data=$("$script_dir/mouse-util.sh") || exit 1
  cap="${data%% *}"
  [[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

  if [[ "$size" != wide ]]; then
    text="$(nerd_font_icon mouse.medium)"
  else
    text="$(nerd_font_icon mouse)$cap$(nerd_font_icon percent)"
  fi
  printf '%s%s\033[0m' "$(level_color "$cap")" "$text"
}

case "${1:-}" in
  --display)
    # The refresher is setsid-detached and loses the tty, so it cannot resolve
    # the layout itself — the display pass resolves it and passes it along.
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    cache_file=$(starship_cache_path mouse "$(starship_cache_client).$size")
    cache_display "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  --refresh)
    cache_refresh "${2:?}" render "${3:-}"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path mouse "$(starship_cache_client).$size")
    cache_gate "$cache_file" 15 "$0" --refresh "$cache_file" "$size"
    ;;
  *) usage ;;
esac
