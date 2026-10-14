#!/usr/bin/env bash
set -euo pipefail

CACHE="/tmp/starship-battery-cache"
LOCK="/tmp/starship-battery.flock"
TTL=60

# Remote battery reads: when this machine is reached over SSH from a tailnet
# client (e.g. the Omarchy laptop), the battery that matters is the client's.
# Read it there over SSH first, falling back to the local paths below. The
# client is referenced by its Tailscale host name, the SSH user defaults to
# the tailnet's and follows the Bluetooth device reads' override
# (BT_REMOTE_SSH_USER), and its host keys come from what Tailscale advertises
# for the peer.

ssh_client_ip() {
  local conn="${SSH_CONNECTION:-}"
  if [[ -z "$conn" && -n "${TMUX:-}" ]] && command -v tmux &>/dev/null; then
    conn=$(tmux show-environment SSH_CONNECTION 2>/dev/null | sed -n 's/^SSH_CONNECTION=//p')
  fi
  [[ -n "$conn" ]] || return 1
  printf '%s' "${conn%% *}"
}

# Tailscale host name for a client address, or the address itself.
ssh_client_host() {
  local ip="$1" host
  if command -v tailscale &>/dev/null && command -v jq &>/dev/null; then
    host=$(tailscale status --json 2>/dev/null |
      jq -r --arg ip "$ip" '.Peer[]? | select(.TailscaleIPs | index($ip)) | .DNSName // empty' 2>/dev/null |
      head -n 1)
    host="${host%.}"
  fi
  printf '%s' "${host:-$ip}"
}

# Known-hosts file built from the host keys Tailscale advertises for the peer,
# so the connection is verified without trusting keys on first use.
remote_known_hosts() {
  local ip="$1" host="$2" file
  file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/remote-ssh-known_hosts"
  command -v tailscale &>/dev/null || return 1
  command -v jq &>/dev/null || return 1
  tailscale status --json 2>/dev/null |
    jq -r --arg ip "$ip" --arg host "$host" \
      '.Peer[]? | select(.TailscaleIPs | index($ip)) | .sshHostKeys[]? | "\($host) \(.)"' \
      > "$file" 2>/dev/null || true
  [[ -s "$file" ]] || return 1
  printf '%s' "$file"
}

# Client-side read: sysfs battery, in the state words the pills understand.
REMOTE_READ='
for b in /sys/class/power_supply/BAT*; do
  [ -r "$b/capacity" ] || continue
  cap=$(cat "$b/capacity") || continue
  st=$(cat "$b/status" 2>/dev/null)
  case "$st" in
    Charging)       st=charging ;;
    Full)           st=fully-charged ;;
    Discharging)    st=discharging ;;
    "Not charging") st=fully-charged ;;
    *)              st=discharging ;;
  esac
  printf "%s %s\n" "$cap" "$st"
  break
done
'

read_battery_remote() {
  command -v ssh &>/dev/null || return 1

  local ip host dest kh out
  local -a ssh_opts=(-o BatchMode=yes -o ConnectTimeout=5)

  ip=$(ssh_client_ip) || return 1
  host=$(ssh_client_host "$ip")
  dest="${BT_REMOTE_SSH_USER:-ttranpphu}@$host"
  if kh=$(remote_known_hosts "$ip" "$host"); then
    ssh_opts+=(-o StrictHostKeyChecking=yes -o UserKnownHostsFile="$kh")
  fi

  out=$(timeout 20 ssh "${ssh_opts[@]}" "$dest" sh -s <<<"$REMOTE_READ" 2>/dev/null | tr -d '\r') || return 1
  out="${out%%$'\n'*}"
  [[ "$out" =~ ^[0-9]+[[:space:]][a-z-]+$ ]] || return 1
  printf '%s' "$out"
}

read_battery_local() {
  local bat raw_status bat_path

  bat_path=$(timeout 0.5 upower -e 2>/dev/null | grep -i bat | head -1)
  if [[ -n "$bat_path" ]]; then
    read -r bat raw_status < <(
      timeout 0.5 upower -i "$bat_path" 2>/dev/null | awk '
        /percentage:/ { gsub(/%/,""); cap = sprintf("%.0f", $2) }
        /state:/      { st = $2 }
        END           { print cap, st }
      '
    )
  fi

  if [[ -z "${bat:-}" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    read -r bat raw_status < <(
      timeout 0.5 powershell.exe -NoProfile -Command '
        $b = Get-WmiObject Win32_Battery
        if ($b) { Write-Host "$($b.EstimatedChargeRemaining) $($b.BatteryStatus)" }
      ' 2>/dev/null | tr -d '\r'
    )
    case "${raw_status:-}" in
      1) raw_status="discharging" ;;
      2|6|7|8|9|11) raw_status="charging" ;;
      3) raw_status="fully-charged" ;;
      *) raw_status="" ;;
    esac
  fi

  [[ -n "${bat:-}" ]] || return 1
  printf '%s %s' "$bat" "${raw_status:-}"
}

fetch_async() {
  (
    flock -xn 200 2>/dev/null || exit 0

    local bat raw_status result

    result=$(read_battery_remote 2>/dev/null) || result=""
    if [[ -z "$result" ]]; then
      result=$(read_battery_local 2>/dev/null) || result=""
    fi

    if [[ -n "$result" ]]; then
      bat="${result%% *}"
      raw_status="${result##* }"
      printf 'bat=%s\nraw_status=%s\nts=%s\n' "$bat" "$raw_status" "$(date +%s)" > "$CACHE"
    fi
  ) 200>"$LOCK" >/dev/null 2>&1 & disown
}

main() {
  mkdir -p /tmp

  local now ts bat raw_status
  now=$(date +%s)

  if [[ -f "$CACHE" ]]; then
    . "$CACHE"
    bat="${bat:-}"
    if [[ -n "$bat" ]]; then
      if [[ $(( now - ${ts:-0} )) -lt "$TTL" ]]; then
        printf '%s %s' "$bat" "${raw_status:-}"
        return 0
      fi
      fetch_async
      printf '%s %s' "$bat" "${raw_status:-}"
      return 0
    fi
  fi

  fetch_async
  return 1
}

main "$@"
