#!/usr/bin/env bash
set -euo pipefail

rf=/tmp/llm-route

if [[ -f $rf ]]; then
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || mtime=0
  if ((now - mtime < 300)); then
    read -r route <"$rf"
    case "$route" in
      claude-pro)      printf '#[fg=colour233,bold,bg=red]  ▐#[default]' ;;
      claude-flash)    printf '#[fg=colour233,bold,bg=purple]  ▐#[default]' ;;
      aichat-reasoner) printf '#[fg=colour233,bold,bg=blue]  ▐#[default]' ;;
      aichat-chat)     printf '#[fg=colour233,bold,bg=cyan]  ▐#[default]' ;;
      aichat-qwen)     printf '#[fg=colour233,bold,bg=white]  ▐#[default]' ;;
      opencode-free)   printf '#[fg=colour233,bold,bg=green]  ▐#[default]' ;;
      *)               printf '#[fg=colour233,bold,bg=colour239]  ▐#[default]' ;;
    esac
    exit 0
  fi
fi

# OS fallback
if [[ -f /etc/os-release ]]; then
  id=$(. /etc/os-release && echo "${ID:-linux}")
else
  id=linux
fi
case "$id" in
  alpine)       icon=" ▐" ;;
  amzn)         icon=" ▐" ;;
  android)      icon=" ▐" ;;
  arch|artix)   icon="󰣇 ▐" ;;
  centos)       icon=" ▐" ;;
  darwin)       icon="󰀵 ▐" ;;
  debian)       icon="󰣚 ▐" ;;
  fedora)       icon="󰣛 ▐" ;;
  gentoo)       icon="󰣨 ▐" ;;
  manjaro)      icon=" ▐" ;;
  mint)         icon="󰣭 ▐" ;;
  nixos)        icon=" ▐" ;;
  opensuse*)    icon=" ▐" ;;
  raspbian)     icon="󰐿 ▐" ;;
  rhel|redhat)  icon="󱄛 ▐" ;;
  rocky)        icon=" ▐" ;;
  sles)         icon=" ▐" ;;
  ubuntu)       icon=" ▐" ;;
  *)            icon="󰌽 ▐" ;;
esac

printf '#[fg=colour233,bold,bg=colour239] %s#[default]' "$icon"
