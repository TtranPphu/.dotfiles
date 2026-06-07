#!/usr/bin/env bash
set -euo pipefail

bat_cap="/sys/class/power_supply/BAT0/capacity"
bat_stat="/sys/class/power_supply/BAT0/status"
[[ -f $bat_cap ]] || exit 1

read -r cap <"$bat_cap"
read -r status <"$bat_stat"

idx=$((cap / 10))
(( idx > 9 )) && idx=9

charging_icons=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
discharging_icons=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

if [[ $status == "Full" ]]; then
  icon="󰂄"
elif [[ $status == "Charging" ]]; then
  icon="${charging_icons[$idx]}"
else
  icon="${discharging_icons[$idx]}"
fi

if [[ $cap -le 20 ]]; then
  printf '#[fg=brightblack,bg=red,bold]'
elif [[ $cap -le 50 ]]; then
  printf '#[fg=brightblack,bg=yellow,bold]'
else
  printf '#[fg=brightblack,bg=green,bold]'
fi

printf ' %s %s ' "$icon" "$cap"
