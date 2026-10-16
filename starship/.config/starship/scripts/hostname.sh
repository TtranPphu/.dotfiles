#!/usr/bin/env bash
# Hostname segment, rendered through the two-pass cache (cache.sh): the prompt
# only reads the cache; hostname/SSH-quality reads run in a detached refresher
# when the entry is stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$("$script_dir/layout.sh" size)}
  local data level ramp icon

  [[ "$size" == narrow ]] && exit 1

  data=$("$script_dir/hostname-util.sh") || exit 1
  [[ -z "$data" ]] && exit 1

  # Over SSH color the host with the connection quality ramp (10 = green, 1 = red);
  # medium drops the name. Without SSH the module only shows in wide.
  if level=$("$script_dir/ssh-quality-util.sh" level 2>/dev/null); then
    ramp=$((level * 10))
    icon=$("$script_dir/ssh-quality-util.sh" signal 2>/dev/null)
    if [[ "$size" == wide ]]; then
      printf '%s%s%s%s\033[0m' "$(level_color "$ramp")" "$icon" "$(nerd_font_icon host)" "$data"
    else
      printf '%s%s\033[0m' "$(level_color "$ramp")" "${icon% }"
    fi
  else
    [[ "$size" == wide ]] || exit 1
    printf '%s%s' "$(nerd_font_icon host)" "$data"
  fi
}

case "${1:-}" in
  --display | "")
    # The refresher is setsid-detached and loses the tty, so it cannot resolve
    # the layout itself — the display pass resolves it and passes it along.
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    cache_file=$(starship_cache_path hostname "$(starship_cache_client).$size")
    cache_display "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  --refresh)
    cache_refresh "${2:?}" render "${3:-}"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ -n "${SSH_CONNECTION:-}" ] || [ -f /.dockerenv ] || exit 1
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path hostname "$(starship_cache_client).$size")
    cache_gate "$cache_file" 60 "$0" --refresh "$cache_file" "$size"
    ;;
  *) exit 2 ;;
esac
