#!/usr/bin/env bash
# Apply the current nerd-font mode to tmux @nerd_font_* options.
# Usage: nerd-font-tmux.sh [socket-path]
set -u

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sock="${1:-}"

tmux_cmd=(tmux)
[ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")

mode="$("$dir/nerd-font.sh" mode "$sock")"
export DOTFILES_NERD_FONT="$mode"

"${tmux_cmd[@]}" set -g @nerd_font "$mode"
for key in prefix copy tree zoom bell win reload; do
  "${tmux_cmd[@]}" set -g "@nerd_font_$key" "$("$dir/nerd-font.sh" get "$key")"
done

"${tmux_cmd[@]}" refresh-client 2>/dev/null
