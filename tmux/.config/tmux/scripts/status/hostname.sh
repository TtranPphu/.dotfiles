#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"
QUALITY="$SCRIPT_DIR/ssh-quality-util.sh"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/layout.sh"

socket_path="${1:-}"
current_session="${2:-}"
size=$(layout_size_fast)
[[ $size == narrow ]] && exit 1

host_name=$("$UTIL") || exit 1
[[ -z "$host_name" ]] && exit 1

# Strip domain for display
if [[ "$host_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$host_name" == *:* ]]; then
  display_host="$host_name"
else
  display_host="${host_name%%.*}"
fi

# Over SSH the pill background shows the connection quality (10 = green, 1 = red);
# medium drops the name, narrow (handled above) hides the pill. Foreground matches
# the battery-family pills (fg=brightblack over the same ramp).
if level=$("$QUALITY" level "$socket_path" "$current_session" 2>/dev/null); then
  ramp=$((level * 10))
  icon=$("$QUALITY" signal "$socket_path" "$current_session" 2>/dev/null)
  if [[ $size == wide ]]; then
    printf '#[fg=brightblack,bg=%s]▏%s %s▕#[default]' "$(level_hex "$ramp")" "$icon" "$display_host"
  elif [[ "$(nerd_font_type)" == nerd ]]; then
    printf '#[fg=brightblack,bg=%s]%s%s%s#[default]' "$(level_hex "$ramp")" "$(nerd_font_icon separator.head)" "$icon" "$(nerd_font_icon separator.tail)"
  else
    printf '#[fg=brightblack,bg=%s]%s%s%s#[default]' "$(level_hex "$ramp")" "$(nerd_font_icon separator.head)" "$icon" "$(nerd_font_icon separator.tail)"
  fi
  exit 0
fi

# Local pill only in wide, neutral style like the pane-id/session pills.
[[ $size == wide ]] || exit 1
printf '#[fg=brightblack,bg=blue,bold]▏%s▕#[default]' "$display_host"
