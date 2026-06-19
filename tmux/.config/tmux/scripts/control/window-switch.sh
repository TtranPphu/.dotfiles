#!/usr/bin/env bash

preview_cmd='key=$(echo {} | cut -d" " -f1); '\
's=$(echo "$key" | cut -d: -f1); '\
'i=$(echo "$key" | cut -d: -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'

win_fmt='#{session_name}:#{window_index} '\
'#{?window_bell_flag,󰅸,} '\
'#{session_name} - #{window_name}: '\
'#{window_panes} #{?#{==:#{window_panes},1},pane,panes}'

result=$(
  tmux list-windows -a \
    -F "$win_fmt" \
  | fzf-tmux -p 60%,60% --reverse --print-query \
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --with-nth=2.. \
      --prompt="Switch to window: "
)
[[ -z "$result" ]] && exit 0

target=$(echo "$result" | tail -1 | cut -d" " -f1)
[[ -z "$target" ]] && exit 0

session=$(echo "$target" | cut -d: -f1)
window=$(echo "$target" | cut -d: -f2)
tmux switch-client -t "$session"
tmux select-window -t ":$window"
