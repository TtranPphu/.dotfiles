#!/usr/bin/env bash
# Apply the current nerd-font type to tmux @nerd_font_* options.
# Usage: nerd-font-tmux.sh [socket-path]
set -u

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sock="${1:-}"

tmux_cmd=(tmux)
[ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")

type="$("$dir/nerd-font.sh" type "$sock")"
export DOTFILES_NERD_FONT="$type"

"${tmux_cmd[@]}" set -g @nerd_font "$type"
for key in prefix copy tree zoom bell win reload; do
  "${tmux_cmd[@]}" set -g "@nerd_font_$key" "$("$dir/nerd-font.sh" get "$key")"
done
"${tmux_cmd[@]}" set -g @nerd_font_win_active "$("$dir/nerd-font.sh" get win.active)"
"${tmux_cmd[@]}" set -g @nerd_font_separator_head "$("$dir/nerd-font.sh" get separator.head)"
"${tmux_cmd[@]}" set -g @nerd_font_separator_tail "$("$dir/nerd-font.sh" get separator.tail)"

"${tmux_cmd[@]}" refresh-client 2>/dev/null
