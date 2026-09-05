#!/usr/bin/env bash

tty="${1:-}"
default_app="${2:-}"

app_name_rules=(
  'claude:claude'
  'opencode:opencode'
  'dsh:deepseek'
)

matched_app=""
matched_branch=""
sudo_real_app=""

while IFS=' ' read -r pid rest; do
  cmd="${rest%% *}"
  cmd="${cmd##*/}"
  if [[ "$cmd" == "sudo" ]]; then
    cmd="${rest#sudo }"
    cmd="${cmd%% *}"
    cmd="${cmd##*/}"
    sudo_real_app="$cmd"
  fi
  for rule in "${app_name_rules[@]}"; do
    pattern="${rule%%:*}"
    name="${rule#*:}"

    if [[ "$cmd" == "$pattern" || " $rest " == *" $pattern "* ]]; then
      branch="$(git -C "/proc/$pid/cwd" branch --show-current 2>/dev/null)"
      if [[ "$default_app" == "$pattern" ]]; then
        if [[ -n "$branch" ]]; then
          printf '%s' "${name} 󰊢 ${branch}"
        else
          printf '%s' "$name"
        fi
        exit 0
      fi
      [[ -z "$matched_app" ]] && matched_app="$name" && matched_branch="$branch"
      break
    fi
  done
done < <(ps -t "$tty" -o pid= -o args= 2>/dev/null)

# Use fallback if we found a background process match
if [[ -n "$matched_app" ]]; then
  if [[ -n "$matched_branch" ]]; then
    printf '%s' "${matched_app} 󰊢 ${matched_branch}"
  else
    printf '%s' "$matched_app"
  fi
  exit 0
fi

printf '%s' "${sudo_real_app:-$default_app}"
