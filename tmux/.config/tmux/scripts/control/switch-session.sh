#!/usr/bin/env bash

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
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --prompt="Switch to/Create new session: "
)
[[ -z "$result" ]] && exit 0

query=$(echo "$result" | head -1)
selection=$(echo "$result" | tail -1)
if [[ "$query" == "$selection" ]]; then
  session="$query"
else
  session=$(echo "$selection" | awk '{print $2}' | cut -d: -f1)
fi
session="${session/#\~/$HOME}"
[[ -z "$session" ]] && exit 0

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
