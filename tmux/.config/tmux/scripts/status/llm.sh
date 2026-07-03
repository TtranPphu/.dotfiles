#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/llm-util.sh"

data=$("$UTIL") || exit 1
type="${data%% *}"
value="${data#* }"

if [[ $type == route ]]; then
  case "$value" in
    claude-pro)      color="red" ;;
    claude-flash)    color="purple" ;;
    aichat-reasoner) color="blue" ;;
    aichat-chat)     color="cyan" ;;
    aichat-qwen)     color="white" ;;
    opencode-free)   color="green" ;;
    *)               color="colour239" ;;
  esac
  printf '#[fg=colour233,bold,bg=%s]  ▐#[default]' "$color"
else
  case "$value" in
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
fi
