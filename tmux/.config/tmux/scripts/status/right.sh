#!/usr/bin/env bash
# Status-right (two parts: adjacent sessions, then the pills). Both parts
# render live on every redraw from the fetch caches; the only prerequisite
# cached here is the per-client font type (a ~10 ms client scan), so the
# modules below inherit DOTFILES_NERD_FONT and their icons stay cheap.

script_dir="${BASH_SOURCE[0]%/*}"
if [ "$script_dir" = "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$script_dir/cache.sh"
source "$script_dir/color.sh"
# layout.sh provides layout_size_fast; sessions_display and render both use it.
source "$script_dir/layout.sh"

# sessions_display <socket> <current-session> <width> <client-pid>
#
# Renders the adjacent-session list live: a killed, created or renamed session
# must show on the very next redraw, so this part is never cached — only the
# slow prerequisites (font type) come from their loose caches.
# One list-windows -a call replaces list-sessions plus a per-session
# list-windows: sessions come back in the same order (alphabetical) and a
# session counts as bell when any of its windows is, so the output matches the
# uncached implementation.
sessions_display() {
  local socket_path="${1:-}" current_session="${2:-}" width="${3:-}" client_pid="${4:-}"
  local s flag line size reversed="" first
  local -A has_bell=()
  local -A seen=()
  local -a order=()
  local fg_green fg_muted icon_bell icon_session style out

  if [[ -z "$width" ]]; then
    width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  fi

  export STATUS_WIDTH="$width"
  size=$(layout_size_fast)
  fg_muted=$(color_get muted)

  if [[ "$size" != narrow ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      s="${line% *}"
      flag="${line##* }"
      if [[ -z "${seen[$s]:-}" ]]; then
        seen[$s]=1
        order+=("$s")
      fi
      [[ "$flag" == 1 ]] && has_bell[$s]=1
    done < <(tmux -S "$socket_path" list-windows -a -F '#{session_name} #{window_bell_flag}' 2>/dev/null)

    # Icons are only needed when a session actually shows (the common
    # single-session case prints just the separator). They come from their own
    # loose caches, so the live path never sources nerd-font.sh or forks awk.
    local glyph_bell="" glyph_session=""
    first="${order[0]:-}"
    if [[ -n "$first" && "$first" != "$current_session" ]]; then
      status_nerd_font_type "$script_dir" "$socket_path" "$client_pid"
      export NERD_FONT_SOCKET="$socket_path"
      if [[ -n "$STATUS_NERD_FONT_TYPE" ]]; then
        export DOTFILES_NERD_FONT="$STATUS_NERD_FONT_TYPE"
        status_nerd_font_glyph "$script_dir" bell
        glyph_bell="$STATUS_NERD_FONT_GLYPH"
        status_nerd_font_glyph "$script_dir" session
        glyph_session="$STATUS_NERD_FONT_GLYPH"
      else
        # No type resolved: fall back to the in-process resolver.
        source "$script_dir/nerd-font.sh"
      fi
      icon_bell="${glyph_bell:-$(nerd_font_icon bell)}"
      icon_session="${glyph_session:-$(nerd_font_icon session)}"
    fi

    fg_green=$(color_get green)
    for s in "${order[@]}"; do
      [[ "$s" == "$current_session" ]] && break
      if [[ -n "${has_bell[$s]:-}" ]]; then
        reversed="#[fg=$fg_green] $icon_bell$s #[default]${reversed:+#[fg=$fg_muted,bold]┋$reversed}"
      else
        reversed="#[fg=$fg_muted] $icon_session$s #[default]${reversed:+#[fg=$fg_muted,bold]┋$reversed}"
      fi
    done
  fi

  # Always emit the separator, even when narrow (the list itself is empty then).
  style=$(printf '#[fg=%s,bold]' "$fg_muted")
  out="┋$reversed"
  printf '%s%s' "$style" "$out"
}

render() {
  local socket_path="${1:-}" current_session="${2:-}" pane_id="${3:-}" width="${4:-}" part="${5:-}" client_pid="${6:-}"
  source "$script_dir/nerd-font.sh"

  if [[ -z "$width" ]]; then
    width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  fi
  export STATUS_WIDTH="$width"
  status_nerd_font_type "$script_dir" "$socket_path" "$client_pid"
  [[ -n "$STATUS_NERD_FONT_TYPE" ]] && export DOTFILES_NERD_FONT="$STATUS_NERD_FONT_TYPE"
  export NERD_FONT_SOCKET="$socket_path"
  # Pin the rendering client's connection so device and signal reads resolve
  # its machine; empty for a local client (no tmux-env fallback then).
  if [ -n "$client_pid" ]; then
    export DOTFILES_CLIENT_SSH="$(tr '\0' '\n' < "/proc/$client_pid/environ" 2>/dev/null | sed -n 's/^SSH_CONNECTION=//p')"
  fi
  local size
  size=$(layout_size_fast)

  local fg_muted fg_green fg_blue icon_bell icon_session
  local style reset out
  fg_muted=$(color_get muted)

  # Build reversed list of sessions before current (newest first on status right)
  local reversed=""
  if [[ "$size" != narrow ]]; then
    local sessions=() s
    mapfile -t sessions < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')
    if [[ "${sessions[0]:-}" != "$current_session" ]]; then
      fg_green=$(color_get green)
      icon_bell=$(nerd_font_icon bell)
      icon_session=$(nerd_font_icon session)
    fi
    for s in "${sessions[@]}"; do
      [[ "$s" == "$current_session" ]] && break
      if tmux -S "$socket_path" list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
        reversed="#[fg=$fg_green] $icon_bell$s #[default]${reversed:+#[fg=$fg_muted,bold]┋$reversed}"
      else
        reversed="#[fg=$fg_muted] $icon_session$s #[default]${reversed:+#[fg=$fg_muted,bold]┋$reversed}"
      fi
    done
  fi

  if [[ -z $part || $part == sessions ]]; then
    # Always emit the separator, even when narrow (the list itself is empty then).
    style=$(printf '#[fg=%s,bold]' "$fg_muted")
    out="┋$reversed"
    printf '%s%s' "$style" "$out"
  fi

  [[ $part == sessions ]] && exit 0

  fg_blue=$(color_get blue)
  style=$(printf '#[fg=%s]' "$fg_blue")
  printf '%s' "$style"

  # Speech recording indicator
  "$script_dir/speech.sh"

  local pane_num pane_label icon_pane
  pane_num="$(printf '%02d' "${pane_id#%}")"
  icon_pane=$(nerd_font_icon pane)
  pane_label="$icon_pane$pane_num"
  local icon_head icon_flat
  icon_head=$(nerd_font_icon separator.head)
  icon_flat=$(nerd_font_icon separator.flat)
  style=$(printf '#[fg=%s,bg=%s,bold]' "$fg_muted" "$fg_blue")
  reset='#[default]'
  out="$icon_head$pane_label$icon_flat"
  printf '%s%s%s' "$style" "$out" "$reset"

  if [[ "$size" != narrow ]]; then
    # Battery indicator
    "$script_dir/battery.sh"

    # Headphone battery
    "$script_dir/headphone.sh"

    # Mouse battery
    "$script_dir/mouse.sh"

    # Keyboard battery
    "$script_dir/keyboard.sh"

    # Host pill: when the rendering client is remote, so each client sees its own
    # status, or when running in docker (matching starship's host condition).
    # Without a client pid (manual invocations) fall back to any attached client.
    # The /proc check avoids the session environment, which can hold a stale
    # SSH_CONNECTION long after the SSH client detached.
    if [ -f /.dockerenv ]; then
      "$script_dir/hostname.sh" "$socket_path" "$current_session"
    else
      local pid
      if [ -z "$client_pid" ]; then
        client_pid=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_pid}' 2>/dev/null)
      fi
      for pid in $client_pid; do
        if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -q '^SSH_CONNECTION='; then
          "$script_dir/hostname.sh" "$socket_path" "$current_session"
          break
        fi
      done
    fi
  fi
}

# The sessions part and the pills part are two separate status entries; both
# render live (the sessions part is action-driven, the pills come from the
# fetch caches).
if [[ "${5:-}" == sessions ]]; then
  sessions_display "${1:-}" "${2:-}" "${4:-}" "${6:-}"
else
  render "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
fi
