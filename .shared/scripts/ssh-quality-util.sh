#!/usr/bin/env bash
# SSH connection quality: client IP resolution and latency sampling.
#
#   ssh-quality-util.sh ip    [socket] [session]  -> client IP; exit 1 when not SSH'd
#   ssh-quality-util.sh rtt   [socket] [session]  -> cached round-trip ms ("-" = ping failed)
#   ssh-quality-util.sh level [socket] [session]  -> 1..10, 10 = best; exit 1 when not SSH'd
#   ssh-quality-util.sh signal [socket] [session] -> signal-strength icon; exit 1 when not SSH'd
#   ssh-quality-util.sh map   <rtt_ms>            -> level for an RTT
#
# The tmux server environment can hold a stale SSH_CONNECTION, so when a socket
# and session are given the attached clients' /proc/<pid>/environ is the source
# of truth. The RTT is cached keyed by client IP and refreshed in the
# background, so callers never block on ping.
set -euo pipefail

# The signal glyph comes from the shared icon catalog, so each
# client type (nerd/mono/lame) resolves to its own glyph.
source "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")/icon.sh"

CACHE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/starship"
CACHE="$CACHE_DIR/ssh-quality"
LOCK="$CACHE_DIR/ssh-quality.lock"
TTL=15

# 30 ms per step: <=30 ms -> 10 (green), >=300 ms -> 1 (red).
map_rtt() {
  local rtt="${1:-}" level
  [[ $rtt =~ ^[0-9]+$ ]] || return 1
  level=$(( 11 - (rtt + 29) / 30 ))
  (( level < 1 )) && level=1
  (( level > 10 )) && level=10
  printf '%s' "$level"
}

client_ip() {
  local socket="${1:-}" session="${2:-}" pid conn
  # A rendering client pinned by the status scripts wins over any scan.
  if [[ -v DOTFILES_CLIENT_SSH ]]; then
    conn="$DOTFILES_CLIENT_SSH"
    [[ -n $conn ]] || return 1
    printf '%s' "${conn%% *}"
    return 0
  fi
  if [[ -n $socket && -n $session ]]; then
    while read -r pid; do
      conn=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null |
        sed -n 's/^SSH_CONNECTION=//p' || true)
      if [[ -n $conn ]]; then
        printf '%s' "${conn%% *}"
        return 0
      fi
    done < <(tmux -S "$socket" list-clients -t "$session" -F '#{client_pid}' 2>/dev/null)
    return 1
  fi
  conn="${SSH_CONNECTION:-${SSH_CLIENT:-}}"
  [[ -n $conn ]] || return 1
  printf '%s' "${conn%% *}"
}

refresh_async() {
  local ip=$1
  (
    mkdir -p "$CACHE_DIR"
    exec 9>"$LOCK"
    if command -v flock >/dev/null 2>&1; then
      flock -n 9 || exit 0
    fi
    local rtt ts
    rtt=$(timeout 2 ping -c1 -W1 -n "$ip" 2>/dev/null |
      sed -n 's/.*time[=<]\([0-9.]*\) *ms.*/\1/p' || true)
    rtt="${rtt%%.*}"
    ts=$(date +%s)
    printf '%s %s %s\n' "$ip" "${rtt:--}" "$ts" >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
  ) >/dev/null 2>&1 & disown
}

ssh_quality_rtt() {
  local ip cip crtt ts now
  ip=$(client_ip "${1:-}" "${2:-}") || return 1
  if [[ -f $CACHE ]]; then
    read -r cip crtt ts <"$CACHE" || true
    if [[ ${cip:-} == "$ip" ]]; then
      now=$(date +%s)
      if (( now - ${ts:-0} >= TTL )); then
        refresh_async "$ip"
      fi
      printf '%s' "${crtt:--}"
      return 0
    fi
  fi
  refresh_async "$ip"
  return 1
}

ssh_quality_level() {
  local rtt
  rtt=$(ssh_quality_rtt "${1:-}" "${2:-}") || return 1
  if [[ $rtt == "-" ]]; then
    printf '1'
  else
    map_rtt "$rtt"
  fi
}

# 5 tiers at 20/40/60/80% of the level scale (1..10 -> 10..100).

signal_icon() {
  local level p tier
  level=$(ssh_quality_level "${1:-}" "${2:-}") || return 1
  p=$((level * 10))
  tier=$((1 + (p >= 20) + (p >= 40) + (p >= 60) + (p >= 80)))
  nerd_font_icon "signal.$tier"
}

case "${1:-}" in
  ip) shift; client_ip "${1:-}" "${2:-}" ;;
  rtt) shift; ssh_quality_rtt "${1:-}" "${2:-}" ;;
  level) shift; ssh_quality_level "${1:-}" "${2:-}" ;;
  signal) shift; signal_icon "${1:-}" "${2:-}" ;;
  map) shift; map_rtt "${1:-}" ;;
  *)
    echo "usage: ssh-quality-util.sh ip|rtt|level|signal [socket] [session] | map <rtt_ms>" >&2
    exit 2
    ;;
esac
