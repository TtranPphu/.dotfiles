#!/usr/bin/env bash
set -euo pipefail

rf=/tmp/llm-route
route="${1:?}"

# Map short names to cache route names
case "$route" in
  os)       cached=;;
  pro)      cached="claude-pro";;
  flash)    cached="claude-flash";;
  reasoner) cached="aichat-reasoner";;
  chat)     cached="aichat-chat";;
  qwen)     cached="aichat-qwen";;
  free)     cached="opencode-free";;
esac

if [[ $route == os ]]; then
  [[ -f $rf ]] || exit 0
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || exit 0
  ((now - mtime >= 300)) && exit 0
  read -r cached_route <"$rf"
  [[ $cached_route =~ ^(claude-pro|claude-flash|aichat-reasoner|aichat-chat|aichat-qwen|opencode-free)$ ]] && exit 1
  exit 0
fi

[[ -f $rf ]] || exit 1
now=$(date +%s)
mtime=$(date -r "$rf" +%s 2>/dev/null) || exit 1
((now - mtime < 300)) || exit 1
read -r cached_route <"$rf"
[[ $cached_route == "$cached" ]] || exit 1
