#!/usr/bin/env bash
# Show all tmux keybindings in an interactive popup
# Triggered by Meta-? (Alt+Shift+/)

# ── ANSI color codes ─────────────────────────────────────────
BOLD=$'\033[1m'
CYAN=$'\033[36m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
MAGENTA=$'\033[35m'
YELLOW=$'\033[33m'
GRAY=$'\033[90m'
BRIGHT=$'\033[97m'
RESET=$'\033[0m'

MODE_PREFIX="󰨙 PREFIX"
MODE_COPY=" COPY"
MODE_TREE="󱏒 TREE"

# ── Description map ──────────────────────────────────────────
declare -A DESC

DESC["prefix:e"]="Enter copy mode"
DESC["prefix:["]="Enter copy mode"
DESC["copy-mode-vi:v"]="Begin selection"
DESC["copy-mode-vi:y"]="Copy selection and cancel"
DESC["copy-mode-vi:PageUp"]="Scroll half page up"
DESC["copy-mode-vi:PageDown"]="Scroll half page down"
DESC["copy-mode-vi:Home"]="First non-space character"
DESC["copy-mode-vi:End"]="Last non-space character"

DESC["prefix:x"]="Kill pane"
DESC["prefix:z"]="Toggle pane zoom"
DESC["prefix:q"]="Reload tmux config"
DESC["prefix:0"]="Select window 0"
DESC["prefix:1"]="Select window 1"
DESC["prefix:2"]="Select window 2"
DESC["prefix:3"]="Select window 3"
DESC["prefix:4"]="Select window 4"
DESC["prefix:5"]="Select window 5"
DESC["prefix:6"]="Select window 6"
DESC["prefix:7"]="Select window 7"
DESC["prefix:8"]="Select window 8"
DESC["prefix:9"]="Select window 9"
DESC["prefix:!"]="Break pane to new window"
DESC['prefix:""']="Split window vertically"
DESC["prefix:%"]="Split window horizontally"
DESC["prefix:&"]="Kill window (confirm)"
DESC["prefix:;"]="Go to last pane"
DESC["prefix:M-n"]="Next window (with alert)"
DESC["prefix:M-p"]="Previous window (with alert)"
DESC["prefix:M-1"]="Layout: even horizontal"
DESC["prefix:M-2"]="Layout: even vertical"
DESC["prefix:M-3"]="Layout: main horizontal"
DESC["prefix:M-4"]="Layout: main vertical"
DESC["prefix:M-5"]="Layout: tiled"
DESC["prefix:M-o"]="Rotate window (reverse)"
DESC["prefix:{"]="Swap pane up/left"
DESC["prefix:}"]="Swap pane down/right"
DESC["prefix:]"]="Paste buffer"
DESC["prefix:="]="Choose buffer"
DESC["prefix:-"]="Delete buffer"
DESC["prefix:?"]="Raw key list"
DESC["prefix:~"]="Show messages"
DESC["prefix:t"]="Clock mode"
DESC["prefix:i"]="Show window info"
DESC["prefix:o"]="Select next pane"
DESC["prefix:m"]="Mark pane"
DESC["prefix:M"]="Clear pane mark"
DESC["prefix:PPage"]="Scroll up in copy mode"

DESC["prefix:c"]="Create new window"
DESC["prefix:r"]="Rename window"
DESC["prefix:k"]="Kill window"
DESC["prefix:,"]="Rename window"
DESC["prefix:l"]="Last window"
DESC["prefix:w"]="Select window (tree)"
DESC["prefix:f"]="Find window"

DESC["prefix:C"]="Create new session"
DESC["prefix:R"]="Rename session"
DESC["prefix:K"]="Kill session"
DESC["prefix:L"]="Last session"
DESC["prefix:d"]="Detach client"
DESC["prefix:s"]="Select session (tree)"
DESC["prefix:("]="Previous session"
DESC["prefix:)"]="Next session"
DESC["prefix:D"]="Open lazydocker"
DESC["prefix:E"]="Open nvim"
DESC["prefix:G"]="Open lazygit"
DESC["prefix:T"]="Open btop"
DESC["prefix:U"]="Open gdu"
DESC["prefix:S"]="Auto-split apps"
DESC["prefix:F"]="Open yazi (auto-split)"
DESC["prefix:\`"]="Open shell popup"

DESC["root:M-C-h"]="Navigate to left pane"
DESC["root:M-C-j"]="Navigate to pane below"
DESC["root:M-C-k"]="Navigate to pane above"
DESC["root:M-C-l"]="Navigate to right pane"
DESC["root:M-C-a"]="Navigate to left pane"
DESC["root:M-C-s"]="Navigate to pane below"
DESC["root:M-C-w"]="Navigate to pane above"
DESC["root:M-C-d"]="Navigate to right pane"

DESC["root:M-S-C-h"]="Resize pane left 5"
DESC["root:M-S-C-j"]="Resize pane down 5"
DESC["root:M-S-C-k"]="Resize pane up 5"
DESC["root:M-S-C-l"]="Resize pane right 5"
DESC["root:M-S-C-a"]="Resize pane left 5"
DESC["root:M-S-C-s"]="Resize pane down 5"
DESC["root:M-S-C-w"]="Resize pane up 5"
DESC["root:M-S-C-d"]="Resize pane right 5"

DESC["root:M-1"]="Go to window 1"
DESC["root:M-2"]="Go to window 2"
DESC["root:M-3"]="Go to window 3"
DESC["root:M-4"]="Go to window 4"
DESC["root:M-5"]="Go to window 5"
DESC["root:M-6"]="Go to window 6"
DESC["root:M-7"]="Go to window 7"
DESC["root:M-8"]="Go to window 8"
DESC["root:M-9"]="Go to window 9"
DESC["root:M-h"]="Previous window"
DESC["root:M-l"]="Next window"
DESC["root:M-a"]="Previous window"
DESC["root:M-d"]="Next window"

DESC["root:M-H"]="Swap window left"
DESC["root:M-L"]="Swap window right"
DESC["root:M-A"]="Swap window left"
DESC["root:M-D"]="Swap window right"

DESC["root:M-j"]="Next session"
DESC["root:M-k"]="Previous session"
DESC["root:M-s"]="Switch session (fzf)"
DESC["root:M-w"]="Switch window (fzf)"
DESC["root:M-m"]="Move pane to session (fzf)"

DESC["root:M-?"]="Show this keymap"

# ── Key formatting ───────────────────────────────────────────

format_key() {
  local raw="$1"
  local key="${raw#prefix }"
  local base="$key"
  local mods=""

  while true; do
    case "$base" in
      C-*)  mods="${mods}Ctrl+"; base="${base#C-}" ;;
      M-*)  mods="${mods}Meta+"; base="${base#M-}" ;;
      S-*)  mods="${mods}Shift+"; base="${base#S-}" ;;
      *)    break ;;
    esac
  done

  [[ "$raw" != "${raw#prefix }" ]] && echo -n "Prefix+"

  echo "${mods}${base}"
}

# ── Description generation ───────────────────────────────────

describe_command() {
  local line="$1"
  local cmd
  cmd=$(echo "$line" | awk '{
    c = $5
    if (c == "command-prompt") {
      print "Prompt for command"
    } else if (c == "confirm-before") {
      print "Confirm then run"
    } else if (c == "display-popup") {
      print "Open popup"
    } else if (c == "display-menu") {
      print "Show menu"
    } else if (c == "run-shell") {
      print "Run external command"
    } else if (c == "if-shell") {
      print "Conditional action"
    } else if (c == "display-message") {
      print "Show hint"
    } else {
      gsub(/-/, " ", c)
      for (i = 1; i <= length(c); i++) {
        if (i == 1 || substr(c, i-1, 1) == " ") {
          c = substr(c, 1, i-1) toupper(substr(c, i, 1)) substr(c, i+1)
        }
      }
      print c
    }
  }')
  echo "$cmd"
}

# ── Output helpers ───────────────────────────────────────────

list_keys() {
  tmux list-keys -T "$1" 2>/dev/null
}

print_section_header() {
  local label="$1"
  local width=72
  local pad=$(((width - ${#label} - 2) / 2))
  printf '\n  %s\n' "${GRAY}$(printf '═%.0s' $(seq 1 "$width"))${RESET}"
  printf "  ${GRAY}%*s${RESET} ${CYAN}${BOLD}%s${RESET} ${GRAY}%*s${RESET}\n" "$pad" '' "$label" "$pad" ''
  printf '  %s\n' "${GRAY}$(printf '═%.0s' $(seq 1 "$width"))${RESET}"
}

print_mode_entry() {
  local key="$1"
  local mode_label="$2"
  local mode_color="$3"
  local target_label="$4"
  local target_color="$5"
  local pad=$((10 - ${#mode_label}))
  [[ $pad -gt 0 ]] && printf -v mode_label "%s%*s" "$mode_label" "$pad" ""
  printf "  ${mode_color}${BOLD}%s${RESET}  ${BRIGHT}${BOLD}%-20s${RESET}  ${target_color}${BOLD}%s${RESET}\n" "$mode_label" "$key" "$target_label"
}

format_group() {
  local category="$1"
  local table="$2"
  local label="$3"
  local label_color="$4"
  shift 4
  local filters=("$@")

  local all_lines
  all_lines=$(list_keys "$table")

  local group_lines=""
  for filter in "${filters[@]}"; do
    while IFS= read -r line; do
      [[ -n "$line" ]] && group_lines+="$line"$'\n'
    done < <(echo "$all_lines" | awk "$filter")
  done

  [[ -z "$group_lines" ]] && return

  group_lines=$(echo "$group_lines" | sort -k4)

  print_section_header "$category"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local key desc formatted
    key=$(echo "$line" | awk '{print $4}')

    local map_key="${table}:${key}"
    if [[ -n "${DESC[$map_key]}" ]]; then
      desc="${DESC[$map_key]}"
    else
      desc=$(describe_command "$line")
    fi

    formatted=$(format_key "$key")
    if [[ -n "$label" ]]; then
      local pad=$((10 - ${#label}))
      [[ $pad -gt 0 ]] && printf -v label "%s%*s" "$label" "$pad" ""
      printf "  ${label_color}${BOLD}%s${RESET}  ${BRIGHT}${BOLD}%-20s${RESET}  %s\n" "$label" "$formatted" "$desc"
    else
      printf "  ${BRIGHT}${BOLD}%-28s${RESET} %s\n" "$formatted" "$desc"
    fi
  done <<< "$group_lines"
}

# ── Copy mode (no section sub-headers) ───────────────────────

parse_copy_mode() {
  local raw
  raw=$(list_keys copy-mode-vi)
  [[ -z "$raw" ]] && return

  print_section_header "COPY MODE"
  print_mode_entry "e or [" "$MODE_PREFIX" "$MAGENTA" "$MODE_COPY" "$CYAN"

  echo "$raw" | sort -k4 | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local key desc formatted
    key=$(echo "$line" | awk '{print $4}')

    local map_key="copy-mode-vi:${key}"
    if [[ -n "${DESC[$map_key]}" ]]; then
      desc="${DESC[$map_key]}"
    else
      desc=$(describe_command "$line")
    fi

    formatted=$(format_key "$key")
    local p_copy="$MODE_COPY"
    local pad=$((10 - ${#p_copy}))
    [[ $pad -gt 0 ]] && printf -v p_copy "%s%*s" "$p_copy" "$pad" ""
    printf "  ${CYAN}${BOLD}%s${RESET}  ${BRIGHT}${BOLD}%-20s${RESET}  %s\n" "$p_copy" "$formatted" "$desc"
  done
}

# ── Tree mode (built-in, no key table exposed) ──────────────

parse_tree_mode() {
  print_section_header "TREE MODE"
  print_mode_entry "s or w" "$MODE_PREFIX" "$MAGENTA" "$MODE_TREE" "$CYAN"

  local keys=(
    "Enter:Choose selected item"
    "Up:Select previous item"
    "Down:Select next item"
    "Shift+Up:Swap window with previous"
    "Shift+Down:Swap window with next"
    "Right:Expand item"
    "Left:Collapse item"
    "plus:Expand item"
    "minus:Collapse item"
    "Meta++:Expand all items"
    "Meta+-:Collapse all items"
    "x:Kill selected item"
    "X:Kill tagged items"
    "lt:Scroll preview left"
    "gt:Scroll preview right"
    "Ctrl+s:Search by name"
    "n:Repeat last search forward"
    "N:Repeat last search backward"
    "t:Toggle tag on item"
    "T:Tag no items"
    "Ctrl+t:Tag all items"
    "colon:Run command for tagged items"
    "f:Enter filter format"
    "O:Change sort field"
    "r:Reverse sort order"
    "v:Toggle preview"
    "q:Exit tree mode"
    "Escape:Exit tree mode"
    "m:Set marked pane"
    "M:Clear marked pane"
    "H:Jump to starting pane"
    "?:Show help"
    "PgUp:Page up"
    "PgDn:Page down"
    "Home:Go to first item"
    "End:Go to last item"
  )

  for entry in "${keys[@]}"; do
    local key desc
    key="${entry%%:*}"
    desc="${entry#*:}"
    [[ "$key" == "colon" ]] && key=":"
    [[ "$key" == "lt" ]] && key="<"
    [[ "$key" == "gt" ]] && key=">"
    local p_tree="$MODE_TREE"
    local pad=$((10 - ${#p_tree}))
    [[ $pad -gt 0 ]] && printf -v p_tree "%s%*s" "$p_tree" "$pad" ""
    printf "  ${CYAN}${BOLD}%s${RESET}  ${BRIGHT}${BOLD}%-20s${RESET}  %s\n" "$p_tree" "$key" "$desc"
  done
}

parse_prefix_bindings() {
  printf "  ${BRIGHT}${BOLD}%-28s${RESET} ${MAGENTA}${BOLD}%s${RESET}\n" "Ctrl+Space" "$MODE_PREFIX"
  printf "  ${BRIGHT}${BOLD}%-28s${RESET} ${MAGENTA}${BOLD}%s${RESET}\n" "Ctrl+A" "$MODE_PREFIX"

  format_group "Session" "prefix" "$MODE_PREFIX" "$MAGENTA" \
    "\$5 ~ /^(new-session|rename-session|kill-session|switch-client|detach-client)\$/"

  format_group "Window" "prefix" "$MODE_PREFIX" "$MAGENTA" \
    "\$5 ~ /^(new-window|rename-window|kill-window|last-window|next-window|previous-window|select-window|choose-tree|find-window)\$/"

  format_group "Pane" "prefix" "$MODE_PREFIX" "$MAGENTA" \
    "\$5 ~ /^(split-window|break-pane|select-pane|kill-pane|resize-pane|swap-pane|last-pane|rotate-window|choose-buffer|choose-client|clock-mode|copy-mode|paste-buffer|list-buffers|send-prefix|suspend-client|select-layout|confirm-before|source-file)\$/"

  format_group "Apps & Popups" "prefix" "$MODE_PREFIX" "$MAGENTA" \
    "\$5 ~ /^(display-popup|run-shell)( |\$)/"

  format_group "Other" "prefix" "$MODE_PREFIX" "$MAGENTA" \
    "\$5 !~ /^(new-session|rename-session|kill-session|switch-client|detach-client|new-window|rename-window|kill-window|last-window|next-window|previous-window|select-window|choose-tree|find-window|split-window|break-pane|select-pane|kill-pane|resize-pane|swap-pane|last-pane|rotate-window|choose-buffer|choose-client|clock-mode|copy-mode|paste-buffer|list-buffers|send-prefix|suspend-client|select-layout|confirm-before|source-file|display-popup|run-shell)( |\$)/"
}

parse_root_bindings() {
  format_group "Pane Navigation" "root" "" "" \
    "\$4 ~ /^M-C-/ && \$4 !~ /S-/"

  format_group "Pane Resize" "root" "" "" \
    "\$4 ~ /^M-S-C-/"

  format_group "Window" "root" "" "" \
    "\$4 ~ /^M-[1-9]\$/ || \$4 ~ /^M-[hlad]\$/"

  format_group "Window Swap" "root" "" "" \
    "\$4 ~ /^M-[HLAD]\$/"

  format_group "Session" "root" "" "" \
    "\$4 ~ /^M-[jkmsw]\$/"

  format_group "Mouse" "root" "" "" \
    "\$4 ~ /Mouse/"

  format_group "Other" "root" "" "" \
    "\$4 !~ /^M-C-/ && \$4 !~ /^M-S-C-/ && \$4 !~ /^M-[1-9hladHLADjkmsw]\$/ && \$4 !~ /Mouse/"
}

# ── Flag parsing ─────────────────────────────────────────────

DEBUG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--debug) DEBUG=1; shift ;;
    *) shift ;;
  esac
done

# ── Pager selection ──────────────────────────────────────────

if command -v bat &>/dev/null; then
  PAGER="bat --style=plain --paging=never"
else
  PAGER="less -FXR"
fi

# ── Main ─────────────────────────────────────────────────────

tmpf=$(mktemp /tmp/tmux-keymap-XXXXXX)
trap 'rm -f "$tmpf"' EXIT

parse_prefix_bindings >> "$tmpf"
echo >> "$tmpf"
parse_root_bindings >> "$tmpf"

if tmux list-keys -T copy-mode-vi &>/dev/null; then
  echo >> "$tmpf"
  parse_copy_mode >> "$tmpf"
fi

echo >> "$tmpf"
parse_tree_mode >> "$tmpf"

if [[ "$DEBUG" -eq 1 ]]; then
  cat "$tmpf"
else
  tmux display-popup -E -w 80% -h 80% "$PAGER '$tmpf'"
fi
