#!/bin/bash

PANE_PATH=$(tmux display-message -p '#{pane_current_path}')
PANE_WIDTH=$(tmux display-message -p '#{pane_width}')
PANE_HEIGHT=$(tmux display-message -p '#{pane_height}')

known_shells=' zsh bash sh nu fish dash ksh tcsh '
current=$(tmux display-message -p '#{pane_current_command}')
shell="$current"
if [[ "$known_shells" != *" $current "* ]]; then
  shell=$(tmux display-message -p '#{pane_start_command}')
fi

if [ "$PANE_WIDTH" -gt $((PANE_HEIGHT * 2)) ]; then
  PANE=$(tmux split-window -h -c "$PANE_PATH" -P -F '#{pane_id}' ${shell:+"$shell"})
else
  PANE=$(tmux split-window -v -c "$PANE_PATH" -P -F '#{pane_id}' ${shell:+"$shell"})
fi

if [ $# -gt 0 ]; then
  tmux send-keys -t "$PANE" "exec $*" Enter
fi
