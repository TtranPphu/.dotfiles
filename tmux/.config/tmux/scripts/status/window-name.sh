#!/usr/bin/env bash
# Window name for the status bar.
#
# Rendered live: the process scan costs ~15 ms, and window-status runs for
# every window on every redraw, so the name is always current — no cache lag
# when a pane's command changes. `--cached` is kept as a live alias for a
# running tmux server that still passes it (the previous status format did).

script_dir="${BASH_SOURCE[0]%/*}"
if [ "$script_dir" = "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi

app_name_rules=(
  'claude:claude'
  'opencode:opencode'
  'opencode.exe:opencode'
  'dsh:deepseek'
)

render() {
  local tty="${1:-}" default_app="${2:-}"
  local matched_app="" sudo_real_app="" rest cmd rule pattern name

  while IFS= read -r rest; do
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
        if [[ "$default_app" == "$pattern" ]]; then
          printf '%s' "$name"
          exit 0
        fi
        [[ -z "$matched_app" ]] && matched_app="$name"
        break
      fi
    done
  done < <(ps -t "$tty" -o args= 2>/dev/null)

  # Use fallback if we found a background process match
  if [[ -n "$matched_app" ]]; then
    printf '%s' "$matched_app"
    exit 0
  fi

  printf '%s' "${sudo_real_app:-$default_app}"
}

case "${1:-}" in
  --cached) shift; render "${1:-}" "${2:-}" ;;
  *) render "${1:-}" "${2:-}" ;;
esac
