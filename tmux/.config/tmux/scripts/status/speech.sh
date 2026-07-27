#!/usr/bin/env bash
PIDFILE="/tmp/tmux-speech.pid"
TRANSFILE="/tmp/tmux-speech-transcribing"

if [ -f "$TRANSFILE" ]; then
    printf '#[fg=brightblack,bold,bg=yellow] 󰔮 ▐#[default]'
elif [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    printf '#[fg=brightblack,bold,bg=red] 󰦚 ▐#[default]'
fi
