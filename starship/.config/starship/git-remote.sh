#!/usr/bin/env bash
set -euo pipefail

remote=$(git remote get-url origin 2>/dev/null) || exit 1

case "$remote" in
  *github*)    echo "" ;;
  *gitlab*)    echo "" ;;
  *bitbucket*) echo "" ;;
  *)           echo "󰊢" ;;
esac
