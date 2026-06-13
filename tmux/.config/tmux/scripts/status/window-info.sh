#!/usr/bin/env bash

tty="${1:-}"
default_app="${2:-}"

foreground_args="$(
  ps -t "$tty" -o stat= -o args= 2>/dev/null |
    awk '/\+/ { $1 = ""; sub(/^ /, ""); print; exit }'
)"

app_name_rules=(
  'claude:claude'
  'copilot:copilot'
)

for rule in "${app_name_rules[@]}"; do
  pattern="${rule%%:*}"
  name="${rule#*:}"

  if [[ "$foreground_args" == *"$pattern"* ]]; then
    printf '%s' "$name"
    exit 0
  fi
done

printf '%s' "$default_app"
