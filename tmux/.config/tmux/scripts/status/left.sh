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

# Sessions next to this one in the switcher, shown when there is room.
print_adjacent_sessions() {
  local adjacent_sessions
  adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" next)"

  if [[ -n "$adjacent_sessions" ]]; then
    printf '#[fg=brightblack]%s#[fg=brightblack,bold]┋' "$adjacent_sessions"
  fi
}

# Layout by width — the only place the size decides what shows.
case "$size" in
  narrow)
    ;;
  medium)
    "$script_dir/os.sh"
    "$script_dir/opencode-quota.sh"
    # "$script_dir/llm-quota.sh"
    print_adjacent_sessions
    ;;
  wide)
    "$script_dir/os.sh"
    "$script_dir/opencode-quota.sh"
    # "$script_dir/deepseek-quota.sh"
    # "$script_dir/kimi-quota.sh"
    print_adjacent_sessions
    ;;
esac

printf '#[fg=#000000,bg=blue,bold]▏ %s▕#[bg=default]' "$current_session"
printf '#[fg=brightblack,bold]┋'
