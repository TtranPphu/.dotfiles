#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"

data=$("$UTIL") || exit 1
[[ -z "$data" ]] && exit 1

printf '󰢹 %s' "$data"
