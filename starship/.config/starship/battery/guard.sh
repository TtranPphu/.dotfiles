#!/usr/bin/env bash

[ -n "$TMUX" ] || [ -n "$ZELLIJ" ] && exit 1

bat_path=$(upower -e 2>/dev/null | grep -i bat | head -1)
[ -z "$bat_path" ] && exit 1

bat=$(upower -i "$bat_path" 2>/dev/null | awk '/percentage:/ { gsub(/%/,""); printf "%.0f", $2 }')
[ -z "$bat" ] && exit 1

lvl="${1:?}"
idx=$(( (bat - 1) / 10 ))
[ "$idx" -eq "$lvl" ]
