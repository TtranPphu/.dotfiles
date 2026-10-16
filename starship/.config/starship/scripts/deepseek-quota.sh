#!/bin/bash
# Starship custom module: DeepSeek account balance (wide terminals), rendered
# through the two-pass cache (cache.sh): the prompt only reads the cache; the
# util's cache/network reads run in a detached refresher when the entry is
# stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local balance

  "$script_dir/llm-quota-util.sh" --configured deepseek || exit 1
  balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
  awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  printf "%s%s%.2f" "$(nerd_font_icon deepseek)" "$(nerd_font_icon usd)" "$balance"
}

case "${1:-}" in
  --display | "")
    cache_file=$(starship_cache_path deepseek-quota "$(starship_cache_client)")
    cache_display "$cache_file" 60 "$0" --refresh "$cache_file"
    ;;
  --refresh)
    cache_refresh "${2:?}" render
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$script_dir/layout.sh" is wide || exit 1
    cache_file=$(starship_cache_path deepseek-quota "$(starship_cache_client)")
    cache_gate "$cache_file" 60 "$0" --refresh "$cache_file"
    ;;
  *) exit 2 ;;
esac
