#!/usr/bin/env bash
# Output LLM route icon, or OS icon when called with 'os' arg and no route.
set -euo pipefail

rf=/tmp/llm-route
valid=false

if [[ -f $rf ]]; then
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || true
  [[ -n $mtime ]] && ((now - mtime < 300)) && valid=true
fi

if [[ $valid == true ]]; then
  if [[ ${1:-} == os ]]; then
    exit 1
  fi
  route=$(<"$rf")
  case $route in
    claude-pro)      echo " " ;;
    claude-flash)    echo " " ;;
    aichat-reasoner) echo " " ;;
    aichat-chat)     echo " " ;;
  esac
elif [[ ${1:-} == os ]]; then
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
fi
