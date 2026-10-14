#!/usr/bin/env bash

socket_path="$1"
current_session="$2"
pane_id="$3"
width="${4:-}"
part="${5:-}"
client_pid="${6:-}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$width" ]]; then
  width=$(tmux -S "$socket_path" list-clients -t "$current_session" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
fi
export STATUS_WIDTH="$width"
size="$("$script_dir/layout.sh" size "$width")"

# Build reversed list of sessions before current (newest first on status right)
reversed=""
if [[ "$size" != narrow ]]; then
  while read -r s; do
    [[ "$s" == "$current_session" ]] && break
    if tmux -S "$socket_path" list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
      reversed='#[fg=green] 󰅸 '"$s"' #[default]'"${reversed:+#[fg=brightblack,bold]┋$reversed}"
    else
      reversed='#[fg=brightblack]  '"$s"' #[default]'"${reversed:+#[fg=brightblack,bold]┋$reversed}"
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

printf '#[fg=brightblack,bg=blue,bold]▏ %02d▕#[default]' "${pane_id#%}"

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
