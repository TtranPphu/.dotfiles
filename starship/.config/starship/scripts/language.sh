#!/usr/bin/env bash
# Language versions segment: gate + live scan; language-util.sh owns the
# cwd-keyed last-known-good cache.
#
# Live with timeout: the scan runs on every render, bounded by
# FETCH_LIVE_TIMEOUT; on a timeout or failed scan the util prints the last
# known good value and exits 3, and the segment is then dimmed with the stale
# marker (fetch-cache.sh documents the exit codes).
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."

render() {
  source "$script_dir/nerd-font.sh"
  local data rc=0
  local lang version icon marker
  local segments=()

  data=$("$script_dir/language-util.sh") || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; then
    exit 1
  fi

  while IFS=' ' read -r lang version; do
    icon="$(nerd_font_icon "lang.$lang")"
    if [ -n "$version" ]; then
      segments+=("${icon}v${version}")
    else
      segments+=("${icon% }")
    fi
  done <<<"$data"

  [ ${#segments[@]} -gt 0 ] || exit 1

  # Stale: the last known good value, dimmed (bright black), stale marker last.
  if [ "$rc" -eq 3 ]; then
    marker=$(nerd_font_icon stale)
    marker=${marker% }
    if [ -n "$marker" ]; then
      printf '\033[90m%s %s\033[0m' "${segments[*]}" "$marker"
    else
      printf '\033[90m%s\033[0m' "${segments[*]}"
    fi
    return 0
  fi

  printf '%s' "${segments[*]}"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    "$script_dir/language-util.sh" --detected || exit 1
    # A cached value means the scan succeeded before; otherwise scan now, so a
    # failed scan leaves the module hidden instead of rendering the format's
    # literal space (exit 3 = the stale fallback still has a value to show).
    "$script_dir/language-util.sh" --has-value && exit 0
    "$script_dir/language-util.sh" >/dev/null 2>&1
    case "$?" in
      0 | 3) exit 0 ;;
      *) exit 1 ;;
    esac
    ;;
  *) exit 2 ;;
esac
