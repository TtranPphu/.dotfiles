#!/usr/bin/env bash
# Date segment: gate + live render. A date call is cheap, so nothing is cached.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/icon.sh"
  local size=${1:-$(layout_size_fast)}
  local text day suffix icon

  if [[ "$size" == wide ]]; then
    text="$(date '+%y-%m-%d %a')"
  else
    day=$(date +%-d)
    case "$day" in
      1 | 21 | 31) suffix='st' ;;
      2 | 22) suffix='nd' ;;
      3 | 23) suffix='rd' ;;
      *) suffix='th' ;;
    esac
    text="${day}${suffix}"
  fi

  icon="$(nerd_font_icon date)"
  if [[ -n "$icon" ]]; then
    printf '%s%s' "$icon" "$text"
  else
    printf '%s' "$text"
  fi
}

case "${1:-}" in
  --display)
    render "$(layout_size_fast)"
    ;;
  --guard)
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) usage ;;
esac
