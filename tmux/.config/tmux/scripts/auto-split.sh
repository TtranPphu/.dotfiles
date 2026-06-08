#!/bin/bash

PANE_PATH=$(tmux display-message -p '#{pane_current_path}')

PANE_WIDTH=$(tmux display-message -p '#{pane_width}')
PANE_HEIGHT=$(tmux display-message -p '#{pane_height}')

if [ "$PANE_WIDTH" -gt $((PANE_HEIGHT * 2)) ]; then
  PANE=$(tmux split-window -h -c "$PANE_PATH" -P -F '#{pane_id}')
else
  PANE=$(tmux split-window -v -c "$PANE_PATH" -P -F '#{pane_id}')
fi

if [ $# -gt 0 ]; then
  tmux send-keys -t "$PANE" "exec $*" Enter
fi
