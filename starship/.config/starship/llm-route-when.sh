#!/usr/bin/env bash
# Exit 0 when the relevant route is active.
# With 'os' arg: exit 0 when NO route is cached (show OS fallback).
set -euo pipefail

rf=/tmp/ai-route

# OS fallback mode: show when no valid route
if [[ ${1:-} == os ]]; then
  [[ -f $rf ]] || exit 0
  now=$(date +%s)
  mtime=$(date -r "$rf" +%s 2>/dev/null) || exit 0
  ((now - mtime < 300)) && exit 1 || exit 0
fi

# Route check mode: show when specific route matches
[[ -f $rf ]] || exit 1
now=$(date +%s)
mtime=$(date -r "$rf" +%s 2>/dev/null) || exit 1
((now - mtime < 300)) || exit 1
[[ $(<"$rf") == "$1" ]] || exit 1
