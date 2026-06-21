#!/usr/bin/env bash
set -euo pipefail

bat_path=$(upower -e 2>/dev/null | grep -i bat | head -1)
[[ -z "$bat_path" ]] && exit 1

read -r cap raw_status < <(
  upower -i "$bat_path" 2>/dev/null | awk '
    /percentage:/ { gsub(/%/,""); cap = sprintf("%.0f", $2) }
    /state:/      { st = $2 }
    END           { print cap, st }
  '
)

[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

idx=$(( (cap - 1) / 10 ))

charging_icons=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
discharging_icons=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

if [[ $raw_status == "fully-charged" ]]; then
  icon="󰂄"
elif [[ $raw_status == "charging" || $raw_status == "pending-charge" ]]; then
  icon="${charging_icons[$idx]}"
else
  icon="${discharging_icons[$idx]}"
fi
color="${colors[$idx]}"

printf '#[fg=colour233,bold,bg=%s] %s %s ' "$color" "$icon" "$cap"
