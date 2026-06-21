#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
pane_id="$3"
pane_mode="$4"
client_prefix="$5"
window_zoomed_flag="$6"
host_name="$7"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Build reversed list of sessions before current (newest first on status right)
reversed=""
while read -r s; do
  [[ "$s" == "$current_session" ]] && break
  if tmux -S "$socket_path" list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
    reversed=' #[fg=green]󰅸 '"$s"' '"${reversed:+$reversed}"
  else
    reversed="  $s ${reversed:+$reversed}"
  fi
done < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')

if [[ -n "$reversed" ]]; then
  printf '#[fg=brightblack]%s' "$reversed"
fi

printf '#[fg=blue]'

if [[ -n "${SSH_CONNECTION-}" || -n "${SSH_CLIENT-}" ]]; then
  printf '#[fg=brightblack]%s ' "$host_name"
fi

printf '#[fg=blue,bg=brightblack,bold]  %s #[default]' "${pane_id#%}"

# DeepSeek balance
"$script_dir/deepseek.sh"

# Battery indicator
"$script_dir/battery.sh"
