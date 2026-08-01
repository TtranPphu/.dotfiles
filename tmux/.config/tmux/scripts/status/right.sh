#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
pane_id="$3"
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

# Speech recording indicator
"$script_dir/speech.sh"

printf '#[fg=blue,bg=brightblack,bold]  %s #[default]' "${pane_id#%}"

# Balance modules: combined LLM quota when narrow, per-provider when wide
export STATUS_WIDTH
STATUS_WIDTH=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -rn | head -1)

if (( STATUS_WIDTH < 144 )); then
  "$script_dir/llm.sh"
else
  "$script_dir/kimi.sh"
  "$script_dir/deepseek.sh"
fi

# Battery indicator
"$script_dir/battery.sh"

# Keyboard battery
"$script_dir/keyboard.sh"

# Mouse battery
"$script_dir/mouse.sh"

# Headphone battery
"$script_dir/headphone.sh"

if tmux -S "$socket_path" show-environment -t "$current_session" SSH_CONNECTION 2>/dev/null | grep -q '^SSH_CONNECTION='; then
  "$script_dir/hostname.sh"
fi
