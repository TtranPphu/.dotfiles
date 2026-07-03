#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/llm-util.sh"

usage() { exit 1; }
[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
type="${data%% *}"
value="${data#* }"

os_icon() {
  case "${1:-linux}" in
    alpine)       echo " " ;;
    amzn)         echo " " ;;
    android)      echo " " ;;
    arch|artix)   echo "󰣇 " ;;
    centos)       echo " " ;;
    darwin)       echo "󰀵 " ;;
    debian)       echo "󰣚 " ;;
    fedora)       echo "󰣛 " ;;
    gentoo)       echo "󰣨 " ;;
    manjaro)      echo " " ;;
    mint)         echo "󰣭 " ;;
    nixos)        echo " " ;;
    opensuse*)    echo " " ;;
    raspbian)     echo "󰐿 " ;;
    rhel|redhat)  echo "󱄛 " ;;
    rocky)        echo " " ;;
    sles)         echo " " ;;
    ubuntu)       echo " " ;;
    *)            echo "󰌽 " ;;
  esac
}

case "${1:-}" in
  --display)
    [[ $# -lt 2 ]] && usage
    if [[ "$2" == os ]]; then
      [[ $type == os ]] || exit 1
      os_icon "$value"
    else
      [[ $type == route ]] || exit 1
      echo " "
    fi
    ;;
  --guard)
    [[ $# -lt 2 ]] && usage
    if [[ "$2" == os ]]; then
      [[ $type == os ]] && exit 0
      exit 1
    fi
    case "$2" in
      pro)      cached="claude-pro" ;;
      flash)    cached="claude-flash" ;;
      reasoner) cached="aichat-reasoner" ;;
      chat)     cached="aichat-chat" ;;
      qwen)     cached="aichat-qwen" ;;
      free)     cached="opencode-free" ;;
      *)        exit 1 ;;
    esac
    [[ $type == route && $value == "$cached" ]]
    ;;
  *) usage ;;
esac
