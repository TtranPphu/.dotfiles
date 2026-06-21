#!/usr/bin/env bash
set -euo pipefail

rf=/tmp/llm-route

if [[ -f $rf ]]; then
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || mtime=0
  if ((now - mtime < 300)); then
    read -r route <"$rf"
    case "$route" in
      claude-pro)      color="red" ;;
      claude-flash)    color="purple" ;;
      aichat-reasoner) color="blue" ;;
      aichat-chat)     color="cyan" ;;
      aichat-qwen)     color="white" ;;
      opencode-free)   color="green" ;;
      *)               color="colour239" ;;
    esac
    printf '#[fg=colour233,bold,bg=%s]  ▐#[default]' "$color"
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
  alpine)       icon="" ;;
  amzn)         icon="" ;;
  android)      icon="" ;;
  arch|artix)   icon="󰣇" ;;
  centos)       icon="" ;;
  darwin)       icon="󰀵" ;;
  debian)       icon="󰣚" ;;
  fedora)       icon="󰣛" ;;
  gentoo)       icon="󰣨" ;;
  manjaro)      icon="" ;;
  mint)         icon="󰣭" ;;
  nixos)        icon="" ;;
  opensuse*)    icon="" ;;
  raspbian)     icon="󰐿" ;;
  rhel|redhat)  icon="󱄛" ;;
  rocky)        icon="" ;;
  sles)         icon="" ;;
  ubuntu)       icon="" ;;
  *)            icon="󰌽" ;;
esac

printf '#[fg=colour233,bold,bg=brightblack] %s ▐#[default]' "$icon"
