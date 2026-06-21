#!/usr/bin/env bash
set -euo pipefail

rf=/tmp/llm-route
route="${1:?}"

if [[ $route == os ]]; then
  [[ -f $rf ]] || true  # continue to OS detection
  if [[ -f $rf ]]; then
    now=$(date +%s)
    mtime=$(date -r "$rf" +%s 2>/dev/null) || true
    if [[ -n $mtime ]] && ((now - mtime < 300)); then
      read -r cached_route <"$rf"
      [[ $cached_route =~ ^(claude-pro|claude-flash|aichat-reasoner|aichat-chat|aichat-qwen|opencode-free)$ ]] && exit 1
    fi
  fi
  if [[ -f /etc/os-release ]]; then
    id=$(. /etc/os-release && echo "${ID:-linux}")
  else
    id=linux
  fi
  case $id in
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
  exit 0
fi

[[ -f $rf ]] || exit 1
now=$(date +%s)
mtime=$(date -r "$rf" +%s 2>/dev/null) || exit 1
((now - mtime < 300)) || exit 1

echo " "
