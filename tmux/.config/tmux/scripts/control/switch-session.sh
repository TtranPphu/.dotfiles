#!/usr/bin/env bash

result=$(tmux list-sessions -F "#{session_name}" | \
  fzf-tmux -p 50%,40% --reverse --print-query \
  --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
  --preview='tmux list-windows -t {} -F "  #{window_index}: #{window_name}" 2>/dev/null' \
  --preview-window='down:40%,wrap' \
  --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
  --prompt="Switch/Create: ")
[[ -z "$result" ]] && exit 0

session=$(echo "$result" | tail -1)
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
  tmux new-session -d -s "$name" -c "$dir" && tmux switch-client -t "$name"
fi
