#!/usr/bin/env bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/tmux-speech.pid"
TRANSFILE="$RUNTIME_DIR/tmux-speech-transcribing"

if [ -f "$TRANSFILE" ]; then
    printf '#[fg=brightblack,bold,bg=yellow] %s ▐#[default]' "$(nerd_font_icon speech.transcribe)"
elif [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    printf '#[fg=brightblack,bold,bg=red] %s ▐#[default]' "$(nerd_font_icon speech.record)"
fi
