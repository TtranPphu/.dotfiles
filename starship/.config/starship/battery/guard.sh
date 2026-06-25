#!/usr/bin/env bash

[ -n "$TMUX" ] || [ -n "$ZELLIJ" ] && exit 1

bat=""

bat_path=$(upower -e 2>/dev/null | grep -i bat | head -1)
if [ -n "$bat_path" ]; then
  bat=$(upower -i "$bat_path" 2>/dev/null | awk '/percentage:/ { gsub(/%/,""); printf "%.0f", $2 }')
fi

if [ -z "$bat" ] && grep -qi microsoft /proc/version 2>/dev/null; then
  bat=$(powershell.exe -NoProfile -Command '
    $b = Get-WmiObject Win32_Battery
    if ($b) { Write-Host $b.EstimatedChargeRemaining }
  ' 2>/dev/null | tr -d '\r')
fi

[ -z "$bat" ] && exit 1

lvl="${1:?}"
idx=$(( (bat - 1) / 10 ))
[ "$idx" -eq "$lvl" ]
