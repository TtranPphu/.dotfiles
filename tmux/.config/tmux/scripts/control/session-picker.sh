#!/usr/bin/env bash

result=$(tmux list-sessions -F "#{session_name}" | fzf-tmux -p 40%,40% --reverse --print-query --prompt="Switch/Create: ")
[[ -z "$result" ]] && exit 0

session=$(echo "$result" | tail -1)

if tmux has-session -t "$session" 2>/dev/null; then
  tmux switch-client -t "$session"
else
  dir=$(zoxide query "$session" 2>/dev/null)
  if [[ -n "$dir" ]]; then
    name=$(basename "$dir")
    name="${name#.}"
    name="${name//[^a-zA-Z0-9_-]/-}"
    [[ -z "$name" ]] && name="shell"
    tmux new-session -d -s "$name" -c "$dir" && tmux switch-client -t "$name"
  else
    tmux display-message "zoxide: no match for '$session'"
  fi
fi
