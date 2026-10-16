#!/usr/bin/env bash
# Status-right (two parts: adjacent sessions, then the pills). The sessions
# part is action-driven and renders live on every redraw; the pills part is
# cached (cache.sh) and its modules run in a detached refresher, so a tmux
# redraw never waits on them.

script_dir="${BASH_SOURCE[0]%/*}"
if [ "$script_dir" = "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
source "$script_dir/cache.sh"

# sessions_display <socket> <current-session> <width> <client-pid>
#
# Renders the adjacent-session list live: a killed, created or renamed session
# must show on the very next redraw, so this part is never cached — only the
# slow prerequisites (font type, layout size) come from their loose caches.
# One list-windows -a call replaces list-sessions plus a per-session
# list-windows: sessions come back in the same order (alphabetical) and a
# session counts as bell when any of its windows is, so the output matches the
# uncached implementation.
sessions_display() {
  local socket_path="$1" current_session="$2" width="${3:-}" client_pid="${4:-}"
  local s flag line size reversed="" first
  local -A has_bell=()
  local -A seen=()
  local -a order=()

  if [[ -z "$width" ]]; then
    width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  fi

  status_layout_size "$script_dir" "$width"
  size="$STATUS_LAYOUT_SIZE"

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
    local glyph_bell="" glyph_session="" icon
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
    fi

    for s in "${order[@]}"; do
      [[ "$s" == "$current_session" ]] && break
      if [[ -n "${has_bell[$s]:-}" ]]; then
        icon="${glyph_bell:-$(nerd_font_icon bell)}"
        reversed="#[fg=green] $icon$s #[default]${reversed:+#[fg=brightblack,bold]┋$reversed}"
      else
        icon="${glyph_session:-$(nerd_font_icon session)}"
        reversed="#[fg=brightblack] $icon$s #[default]${reversed:+#[fg=brightblack,bold]┋$reversed}"
      fi
    done
  fi

  # Always emit the separator, even when narrow (the list itself is empty then).
  printf '#[fg=brightblack,bold]┋%s' "$reversed"
}

render() {
  local socket_path="$1" current_session="$2" pane_id="$3" width="${4:-}" part="${5:-}" client_pid="${6:-}"
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
  status_layout_size "$script_dir" "$width"
  local size="$STATUS_LAYOUT_SIZE"

  # Build reversed list of sessions before current (newest first on status right)
  local reversed=""
  if [[ "$size" != narrow ]]; then
    while read -r s; do
      [[ "$s" == "$current_session" ]] && break
      if tmux -S "$socket_path" list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
        reversed="#[fg=green] $(nerd_font_icon bell)$s #[default]${reversed:+#[fg=brightblack,bold]┋$reversed}"
      else
        reversed="#[fg=brightblack] $(nerd_font_icon session)$s #[default]${reversed:+#[fg=brightblack,bold]┋$reversed}"
      fi
    done < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')
  fi

  if [[ -z $part || $part == sessions ]]; then
    # Always emit the separator, even when narrow (the list itself is empty then).
    printf '#[fg=brightblack,bold]┋%s' "$reversed"
  fi

  [[ $part == sessions ]] && exit 0

  printf '#[fg=blue]'

  # Speech recording indicator
  "$script_dir/speech.sh"

  local pane_num pane_icon pane_label
  pane_num="$(printf '%02d' "${pane_id#%}")"
  pane_icon="$(nerd_font_icon pane)"
  pane_label="$pane_icon$pane_num"
  printf '#[fg=brightblack,bg=blue,bold]▏%s▕#[default]' "$pane_label"

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

case "${1:-}" in
  --refresh) cache_refresh "${2:?}" render "${@:3}" ;;
  *)
    if [[ "${5:-}" == sessions ]]; then
      sessions_display "${1:-}" "${2:-}" "${4:-}" "${6:-}"
    else
      # The key covers everything that changes the output: part, session, pane,
      # client width and pid. TTL is loose — quota/battery/BT move slowly.
      key="right.${2:-}.${3:-}.${4:-}.${5:-}.${6:-}.${DOTFILES_NERD_FONT:-auto}"
      key="${key//[^a-zA-Z0-9]/_}"
      cache_display "$CACHE_DIR/$key.out" 60 "$0" --refresh "$CACHE_DIR/$key.out" "$@"
    fi
    ;;
esac
