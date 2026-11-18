#!/usr/bin/env bash
# prefix+S picker: "new" splits the invoking pane the usual way; any other
# choice moves that pane into the invoking window with the same orientation.

invoker="${1:?usage: $(basename "$0") <pane-id>}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

path=$(tmux display-message -p -t "$invoker" '#{pane_current_path}') || exit 1
win=$(tmux display-message -p -t "$invoker" '#{window_id}') || exit 1

format=$'#{window_index}.#{pane_index}\t#{pane_current_command}\t#{pane_current_path}\t#{pane_id}\t#{window_id}'
list=$(
  printf '%-6s %-20s %s\t%s\n' new '(new split)' "$path" new
  tmux list-panes -s -t "$invoker" -F "$format" |
    awk -F '\t' -v me="$invoker" -v win="$win" \
      '$4 != me && $5 != win { printf "%-6s %-20s %s\t%s\n", $1, $2, $3, $4 }'
)

# FZF_DEFAULT_OPTS may force --popup/--height, which cannot nest inside this
# tmux popup (fzf exits immediately); run with clean options.
choice=$(printf '%s\n' "$list" | FZF_DEFAULT_OPTS= fzf --no-sort --reverse \
  --delimiter='\t' --with-nth=1 \
  --header='enter: split here | pick a pane: move it here' \
  --prompt='pane> ')
[ -n "$choice" ] || exit 0

target=$(printf '%s' "$choice" | cut -f2)
[ -n "$target" ] || exit 0

if [ "$target" = new ]; then
  "$script_dir/auto-split.sh" -t "$invoker" &&
    "$script_dir/../hook/balance-layout.sh" "$invoker"
  exit
fi

width=$(tmux display-message -p -t "$invoker" '#{pane_width}')
height=$(tmux display-message -p -t "$invoker" '#{pane_height}')
dir=-v
[ "$width" -gt $((height * 2)) ] && dir=-h

tmux join-pane "$dir" -s "$target" -t "$invoker" || exit 1
"$script_dir/../hook/balance-layout.sh" "$invoker"
