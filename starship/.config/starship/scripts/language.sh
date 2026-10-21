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

# Per-language accents from the color catalog (lang.* keys): bold, dim for
# java, as in the old per-language modules (c, java, kotlin/lua, python, rust);
# unknown languages stay unstyled.
lang_color() {
  local color style
  color=$(color_ansi "lang.$1") || return 0
  case "$1" in
    java) style=$'\033[2m' ;;
    *) style=$'\033[1m' ;;
  esac
  printf '%s%s' "$style" "$color"
}

render() {
  source "$script_dir/icon.sh"
  source "$script_dir/color.sh"
  local data rc=0
  local lang version icon_lang fg_lang icon_stale seg text
  local segments=() colored=()
  local reset style

  data=$("$script_dir/language-util.sh") || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; then
    exit 1
  fi

  reset=$'\033[0m'
  while IFS=' ' read -r lang version; do
    [ -n "$lang" ] || continue
    icon_lang="$(nerd_font_icon "lang.$lang")"
    if [ -n "$version" ]; then
      seg="${icon_lang}v${version}"
    else
      seg="${icon_lang% }"
    fi
    segments+=("$seg")
    fg_lang=$(lang_color "$lang")
    if [ -n "$fg_lang" ]; then
      colored+=("$(printf '%s%s%s' "$fg_lang" "$seg" "$reset")")
    else
      colored+=("$seg")
    fi
  done <<<"$data"

  [ ${#segments[@]} -gt 0 ] || exit 1

  # Stale: the last known good value, dimmed (bright black), stale marker last.
  if [ "$rc" -eq 3 ]; then
    icon_stale=$(nerd_font_icon stale)
    icon_stale=${icon_stale% }
    text="${segments[*]}"
    style=$'\033[90m'
    if [ -n "$icon_stale" ]; then
      printf '%s%s %s%s' "$style" "$text" "$icon_stale" "$reset"
    else
      printf '%s%s%s' "$style" "$text" "$reset"
    fi
    return 0
  fi

  printf '%s' "${colored[*]}"
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
