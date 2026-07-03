#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"

host_name=$("$UTIL") || exit 1
[[ -z "$host_name" ]] && exit 1

# Strip domain for display
if [[ "$host_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$host_name" == *:* ]]; then
  display_host="$host_name"
else
  display_host="${host_name%%.*}"
fi

# Color hash the full hostname for stable color
h=0
for ((i=0; i<${#host_name}; i++)); do
  printf -v c '%d' "'${host_name:$i:1}"
  ((h = (h * 31 + c) % 2147483647))
done
bg=$((16 + (h % 216)))
if (( (bg - 16) / 36 < 2 )); then
  printf '#[fg=colour231,bg=colour%d] %s #[default]' "$bg" "$display_host"
else
  printf '#[fg=colour232,bg=colour%d] %s #[default]' "$bg" "$display_host"
fi
