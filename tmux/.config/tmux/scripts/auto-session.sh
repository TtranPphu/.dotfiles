#!/usr/bin/env bash
set -euo pipefail

pane_id="${1:-}"
cwd="${2:-}"
current_session="${3:-}"

if [[ -z "$cwd" ]]; then
    cwd=$(tmux display-message -p '#{pane_current_path}')
    pane_id=$(tmux display-message -p '#{pane_id}')
    current_session=$(tmux display-message -p '#{session_name}')
fi

target_session=$(basename "$cwd")
target_session="${target_session#.}"
target_session="${target_session//[^a-zA-Z0-9_-]/-}"
[[ -z "$target_session" ]] && target_session="shell"

[[ "$current_session" == "$target_session" ]] && exit 0

# Ensure target session exists
session_created=false
if ! tmux has-session -t "$target_session" 2>/dev/null; then
    tmux new-session -d -s "$target_session" -c "$cwd"
    session_created=true
fi

# Create a new window in target and move the current pane there
new_win=$(tmux new-window -P -F '#{window_index}' -t "$target_session" -c "$cwd")
tmux join-pane -s "$pane_id" -t "${target_session}:${new_win}"
tmux kill-pane -t "${target_session}:${new_win}.1"

# If we created the session, clean up its default window
if [[ "$session_created" == "true" ]]; then
    tmux kill-window -t "${target_session}:1"
fi

tmux switch-client -t "$target_session"

# Clean up source session if now empty
if ! tmux has-session -t "$current_session" 2>/dev/null; then
    :  # session already gone from pane move
elif tmux list-windows -t "$current_session" 2>/dev/null; then
    :  # session still has windows, keep it
else
    tmux kill-session -t "$current_session"
fi

# Exit copy mode if pane happened to enter it during the move
tmux send -X cancel 2>/dev/null || true
