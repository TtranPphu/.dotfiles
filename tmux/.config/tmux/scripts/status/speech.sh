#!/usr/bin/env bash
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/tmux-speech.pid"
TRANSFILE="$RUNTIME_DIR/tmux-speech-transcribing"

if [ -f "$TRANSFILE" ]; then
    printf '#[fg=brightblack,bold,bg=yellow] 󰔮 ▐#[default]'
elif [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    printf '#[fg=brightblack,bold,bg=red] 󰦚 ▐#[default]'
fi
