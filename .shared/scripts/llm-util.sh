#!/usr/bin/env bash
set -euo pipefail

rf=/tmp/llm-route

if [[ -f $rf ]]; then
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || mtime=0
  if ((now - mtime < 300)); then
    read -r route <"$rf"
    printf 'route %s' "$route"
    exit 0
  fi
fi

if [[ -f /etc/os-release ]]; then
  id=$(. /etc/os-release && echo "${ID:-linux}")
else
  id=linux
fi
printf 'os %s' "$id"
