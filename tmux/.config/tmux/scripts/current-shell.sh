#!/usr/bin/env bash
# Print the interactive shell the user is currently in, for reuse in new panes/windows.

known_shells=' zsh bash sh nu fish dash ksh tcsh '

current=$(tmux display-message -p '#{pane_current_command}' 2>/dev/null)

if [[ "$known_shells" == *" $current "* ]]; then
    echo "$current"
else
    # Not at a shell prompt — use what started the pane
    start=$(tmux display-message -p '#{pane_start_command}' 2>/dev/null)
    echo "${start:-zsh}"
fi
