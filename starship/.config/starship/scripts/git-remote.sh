#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"

remote=$(git remote get-url origin 2>/dev/null) || exit 1

case "$remote" in
  *github*)    echo "$(nerd_font_icon remote.github)" ;;
  *gitlab*)    echo "$(nerd_font_icon remote.gitlab)" ;;
  *bitbucket*) echo "$(nerd_font_icon remote.bitbucket)" ;;
  *)           echo "$(nerd_font_icon remote.git)" ;;
esac
