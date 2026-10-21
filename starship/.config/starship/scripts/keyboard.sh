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
  local data left right icon_keyboard icon_percent text_left text_right fg_left fg_right

  data=$("$script_dir/keyboard-util.sh") || exit 1
  left="${data%% *}"
  right="${data##* }"
  [[ -z "$left" ]] && exit 1

  icon_keyboard="$(nerd_font_icon keyboard)"
  fg_left=$(level_color "$left")
  fg_right=$(level_color "$right")

  if [[ "$size" != wide ]]; then
    icon_keyboard="${icon_keyboard% }"
    text_left="$icon_keyboard"
    text_right="$icon_keyboard"
    reset=$'\033[0m'
    printf '%s%s%s%s %s%s' "$fg_left" "$text_left" "$reset" "$fg_right" "$text_right" "$reset"
  else
    icon_percent="$(nerd_font_icon percent)"
    text_left="$icon_keyboard$left$icon_percent"
    text_right="$icon_keyboard$right$icon_percent"
    reset=$'\033[0m'
    printf '%s%s%s %s%s%s' "$fg_left" "$text_left" "$reset" "$fg_right" "$text_right" "$reset"
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
