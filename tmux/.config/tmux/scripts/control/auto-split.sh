#!/bin/bash

TARGET=""
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -t) TARGET="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

TARGET_FLAG=""
[ -n "$TARGET" ] && TARGET_FLAG="-t $TARGET"

PANE_PATH=$(tmux display-message -p $TARGET_FLAG '#{pane_current_path}')
PANE_WIDTH=$(tmux display-message -p $TARGET_FLAG '#{pane_width}')
PANE_HEIGHT=$(tmux display-message -p $TARGET_FLAG '#{pane_height}')

known_shells=' zsh bash sh nu fish dash ksh tcsh '
current=$(tmux display-message -p $TARGET_FLAG '#{pane_current_command}')
shell="$current"
if [[ "$known_shells" != *" $current "* ]]; then
  shell=$(tmux display-message -p $TARGET_FLAG '#{pane_start_command}')
fi

if [ "$PANE_WIDTH" -gt $((PANE_HEIGHT * 2)) ]; then
  PANE=$(tmux split-window $TARGET_FLAG -h -c "$PANE_PATH" -P -F '#{pane_id}' ${shell:+"$shell"})
else
  PANE=$(tmux split-window $TARGET_FLAG -v -c "$PANE_PATH" -P -F '#{pane_id}' ${shell:+"$shell"})
fi

if [ ${#ARGS[@]} -gt 0 ]; then
  tmux send-keys -t "$PANE" "exec ${ARGS[*]}" Enter
fi
