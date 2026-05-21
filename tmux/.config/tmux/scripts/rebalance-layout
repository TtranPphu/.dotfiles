#!/bin/bash

TARGET_WINDOW=${1:-$(tmux display-message -p '#{window_id}')}

if [ -z "$TARGET_WINDOW" ]; then
  exit 0
fi

WINDOW_PANES=$(tmux display-message -p -t "$TARGET_WINDOW" '#{window_panes}')

if [ "$WINDOW_PANES" -le 1 ]; then
  exit 0
fi

UNIQUE_TOPS=$(tmux list-panes -t "$TARGET_WINDOW" -F '#{pane_top}' | sort -u | wc -l | tr -d '[:space:]')
UNIQUE_LEFTS=$(tmux list-panes -t "$TARGET_WINDOW" -F '#{pane_left}' | sort -u | wc -l | tr -d '[:space:]')

if [ "$UNIQUE_TOPS" -eq 1 ] && [ "$UNIQUE_LEFTS" -gt 1 ]; then
  tmux select-layout -t "$TARGET_WINDOW" even-horizontal
elif [ "$UNIQUE_LEFTS" -eq 1 ] && [ "$UNIQUE_TOPS" -gt 1 ]; then
  tmux select-layout -t "$TARGET_WINDOW" even-vertical
fi
