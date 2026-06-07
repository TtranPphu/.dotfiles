#!/usr/bin/env bash

[ -n "$TMUX" ] || [ -n "$ZELLIJ" ] && exit 1
[ ! -d /sys/class/power_supply/BAT0 ] && [ ! -d /sys/class/power_supply/BAT1 ] && exit 1

bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
[ -z "$bat" ] && exit 1
[ "$bat" -lt 20 ]
