#!/usr/bin/env bash
# Status-left. The display path only reads the cache (cache.sh); the modules
# run in a detached refresher so a tmux redraw never waits on them.

script_dir="${BASH_SOURCE[0]%/*}"
if [ "$script_dir" = "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$script_dir/cache.sh"

render() {
  local socket_path="$1" current_session="$2" width="${3:-}" client_pid="${4:-}"
  source "$script_dir/nerd-font.sh"

  if [[ -z "$width" ]]; then
    width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  fi
  export STATUS_WIDTH="$width"
  status_nerd_font_type "$script_dir" "$socket_path" "$client_pid"
  [[ -n "$STATUS_NERD_FONT_TYPE" ]] && export DOTFILES_NERD_FONT="$STATUS_NERD_FONT_TYPE"
  export NERD_FONT_SOCKET="$socket_path"
  status_layout_size "$script_dir" "$width"
  local size="$STATUS_LAYOUT_SIZE"

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

  printf '#[fg=#000000,bg=blue,bold]▏%s%s▕#[bg=default]' "$(nerd_font_icon session)" "$current_session"
  printf '#[fg=brightblack,bold]┋'
}

case "${1:-}" in
  --refresh) cache_refresh "${2:?}" render "${@:3}" ;;
  *)
    # The key covers everything that changes the output: session, client width
    # and pid (per-client font type). TTL is loose — quota/battery move slowly.
    key="left.${2:-}.${3:-}.${4:-}.${DOTFILES_NERD_FONT:-auto}"
    key="${key//[^a-zA-Z0-9]/_}"
    cache_display "$CACHE_DIR/$key.out" 60 "$0" --refresh "$CACHE_DIR/$key.out" "$@"
    ;;
esac
