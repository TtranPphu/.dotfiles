#!/usr/bin/env bash
# Apply the color catalog to tmux @color_* options.
# Usage: color-tmux.sh [socket-path]
set -u

dir="$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=/dev/null
source "$dir/color.sh"
sock="${1:-}"

tmux_cmd=(tmux)
[ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")

while IFS=';' read -r key _ value _; do
  case "$key" in '' | '#'* | key) continue ;; esac
  [ -n "$value" ] || continue
  "${tmux_cmd[@]}" set -g "@color_${key//./_}" "$value"
done <"$_color_catalog"

"${tmux_cmd[@]}" refresh-client 2>/dev/null
