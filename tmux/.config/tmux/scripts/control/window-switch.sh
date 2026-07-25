#!/usr/bin/env bash

preview_cmd='key=$(echo {} | cut -d" " -f1); '\
's=$(echo "$key" | cut -d: -f1); '\
'i=$(echo "$key" | cut -d: -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'

wm_status="$HOME/.config/tmux/scripts/status"

result=$(
  while read -r s; do
    tmux list-windows -t "$s" -F '#{session_name}:#{window_index}|#{pane_tty}|#{pane_current_command}|#{window_panes}|#{window_bell_flag}' 2>/dev/null
  done < <(tmux list-sessions -F '#{session_name}') \
  | while IFS='|' read -r key tty cmd panes bell; do
      name=$("$wm_status/window-name.sh" "$tty" "$cmd")
      session=${key%%:*}
      bell_icon=$([ "$bell" = "1" ] && echo "󰅸" || echo "")
      panes_suffix=$([ "${panes:-1}" -gt 1 ] && echo ": $panes panes" || echo "")
      echo "$key  $session - $bell_icon $name$panes_suffix"
    done \
  | fzf-tmux -p 60%,60% --reverse --print-query \
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --with-nth=2.. \
      --prompt="Switch to window: "
)
[[ -z "$result" ]] && exit 0

query=$(echo "$result" | head -1)
selection=$(echo "$result" | tail -1)
if [[ "$query" == "$selection" ]]; then
  tmux display-message "No window selected"
  exit 0
fi

target=$(echo "$selection" | cut -d" " -f1)
[[ -z "$target" ]] && exit 0

session=$(echo "$target" | cut -d: -f1)
window=$(echo "$target" | cut -d: -f2)
tmux switch-client -t "$session"
tmux select-window -t ":$window"
