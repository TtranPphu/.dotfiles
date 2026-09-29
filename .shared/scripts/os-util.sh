#!/usr/bin/env bash
set -euo pipefail

if [[ -f /etc/os-release ]]; then
  id=$(. /etc/os-release && echo "${ID:-linux}")
else
  id=linux
fi
echo "${id:-linux}"
