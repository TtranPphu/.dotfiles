#!/usr/bin/env bash
# Bluetooth mouse battery segment: gate + live render; mouse-util.sh owns the
# fetch cache.
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
  local data cap text

  data=$("$script_dir/mouse-util.sh") || exit 1
  cap="${data%% *}"
  [[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

  if [[ "$size" != wide ]]; then
    text="$(nerd_font_icon mouse)"; text="${text% }"
  else
    text="$(nerd_font_icon mouse)$cap$(nerd_font_icon percent)"
  fi
  printf '%s%s\033[0m' "$(level_color "$cap")" "$text"
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
