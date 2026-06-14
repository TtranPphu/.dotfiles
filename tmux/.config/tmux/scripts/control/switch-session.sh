#!/usr/bin/env bash

win_fmt_act='-F "#{window_active} #{window_index}"'
win_fmt_list='#{window_name} (#{window_panes} '\
'#{?#{==:#{window_panes},1},pane,panes})'

preview_cmd='s=$(echo {} | cut -d: -f1); '\
'i=$(tmux list-windows -t "$s" '"$win_fmt_act"' '\
'  2>/dev/null | sort -k1 -rn | head -1 | cut -d" " -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'

result=$(
  tmux list-sessions -F "#{session_name}" \
  | while read -r s; do
      windows=$(tmux list-windows -t "$s" \
        -F "$win_fmt_list" \
        2>/dev/null | paste -sd " ")
      echo "$s: $windows"
    done \
  | fzf-tmux -p 60%,60% --reverse --print-query \
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --prompt="Switch to/Create new session: "
)
[[ -z "$result" ]] && exit 0

session=$(echo "$result" | tail -1 | cut -d: -f1)
session="${session/#\~/$HOME}"

if tmux has-session -t "$session" 2>/dev/null; then
  tmux switch-client -t "$session"
else
  dir=$(zoxide query "$session" 2>/dev/null)
  if [[ -n "$dir" ]]; then
    name=$(basename "$dir")
  elif [[ -d "$session" ]]; then
    dir="$session"
    name=$(basename "$dir")
  else
    tmux display-message "No match for '$session'"
    exit 0
  fi
  name="${name#.}"
  name="${name//[^a-zA-Z0-9_-]/-}"
  [[ -z "$name" ]] && name="shell"
  tmux new-session -d -s "$name" -c "$dir" \
    && tmux switch-client -t "$name"
fi
