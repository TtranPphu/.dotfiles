#!/usr/bin/env bash
# Apply the current icons mode to tmux @icon_* options.
# Usage: icons-tmux.sh [socket-path]
set -u

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sock="${1:-}"

tmux_cmd=(tmux)
[ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")

mode="$("$dir/icons.sh" mode "$sock")"
export DOTFILES_ICONS="$mode"

"${tmux_cmd[@]}" set -g @icons "$mode"
for key in prefix copy tree zoom bell win reload; do
  "${tmux_cmd[@]}" set -g "@icon_$key" "$("$dir/icons.sh" get "$key")"
done

"${tmux_cmd[@]}" refresh-client 2>/dev/null
