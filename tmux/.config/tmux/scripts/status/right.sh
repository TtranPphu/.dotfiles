#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
pane_id="$3"
pane_mode="$4"
client_prefix="$5"
window_zoomed_flag="$6"
host_name="$7"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" prev)"

# Reverse session order so newest (bottom of session list) appears first on the status right
if [[ -n "$adjacent_sessions" ]]; then
  reversed=$(echo "$adjacent_sessions" | awk -F'' '
    {
      result = ""
      for (i = NF; i >= 1; i--) {
        gsub(/^[ ]+|[ ]+$/, "", $i)
        if ($i != "") {
          if (result == "") result = " " $i
          else result = result "  " $i
        }
      }
      print result
    }
  ')
  printf '#[fg=brightblack]%s ' "$reversed"
fi

printf '#[fg=blue]'

if [[ -n "${SSH_CONNECTION-}" || -n "${SSH_CLIENT-}" ]]; then
  printf '#[fg=brightblack]%s ' "$host_name"
fi

printf '#[fg=blue,bg=brightblack,bold]  #[fg=blue,bg=brightblack,bold]%s ' "${pane_id#%}"

# DeepSeek balance
"$script_dir/deepseek.sh"

# Battery indicator
"$script_dir/battery.sh"
