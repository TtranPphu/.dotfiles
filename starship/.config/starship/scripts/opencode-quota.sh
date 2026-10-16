#!/bin/bash
# Starship custom module: OpenCode Go quota usage, rendered through the
# two-pass cache (cache.sh): the prompt only reads the cache; the util's
# cache/network reads run in a detached refresher when the entry is stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$("$script_dir/layout.sh" size)}
  local values rolling monthly pct icon

  [ "$size" = narrow ] && exit 1

  values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
  read -r rolling _ monthly <<<"$values"

  pct="$(nerd_font_icon percent)"
  icon="$(nerd_font_icon opencode)"

  # Rolling quota drives the foreground: low usage green, near limit red.
  printf '%s%s%s%s\033[0m' "$(level_color "$rolling")" "$icon" "$monthly" "$pct"
}

case "${1:-}" in
  --display | "")
    # The refresher is setsid-detached and loses the tty, so it cannot resolve
    # the layout itself — the display pass resolves it and passes it along.
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    cache_file=$(starship_cache_path opencode-quota "$(starship_cache_client).$size")
    cache_display "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  --refresh)
    cache_refresh "${2:?}" render "${3:-}"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path opencode-quota "$(starship_cache_client).$size")
    cache_gate "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  *) exit 2 ;;
esac
