#!/usr/bin/env bash
# Window name for the status bar.
#
# Plain invocation renders synchronously (control scripts and session presets
# want the real name). `--cached` is the tmux status path: it only reads the
# cache (cache.sh) and refreshes in the background — window-status runs for
# every window on every redraw, so it must not wait on the ps scan.

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
  --refresh)
    source "$script_dir/cache.sh"
    cache_refresh "${2:?}" render "${3:-}" "${4:-}"
    ;;
  --cached)
    source "$script_dir/cache.sh"
    key="window-name.${2:-}.${3:-}"
    key="${key//[^a-zA-Z0-9]/_}"
    if ! cache_display "$CACHE_DIR/$key.out" 30 "$0" --refresh "$CACHE_DIR/$key.out" "${2:-}" "${3:-}"; then
      # Nothing cached yet (first pass after a pane's command changed): show
      # the mapped command name until the refresher's process scan lands.
      for rule in "${app_name_rules[@]}"; do
        pattern="${rule%%:*}"
        name="${rule#*:}"
        if [[ "${3:-}" == "$pattern" ]]; then
          printf '%s' "$name"
          exit 0
        fi
      done
      printf '%s' "${3:-}"
    fi
    ;;
  *) render "${1:-}" "${2:-}" ;;
esac
