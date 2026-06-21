#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# LLM / OS route indicator
"$script_dir/llm.sh"

adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" next)"

if [[ -n "$adjacent_sessions" ]]; then
  printf '#[fg=brightblack]%s ' "$adjacent_sessions"
fi

printf '#[fg=#000000,bg=blue,bold]  %s #[bg=default]' "$current_session"
