#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# LLM / OS route indicator
"$script_dir/llm-cache.sh"

# Balance modules: combined LLM quota when narrow, per-provider when wide
export STATUS_WIDTH
STATUS_WIDTH=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -rn | head -1)

if (( STATUS_WIDTH < 144 )); then
  "$script_dir/llm-quota.sh"
else
  "$script_dir/deepseek.sh"
  "$script_dir/kimi.sh"
fi

adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" next)"

if [[ -n "$adjacent_sessions" ]]; then
  printf '#[fg=brightblack]%s' "$adjacent_sessions"
fi

printf '#[fg=#000000,bg=blue,bold]  %s #[bg=default]' "$current_session"
