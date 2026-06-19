#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
direction="$3"

mapfile -t sessions < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')

current_index=-1
for index in "${!sessions[@]}"; do
  if [[ "${sessions[$index]}" == "$current_session" ]]; then
    current_index=$index
    break
  fi
done

if (( current_index < 0 )); then
  exit 0
fi

case "$direction" in
  prev)
    selected=("${sessions[@]:0:current_index}")
    ;;
  next)
    selected=("${sessions[@]:current_index + 1}")
    ;;
  *)
    exit 1
    ;;
esac

if (( ${#selected[@]} > 0 )); then
  first=true
  for session in "${selected[@]}"; do
    $first && first=false || printf ' '
    if tmux -S "$socket_path" list-windows -t "$session" \
      -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
      printf '#[fg=green]󰅸 %s' "$session"
    else
      printf ' %s' "$session"
    fi
  done
fi
