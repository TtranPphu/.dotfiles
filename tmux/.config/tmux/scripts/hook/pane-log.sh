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
  local log_file
  log_file="$(log_file_for "$pane_id")"
  rm -f "$log_file"
  touch "$log_file"
  # tmux runs the pipe command under sh -c once per pane and keeps it alive;
  # `exec cat` makes it a single process with no per-chunk shell work.
  tmux -S "$socket_path" pipe-pane -t "$pane_id" "exec cat >> $(printf '%q' "$log_file")"
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
