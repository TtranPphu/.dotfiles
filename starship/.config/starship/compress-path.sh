#!/usr/bin/env bash
# Smart path: 2 unique-prefix heads + ... + 2 unique-prefix tails + full current
set -euo pipefail

dir=$(pwd)
home=$HOME
tilde=

# Minimum unique prefix for a name among its peers
min_prefix() {
  local name=$1 n sib prefix unique
  shift; local -a siblings=("$@")
  for ((n = 1; n <= ${#name}; n++)); do
    prefix="${name:0:n}"; unique=1
    for sib in "${siblings[@]}"; do
      if [[ $sib != "$name" && $sib == "$prefix"* ]]; then unique=0; break; fi
    done
    ((unique)) && { echo "$prefix"; return; }
  done
  echo "$name"
}

# Build parts with ~ or leading /
if [[ $dir == "$home"* ]]; then
  tilde=1
  rel="${dir#$home}"
  parts=('~')
else
  rel=$dir
  parts=()
fi

IFS='/' read -ra raw <<<"$rel"
for p in "${raw[@]}"; do
  [[ -n $p ]] && parts+=("$p")
done
total=${#parts[@]}

# Show short paths as-is
if ((total <= 5)); then
  [[ $tilde ]] && echo "~$rel" || echo "$rel"
  exit 0
fi

# Build shortened versions, using ORIGINAL parts for filesystem lookups
short=()
for ((i = 0; i < total - 1; i++)); do
  name="${parts[$i]}"
  [[ $name == '~' ]] && { short+=("$name"); continue; }

  # Build parent path from ORIGINAL names
  if [[ $tilde ]]; then
    parent_path="$home"
    for ((j = 1; j < i; j++)); do parent_path="$parent_path/${parts[$j]}"; done
  else
    parent_path='/'
    for ((j = 0; j < i; j++)); do
      [[ $parent_path == '/' ]] && parent_path="$parent_path${parts[$j]}" || parent_path="$parent_path/${parts[$j]}"
    done
  fi

  [[ $parent_path == '/' ]] && { short+=("${name:0:1}"); continue; }

  siblings=()
  while IFS= read -r entry; do
    [[ -n $entry ]] && siblings+=("$entry")
  done < <(ls -1A "$parent_path" 2>/dev/null || true)

  if ((${#siblings[@]} > 0)); then
    short+=("$(min_prefix "$name" "${siblings[@]}")")
  else
    short+=("${name:0:1}")
  fi
done

cur="${parts[-1]}"
h0="${short[0]}"
h1="${short[1]}"
t0="${short[$((total - 3))]}"
t1="${short[$((total - 2))]}"

if [[ $tilde ]]; then
  echo "$h0/$h1/…/$t0/$t1/$cur"
else
  echo "/$h0/$h1/…/$t0/$t1/$cur"
fi
