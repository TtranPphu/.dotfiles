#!/usr/bin/env bash
# Raw git segment data: live fetch with timeout + last-known-good cache.
#
#   git-util.sh              -> live fetch, bounded by FETCH_LIVE_TIMEOUT
#                               (fetch-cache.sh):
#                                 exit 0: live value printed (and stored)
#                                 exit 3: live timed out/failed; the last
#                                         known good value is printed (stale)
#                                 exit 1: nothing to show (not a work tree, or
#                                         a timeout with no cached value)
#   git-util.sh --fresh      -> internal: the unbounded probe (run under the
#                               timeout by the default mode)
#   git-util.sh --has-value  -> exit 0 when a last-known-good value exists
#
# Output lines (raw values, no icons/colors):
#   remote=<url or empty>
#   branch=<branch or HEAD>
#   counts=<conflicted> <stashed> <deleted> <renamed> <modified> <staged> <untracked>
#   ab=<ahead> <behind>
set -euo pipefail

# Resolve this script through symlinks (stow links it into consumers) so the
# shared fetch-cache engine next to the real file is found.
script_dir="${BASH_SOURCE[0]:-}"
script_dir="$(readlink -f -- "$script_dir" 2>/dev/null || true)"
script_dir="${script_dir%/*}"
[ -n "$script_dir" ] || script_dir=.
[ -f "$script_dir/fetch-cache.sh" ] && source "$script_dir/fetch-cache.sh"

fetch_git() {
  [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || exit 1

  local remote branch
  remote=$(git remote get-url origin 2>/dev/null) || remote=
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch=HEAD

  local conflicted=0 stashed=0 deleted=0 renamed=0 modified=0 staged=0 untracked=0
  local ahead= behind= line xy rest
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

  printf 'remote=%s\nbranch=%s\ncounts=%s %s %s %s %s %s %s\nab=%s %s\n' \
    "$remote" "$branch" \
    "$conflicted" "$stashed" "$deleted" "$renamed" "$modified" "$staged" "$untracked" \
    "${ahead:-}" "${behind:-}"
}

case "${1:-}" in
  --fresh) fetch_git ;;
  --has-value) fetch_has_value "$(fetch_cache_path git "$(fetch_cache_cwd)")" ;;
  *) fetch_live "$(fetch_cache_path git "$(fetch_cache_cwd)")" "$0" --fresh ;;
esac
