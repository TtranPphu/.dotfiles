#!/bin/bash
# Adjust volume of the actively running audio sink, or fall back to default.
# Usage: volume-active-sink.sh <raise|lower|mute-toggle|(+|-)number>

action="${1:-raise}"

# Find the actively running sink (non-idle, non-suspended)
running_sink=$(pactl list sinks short | awk '$7 == "RUNNING" {print $2; exit}')

if [ -n "$running_sink" ]; then
  exec swayosd-client --device "$running_sink" --output-volume "$action"
else
  exec swayosd-client --output-volume "$action"
fi
