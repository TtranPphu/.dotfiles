#!/usr/bin/env bash
# One git prompt segment: remote host icon, branch, status counts.
# Consolidates the built-in git_branch/git_status modules and custom.git_remote
# into a single custom module so the segment renders in one pass.
#
# Live with timeout: git-util.sh fetches on every render, bounded by
# FETCH_LIVE_TIMEOUT; on a timeout or failed fetch it prints the last known
# good value and exits 3, and the segment is then dimmed with the stale marker
# (fetch-cache.sh documents the exit codes).
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."

render() {
  source "$script_dir/icon.sh"
  source "$script_dir/color.sh"
  local data rc=0
  local line remote branch
  local conflicted stashed deleted renamed modified staged untracked ahead behind
  local icon_remote out status icon_stale stale_text
  local fg_muted fg_white fg_green fg_yellow
  local style reset

  data=$("$script_dir/git-util.sh") || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; then
    exit 1
  fi

  while IFS= read -r line; do
    case "$line" in
      remote=*) remote=${line#remote=} ;;
      branch=*) branch=${line#branch=} ;;
      counts=*) read -r conflicted stashed deleted renamed modified staged untracked <<<"${line#counts=}" ;;
      ab=*) read -r ahead behind <<<"${line#ab=}" ;;
    esac
  done <<<"$data"

  fg_muted=$(color_ansi muted)
  fg_white=$(color_ansi white)
  fg_green=$(color_ansi green)
  fg_yellow=$(color_ansi brightyellow)
  reset=$'\033[0m'

  # Remote host icon, bold white (was custom.git_remote). The icon catalog pads
  # some cells with trailing spaces, which starship's output trim used to drop.
  # With an icon it is followed by the separator space; with no remote (or no
  # glyph) nothing is emitted before the branch, so the path module's trailing
  # format space stays the only separator and the two cannot double up.
  icon_remote=
  case "$remote" in
    '') ;;
    *github*)    icon_remote=$(nerd_font_icon remote.github) ;;
    *gitlab*)    icon_remote=$(nerd_font_icon remote.gitlab) ;;
    *bitbucket*) icon_remote=$(nerd_font_icon remote.bitbucket) ;;
    *)           icon_remote=$(nerd_font_icon remote.git) ;;
  esac
  icon_remote=${icon_remote#"${icon_remote%%[![:space:]]*}"}
  icon_remote=${icon_remote%"${icon_remote##*[![:space:]]}"}

  # Status counts, bright yellow (was git_status), in the old $all_status order:
  # conflicted, stashed, deleted, renamed, modified, staged, untracked.
  status=
  add_status() {
    if [ "$2" -gt 0 ]; then
      status+="$1$2 "
    fi
  }
  add_status '~' "$conflicted"
  add_status '≡' "$stashed"
  add_status '✗' "$deleted"
  add_status '→' "$renamed"
  add_status '!' "$modified"
  add_status '✓' "$staged"
  add_status '?' "$untracked"
  if [ -n "$ahead" ] && [ -n "$behind" ]; then
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
      status+="↑$ahead ↓$behind "
    elif [ "$ahead" -gt 0 ]; then
      status+="↑$ahead "
    elif [ "$behind" -gt 0 ]; then
      status+="↓$behind "
    fi
  fi

  # Stale: the last known good value, dimmed (bright black), stale marker last.
  if [ "$rc" -eq 3 ]; then
    if [ -n "$icon_remote" ]; then
      stale_text="$icon_remote $branch"
    else
      stale_text="$branch"
    fi
    [ -n "$status" ] && stale_text+=" ${status% }"
    icon_stale=$(nerd_font_icon stale)
    icon_stale=${icon_stale% }
    [ -n "$icon_stale" ] && stale_text+=" $icon_stale"
    printf '%s%s%s' "$fg_muted" "$stale_text" "$reset"
    return 0
  fi

  if [ -n "$icon_remote" ]; then
    style=$'\033[1m'"$fg_white"
    out=$(printf '%s%s%s ' "$style" "$icon_remote" "$reset")
  else
    # No icon: no leading space either — the path module's format already ends
    # with one, and starship trims a leading space in the output anyway. The
    # zero-width reset keeps the segment starting on a clean SGR state.
    out="$reset"
  fi

  # Branch, green (was git_branch); detached HEAD falls back to "HEAD".
  out+=$(printf '%s%s%s' "$fg_green" "$branch" "$reset")

  if [ -n "$status" ]; then
    # The old symbol formats each end with a space; the segment's final space
    # comes from the module format instead.
    out+=$(printf ' %s%s' "$fg_yellow" "${status% }")
  fi

  printf '%s' "$out"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    # A cached value means this directory rendered git info before (the fetch
    # is repo-gated), so the module shows without probing git at all. Only an
    # empty entry needs the repo check that decides whether to keep probing.
    "$script_dir/git-util.sh" --has-value && exit 0
    [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || exit 1
    # No cached value yet: fetch now, so a failed fetch leaves the module
    # hidden instead of rendering the format's literal space (exit 3 = the
    # stale fallback still has a value to show).
    "$script_dir/git-util.sh" >/dev/null 2>&1
    case "$?" in
      0 | 3) exit 0 ;;
      *) exit 1 ;;
    esac
    ;;
  *) exit 2 ;;
esac
