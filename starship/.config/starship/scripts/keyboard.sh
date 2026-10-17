#!/usr/bin/env bash
# Bluetooth keyboard battery segment: gate + live render; keyboard-util.sh
# owns the fetch cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

usage() {
  echo "Usage: $(basename "$0") --display | --guard"
  exit 1
}

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$(layout_size_fast)}
  local data left right

  data=$("$script_dir/keyboard-util.sh") || exit 1
  left="${data%% *}"
  right="${data##* }"
  [[ -z "$left" ]] && exit 1

  if [[ "$size" != wide ]]; then
    icon="$(nerd_font_icon keyboard)"; icon="${icon% }"
    printf '%s%s\033[0m%s %s\033[0m' \
      "$(level_color "$left")" "$icon" \
      "$(level_color "$right")" "$icon"
  else
    printf '%s%s%s\033[0m %s%s%s\033[0m' \
      "$(level_color "$left")" "$(nerd_font_icon keyboard)" "$left$(nerd_font_icon percent)" \
      "$(level_color "$right")" "$(nerd_font_icon keyboard)" "$right$(nerd_font_icon percent)"
  fi
}

case "${1:-}" in
  --display)
    render "$(layout_size_fast)"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) usage ;;
esac
