#!/usr/bin/env bash

set -euo pipefail

action="$1"

log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/pane-logs"
mkdir -p "$log_dir"

log_file_for() {
  printf '%s/%s.log' "$log_dir" "${1#%}"
}

attach_pipe() {
  socket_path="$1"
  pane_id="$2"
  touch "$(log_file_for "$pane_id")"
  tmux -S "$socket_path" pipe-pane -t "$pane_id" "~/.config/tmux/scripts/pane-log.sh write $pane_id"
}

case "$action" in
  write)
    pane_id="$2"
    log_file="$(log_file_for "$pane_id")"
    cat >>"$log_file"
    ;;
  attach)
    socket_path="$2"
    pane_id="$3"
    attach_pipe "$socket_path" "$pane_id"
    ;;
  init)
    socket_path="$2"
    tmux -S "$socket_path" list-panes -a -F '#{pane_id}' |
      while IFS= read -r pane_id; do
        attach_pipe "$socket_path" "$pane_id"
      done
    ;;
  cleanup)
    pane_id="$2"
    rm -f "$(log_file_for "$pane_id")"
    ;;
  *)
    printf 'usage: %s {write|attach|init|cleanup} ...\n' "$0" >&2
    exit 2
    ;;
esac
