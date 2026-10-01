#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
width="${3:-}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$width" ]]; then
  width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
fi
export STATUS_WIDTH="$width"
size="$("$script_dir/layout.sh" size "$width")"

if [[ "$size" != narrow ]]; then
  # OS indicator
  "$script_dir/os.sh"
fi

# Balance modules: combined quota in medium, per-provider in wide
case "$size" in
  medium) "$script_dir/llm-quota.sh" ;;
  wide)
    "$script_dir/deepseek.sh"
    "$script_dir/kimi.sh"
    ;;
esac

if [[ "$size" != narrow ]]; then
  adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" next)"

  if [[ -n "$adjacent_sessions" ]]; then
    printf '#[fg=brightblack]%s#[fg=brightblack,bold]┋' "$adjacent_sessions"
  fi
fi

printf '#[fg=#000000,bg=blue,bold]▏ %s▕#[bg=default]' "$current_session"
printf '#[fg=brightblack,bold]┋'
