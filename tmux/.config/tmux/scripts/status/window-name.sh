#!/usr/bin/env bash

tty="${1:-}"
default_app="${2:-}"

app_name_rules=(
  'claude:claude'
  'copilot:copilot'
  'opencode:opencode'
  'pi:pi'
)

matched_app=""
matched_branch=""

while IFS=' ' read -r pid rest; do
  for rule in "${app_name_rules[@]}"; do
    pattern="${rule%%:*}"
    name="${rule#*:}"

    if [[ "$rest" == *"$pattern"* ]]; then
      branch="$(git -C "/proc/$pid/cwd" branch --show-current 2>/dev/null)"
      # If this process matches the active command, use it immediately
      if [[ "$default_app" == *"$pattern"* ]]; then
        if [[ -n "$branch" ]]; then
          printf '%s' "${name} 󰊢 ${branch}"
        else
          printf '%s' "$name"
        fi
        exit 0
      fi
      # Otherwise, remember the first match as fallback
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

printf '%s' "$default_app"
