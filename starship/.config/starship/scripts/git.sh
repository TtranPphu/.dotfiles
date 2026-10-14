#!/usr/bin/env bash
# One git prompt segment: remote host icon, branch, status counts.
# Consolidates the built-in git_branch/git_status modules and custom.git_remote
# into a single custom module so the segment renders in one pass.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"

# Remote host icon, bold white (was custom.git_remote). The icon catalog pads
# some cells with trailing spaces, which starship's output trim used to drop.
# With no remote (or no glyph) the old module still emitted its format's literal
# space, so a space is kept either way; the leading reset is zero-width and only
# stops starship's custom-output trim from eating that space.
icon=
if remote=$(git remote get-url origin 2>/dev/null); then
  case "$remote" in
    *github*)    icon=$(nerd_font_icon remote.github) ;;
    *gitlab*)    icon=$(nerd_font_icon remote.gitlab) ;;
    *bitbucket*) icon=$(nerd_font_icon remote.bitbucket) ;;
    *)           icon=$(nerd_font_icon remote.git) ;;
  esac
  icon=${icon#"${icon%%[![:space:]]*}"}
  icon=${icon%"${icon##*[![:space:]]}"}
fi
if [ -n "$icon" ]; then
  out=$(printf '\033[1;37m%s\033[0m ' "$icon")
else
  out=$(printf '\033[0m ')
fi

# Branch, green (was git_branch); detached HEAD falls back to "HEAD".
branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=HEAD
out+=$(printf '\033[32m%s\033[0m' "$branch")

# Status counts, bright yellow (was git_status), in the old $all_status order:
# conflicted, stashed, deleted, renamed, modified, staged, untracked.
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
  conflicted=0 stashed=0 deleted=0 renamed=0 modified=0 staged=0 untracked=0
  ahead= behind=
  while IFS= read -r line; do
    case "$line" in
      '# branch.ab '*)
        rest=${line#'# branch.ab '}
        ahead=${rest%% *}
        behind=${rest##* }
        ahead=${ahead#+}
        behind=${behind#-}
        ;;
      '1 '* | '2 '*)
        if [ "${line:0:1}" = 2 ]; then
          renamed=$((renamed + 1))
        fi
        xy=${line:2:2}
        case "${xy:1:1}" in
          A | M) modified=$((modified + 1)) ;;
          D) deleted=$((deleted + 1)) ;;
        esac
        case "${xy:0:1}" in
          A | M | T) staged=$((staged + 1)) ;;
          D) deleted=$((deleted + 1)) ;;
        esac
        ;;
      'u '*) conflicted=$((conflicted + 1)) ;;
      '?'*) untracked=$((untracked + 1)) ;;
    esac
  done < <(git status --porcelain=2 --branch 2>/dev/null || true)

  stashed=$(git stash list 2>/dev/null | wc -l)
  stashed=${stashed//[[:space:]]/}

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
  if [ -n "$status" ]; then
    # The old symbol formats each end with a space; the segment's final space
    # comes from the module format instead.
    out+=$(printf ' \033[93m%s' "${status% }")
  fi
fi

printf '%s' "$out"
