#!/bin/bash
# Background daemon: move all audio streams to the default sink when it changes.
# Prevents apps from staying pinned to a disconnected/unwanted output.

last_sink=""

# Move existing streams on any potentially relevant event
move_streams() {
  local current
  current=$(pactl get-default-sink 2>/dev/null) || return
  [[ "$current" == "$last_sink" ]] && return
  last_sink="$current"

  pactl list short sink-inputs 2>/dev/null | awk '{print $1}' | while read -r input; do
    pactl move-sink-input "$input" "$current" 2>/dev/null
  done
}

# Initial catch-up: move any orphaned streams on start
move_streams

pactl subscribe | while read -r event; do
  case "$event" in
    *sink* | *server*) move_streams ;;
  esac
done
