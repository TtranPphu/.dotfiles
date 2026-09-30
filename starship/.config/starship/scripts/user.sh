#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  --display)
    user=$(id -un)
    if [ "$(id -u)" -eq 0 ]; then
      color=$'\033[35m' # root
    else
      color=$'\033[36m'
    fi
    printf '%s\uf007 %s\033[0m' "$color" "$user"
    ;;
  --guard)
    "$script_dir/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *)
    exit 2
    ;;
esac
