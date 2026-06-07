#!/usr/bin/bash

if [ ! -d /sys/class/power_supply/BAT0 ] && [ ! -d /sys/class/power_supply/BAT1 ]; then
  exit 1
fi

bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)

if [ -z "$bat" ]; then
  exit 1
fi

charging=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
discharging=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

idx=$((bat / 10))
[ "$idx" -gt 9 ] && idx=9

if [ "$status" = "Full" ]; then
  icon="󰂄"
elif [ "$status" = "Charging" ]; then
  icon="${charging[$idx]}"
else
  icon="${discharging[$idx]}"
fi

printf '%s %s\n' "$icon" "$bat"
