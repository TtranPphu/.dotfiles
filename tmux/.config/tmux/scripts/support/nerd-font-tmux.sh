#!/usr/bin/env bash
# Apply the current nerd-font type to tmux @nerd_font_* options.
# Usage: nerd-font-tmux.sh [socket-path]
#
# A tmux server that is gone (restart/detach race) is a known condition: it is
# reported to the log and exits 0, since the next attach or config load applies
# the options to the new server. Every other failure is a real error: it is
# logged, printed, and exits non-zero.
set -u

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sock="${1:-}"
log="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/nerd-font-tmux.log"
glyph_value=""

tmux_cmd=(tmux)
[ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")

# Durable report channel: append a timestamped line. If the log cannot be
# written the line goes to stderr instead, so nothing is lost silently.
report() {
  mkdir -p -- "$(dirname -- "$log")" &&
    printf '%s %s\n' "$(date -Is)" "$*" >>"$log" && return 0
  printf 'nerd-font-tmux: cannot write %s: %s\n' "$log" "$*" >&2
}

# Real error: durable log + stdout (tmux shows the stdout of -b jobs, not stderr).
fail() {
  report "ERROR $*"
  printf 'nerd-font-tmux: %s\n' "$*"
  exit 1
}

# Server liveness probe, read-only, stderr captured (never discarded).
probe_err="$("${tmux_cmd[@]}" list-clients 2>&1 >/dev/null)"; probe_rc=$?
if [ "$probe_rc" -ne 0 ]; then
  report "server unreachable on ${sock:-<default socket>} (exit $probe_rc): ${probe_err:-no stderr}"
  exit 0
fi

# Resolve the type: non-zero status, empty or unexpected output is a real error.
type="$("$dir/nerd-font.sh" type "$sock" 2>&1)"; type_rc=$?
[ "$type_rc" -eq 0 ] || fail "nerd-font.sh type failed (exit $type_rc): ${type:-no output}"
case "$type" in
  nerd | mono | lame) ;;
  "") fail "nerd-font.sh type returned empty output" ;;
  *) fail "nerd-font.sh type returned unexpected value [$type]" ;;
esac
export DOTFILES_NERD_FONT="$type"

# Look up one catalog key into glyph_value. An empty value is valid (the lame
# column is empty for some keys); only a non-zero status is an error.
glyph() {
  local rc
  glyph_value="$("$dir/nerd-font.sh" get "$1" 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] || fail "nerd-font.sh get $1 failed (exit $rc): ${glyph_value:-no output}"
}

# Set one tmux option, reporting the option name and the captured stderr.
set_opt() {
  local err rc
  err="$("${tmux_cmd[@]}" set -g "$1" "$2" 2>&1 >/dev/null)"; rc=$?
  [ "$rc" -eq 0 ] || fail "tmux set -g $1 failed (exit $rc): ${err:-no stderr}"
}

set_opt @nerd_font "$type"
for key in prefix copy tree zoom bell win reload; do
  glyph "$key"
  set_opt "@nerd_font_$key" "$glyph_value"
done
glyph win.active
set_opt @nerd_font_win_active "$glyph_value"
glyph separator.head
set_opt @nerd_font_separator_head "$glyph_value"
glyph separator.tail
set_opt @nerd_font_separator_tail "$glyph_value"

# The probe proved the server is alive, so a failure here is a real error.
err="$("${tmux_cmd[@]}" refresh-client 2>&1 >/dev/null)"; rc=$?
[ "$rc" -eq 0 ] || fail "tmux refresh-client failed (exit $rc): ${err:-no stderr}"
