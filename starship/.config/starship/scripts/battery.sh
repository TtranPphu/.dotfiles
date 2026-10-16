#!/usr/bin/env bash
# Battery segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; the util's upower/PowerShell reads run in a detached
# refresher when the entry is stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$("$script_dir/layout.sh" size)}
  local data bat raw_status idx icon text

  data=$("$script_dir/battery-util.sh") || exit 1
  bat="${data%% *}"
  raw_status="${data##* }"
  [[ -z "$bat" ]] && exit 1

  idx=$(( (bat - 1) / 10 ))

  if [ "$raw_status" = "fully-charged" ]; then
    icon="$(nerd_font_icon battery.full)"
  elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
    icon="$(nerd_font_icon "battery.charging.$idx")"
  else
    icon="$(nerd_font_icon "battery.discharging.$idx")"
  fi

  if [[ "$size" != wide ]]; then
    case "$raw_status" in
      fully-charged)             icon="$(nerd_font_icon battery.full)"; icon="${icon% }" ;;
      charging | pending-charge) icon="$(nerd_font_icon battery.charging.medium)" ;;
      *)                         icon="$(nerd_font_icon "battery.discharging.$idx")"; icon="${icon% }" ;;
    esac
    text="$icon"
  else
    text="$icon$bat$(nerd_font_icon percent)"
  fi

  printf '%s%s\033[0m' "$(level_color "$bat")" "$text"
}

case "${1:-}" in
  --display)
    # The refresher is setsid-detached and loses the tty, so it cannot resolve
    # the layout itself — the display pass resolves it and passes it along.
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    cache_file=$(starship_cache_path battery "$(starship_cache_client).$size")
    cache_display "$cache_file" 30 "$0" --refresh "$cache_file" "$size"
    ;;
  --refresh)
    cache_refresh "${2:?}" render "${3:-}"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path battery "$(starship_cache_client).$size")
    cache_gate "$cache_file" 30 "$0" --refresh "$cache_file" "$size"
    ;;
  *) usage ;;
esac
