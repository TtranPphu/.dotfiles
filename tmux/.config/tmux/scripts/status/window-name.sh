#!/usr/bin/env bash

tty="${1:-}"
default_app="${2:-}"

app_name_rules=(
  'claude:claude'
  'copilot:copilot'
  'opencode:opencode'
)

while IFS=' ' read -r pid rest; do
  for rule in "${app_name_rules[@]}"; do
    pattern="${rule%%:*}"
    name="${rule#*:}"

    if [[ "$rest" == *"$pattern"* ]]; then
      branch="$(git -C "/proc/$pid/cwd" branch --show-current 2>/dev/null)"
      if [[ -n "$branch" ]]; then
        printf '%s' "${name} 󰊢 ${branch}"
      else
        printf '%s' "$name"
      fi
      exit 0
    fi
  done
done < <(ps -t "$tty" -o pid= -o args= 2>/dev/null)

printf '%s' "$default_app"
