#!/usr/bin/env bash
# Status-left. Rendered live on every redraw from the fetch caches; the only
# prerequisite cached here is the per-client font type (a ~10 ms client scan),
# so the modules below inherit DOTFILES_NERD_FONT and their icons stay cheap.

script_dir="${BASH_SOURCE[0]%/*}"
if [ "$script_dir" = "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$script_dir/cache.sh"
source "$script_dir/color.sh"

render() {
  local socket_path="${1:-}" current_session="${2:-}" width="${3:-}" client_pid="${4:-}"
  local fg_muted fg_ink fg_blue
  local icon_head icon_session icon_flat out style reset
  source "$script_dir/icon.sh"
  source "$script_dir/layout.sh"

  if [[ -z "$width" ]]; then
    width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  fi
  export STATUS_WIDTH="$width"
  status_nerd_font_type "$script_dir" "$socket_path" "$client_pid"
  [[ -n "$STATUS_NERD_FONT_TYPE" ]] && export DOTFILES_NERD_FONT="$STATUS_NERD_FONT_TYPE"
  export NERD_FONT_SOCKET="$socket_path"
  local size
  size=$(layout_size_fast)

  fg_muted=$(color_get muted)
  fg_ink=$(color_get ink)
  fg_blue=$(color_get blue)

  # Sessions next to this one in the switcher, shown when there is room.
  print_adjacent_sessions() {
    local adjacent_sessions style style_divider adjacent_out
    adjacent_sessions="$("$script_dir/session-list.sh" "$socket_path" "$current_session" next)"

    if [[ -n "$adjacent_sessions" ]]; then
      style=$(printf '#[fg=%s]' "$fg_muted")
      style_divider=$(printf '#[fg=%s,bold]' "$fg_muted")
      adjacent_out="$adjacent_sessions$style_divider┋"
      printf '%s%s' "$style" "$adjacent_out"
    fi
  }

  # Layout by width — the only place the size decides what shows.
  case "$size" in
    narrow)
      ;;
    medium)
      "$script_dir/os.sh"
      "$script_dir/llm-quota.sh"
      print_adjacent_sessions
      ;;
    wide)
      "$script_dir/os.sh"
      "$script_dir/opencode-quota.sh"
      "$script_dir/deepseek-quota.sh"
      "$script_dir/kimi-quota.sh"
      print_adjacent_sessions
      ;;
  esac

  icon_head=$(nerd_font_icon separator.head)
  icon_session=$(nerd_font_icon session.active)
  icon_flat=$(nerd_font_icon separator.flat)
  style=$(printf '#[fg=%s,bg=%s,bold]' "$fg_ink" "$fg_blue")
  reset='#[bg=default]'
  out="$icon_head$icon_session$current_session$icon_flat"
  printf '%s%s%s' "$style" "$out" "$reset"
  style=$(printf '#[fg=%s,bold]' "$fg_muted")
  printf '%s┋' "$style"
}

render "$@"
