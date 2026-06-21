#!/usr/bin/bash

bat_path=$(upower -e 2>/dev/null | grep -i bat | head -1)
[ -z "$bat_path" ] && exit 1

read -r bat raw_status < <(
  upower -i "$bat_path" 2>/dev/null | awk '
    /percentage:/ { gsub(/%/,""); cap = sprintf("%.0f", $2) }
    /state:/      { st = $2 }
    END           { print cap, st }
  '
)

[ -z "$bat" ] && exit 1

charging=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
discharging=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

idx=$(( (bat - 1) / 10 ))

if [ "$raw_status" = "fully-charged" ]; then
  icon="󰂄"
elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
  icon="${charging[$idx]}"
else
  icon="${discharging[$idx]}"
fi

printf '%s %s\n' "$icon" "$bat"
