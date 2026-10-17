#!/usr/bin/env bash
# Bluetooth headphone battery segment: gate + live render; headphone-util.sh
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
  local data val text

  data=$("$script_dir/headphone-util.sh") || exit 1
  [[ -z "$data" || "$data" -eq 0 ]] && exit 1
  val="$data"

  local wide_icon medium_icon
  wide_icon="$(nerd_font_icon headphone)"
  medium_icon="$(nerd_font_icon headphone.medium)"

  if [[ "$size" != wide ]]; then
    text="$medium_icon"
  else
    text="$wide_icon$val$(nerd_font_icon percent)"
  fi
  printf '%s%s\033[0m' "$(level_color "$val")" "$text"
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
