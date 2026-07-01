#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
pane_id="$3"
host_name="$4"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Build reversed list of sessions before current (newest first on status right)
reversed=""
while read -r s; do
  [[ "$s" == "$current_session" ]] && break
  if tmux -S "$socket_path" list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
    reversed='#[fg=green] 󰅸 '"$s"' #[default]'"${reversed:+$reversed}"
  else
    reversed='#[fg=brightblack]  '"$s"' #[default]'"${reversed:+$reversed}"
  fi
done < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')

if [[ -n "$reversed" ]]; then
  printf '%s' "$reversed"
fi

printf '#[fg=blue]'

printf '#[fg=blue,bg=brightblack,bold]  %s #[default]' "${pane_id#%}"

# DeepSeek balance
"$script_dir/deepseek.sh"

# Battery indicator
"$script_dir/battery.sh"

# Keyboard battery
"$script_dir/keyboard-battery.sh"

if tmux -S "$socket_path" show-environment -t "$current_session" SSH_CONNECTION 2>/dev/null | grep -q '^SSH_CONNECTION='; then
  if [[ "$host_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$host_name" == *:* ]]; then
    display_host="$host_name"
  else
    display_host="${host_name%%.*}"
  fi
  h=0
  for ((i=0; i<${#host_name}; i++)); do
    printf -v c '%d' "'${host_name:$i:1}"
    ((h = (h * 31 + c) % 2147483647))
  done
  bg=$((16 + (h % 216)))
  if (( (bg - 16) / 36 < 2 )); then
    printf '#[fg=colour231,bg=colour%d] %s #[default]' "$bg" "$display_host"
  else
    printf '#[fg=colour232,bg=colour%d] %s #[default]' "$bg" "$display_host"
  fi
fi
