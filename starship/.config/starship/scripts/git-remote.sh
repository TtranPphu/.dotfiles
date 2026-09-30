#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icons.sh"

remote=$(git remote get-url origin 2>/dev/null) || exit 1

case "$remote" in
  *github*)    echo "$(icon remote.github)" ;;
  *gitlab*)    echo "$(icon remote.gitlab)" ;;
  *bitbucket*) echo "$(icon remote.bitbucket)" ;;
  *)           echo "$(icon remote.git)" ;;
esac
