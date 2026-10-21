#!/usr/bin/env bash
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icon.sh"
source "$script_dir/color.sh"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNTIME_DIR/tmux-speech.pid"
TRANSFILE="$RUNTIME_DIR/tmux-speech-transcribing"

fg_muted="$(color_get muted)"
icon_transcribe="$(nerd_font_icon speech.transcribe)"
icon_record="$(nerd_font_icon speech.record)"

if [ -f "$TRANSFILE" ]; then
  bg_yellow="$(color_get yellow)"
  style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_yellow")
  reset='#[default]'
  out=" $icon_transcribe▐"
  printf '%s%s%s' "$style" "$out" "$reset"
elif [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  bg_red="$(color_get red)"
  style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_red")
  reset='#[default]'
  out=" $icon_record▐"
  printf '%s%s%s' "$style" "$out" "$reset"
fi
