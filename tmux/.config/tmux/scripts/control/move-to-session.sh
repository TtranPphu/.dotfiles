#!/usr/bin/env bash
set -uo pipefail

pane_id="${1:-}"
cwd="${2:-}"
current_session="${3:-}"

if [[ -z "$cwd" ]]; then
    cwd=$(tmux display-message -p '#{pane_current_path}')
    pane_id=$(tmux display-message -p '#{pane_id}')
    current_session=$(tmux display-message -p '#{session_name}')
fi

default_session=$(basename "$cwd")
default_session="${default_session#.}"
default_session="${default_session//[^a-zA-Z0-9_-]/-}"
[[ -z "$default_session" ]] && default_session="shell"

win_fmt_act='-F "#{window_active} #{window_index}"'
win_fmt_list='#{?window_bell_flag,󰅸,} #{window_name}'\
'#{?#{>:#{window_panes},1}, (#{window_panes} panes),}'

preview_cmd='s=$(echo {} | awk "{print \$2}" | cut -d: -f1); '\
'i=$(tmux list-windows -t "$s" '"$win_fmt_act"' '\
'  2>/dev/null | sort -k1 -rn | head -1 | cut -d" " -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'

result=$(
  tmux list-sessions -F "#{session_name}" \
  | while read -r s; do
      windows=$(tmux list-windows -t "$s" \
        -F "$win_fmt_list" \
        2>/dev/null | paste -sd '|' | sed 's/|/ | /g')
      if tmux list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
        icon="󰅸"
      else
        icon=""
      fi
      echo "$icon $s: $windows"
    done \
  | fzf-tmux -p 60%,60% --reverse --print-query \
      --query="$default_session" \
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --prompt="Move to session: "
)
[[ -z "$result" ]] && exit 0

line_count=$(echo "$result" | wc -l)
if [[ "$line_count" -gt 1 ]]; then
    target_session=$(echo "$result" | tail -1 | awk '{print $2}' | cut -d: -f1)
else
    target_session="$result"
fi
target_session="${target_session/#\~/$HOME}"

if tmux has-session -t "$target_session" 2>/dev/null; then
    [[ "$current_session" == "$target_session" ]] && { tmux display-message "Already in session \"$target_session\""; exit 0; }

    new_win=$(tmux new-window -P -F '#{window_index}' -t "$target_session" -c "$cwd")
    tmux join-pane -s "$pane_id" -t "${target_session}:${new_win}"
    tmux kill-pane -t "${target_session}:${new_win}.1"
    tmux switch-client -t "$target_session"
else
    dir=$(zoxide query "$target_session" 2>&1) || {
        tmux display-message "zoxide: $(echo "$dir" | head -1)"
        exit 0
    }
    if [[ -n "$dir" ]]; then
        name=$(basename "$dir")
    elif [[ -d "$target_session" ]]; then
        dir="$target_session"
        name=$(basename "$dir")
    else
        tmux display-message "No match for '$target_session'"
        exit 0
    fi
    name="${name#.}"
    name="${name//[^a-zA-Z0-9_-]/-}"
    [[ -z "$name" ]] && name="shell"

    session_created=false
    if ! tmux has-session -t "$name" 2>/dev/null; then
        tmux new-session -d -s "$name" -c "$dir"
        session_created=true
    fi

    new_win=$(tmux new-window -P -F '#{window_index}' -t "$name" -c "$dir")
    tmux join-pane -s "$pane_id" -t "${name}:${new_win}"
    tmux kill-pane -t "${name}:${new_win}.1"

    if [[ "$session_created" == "true" ]]; then
        tmux kill-window -t "${name}:1"
    fi

    tmux switch-client -t "$name"
fi

# Clean up source session if now empty
if ! tmux has-session -t "$current_session" 2>/dev/null; then
    :  # session already gone from pane move
elif tmux list-windows -t "$current_session" 2>/dev/null; then
    :  # session still has windows, keep it
else
    tmux kill-session -t "$current_session"
fi

tmux send -X cancel 2>/dev/null || true
