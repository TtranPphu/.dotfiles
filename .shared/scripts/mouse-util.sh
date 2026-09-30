#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/tmp/mouse-battery.lock"
CACHEFILE="/tmp/mouse-battery.json"
CACHE_TTL=5
REMOTE_CACHE_TTL=60
DBUS_TIMEOUT=2

DBUS_CONN="org.bluez"
DBUS_PATH="/org/bluez/hci0"
BATTERY_SVC_UUID="0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID="00002a19-0000-1000-8000-00805f9b34fb"

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
WSL_PS1="$SCRIPT_DIR/mouse-battery-wsl.ps1"

# Remote battery reads: when this machine is reached over SSH from a tailnet
# client (e.g. the WSL laptop), the Bluetooth devices belong to that client.
# Run the local WSL PowerShell script there instead of reading local BlueZ.
# The client is referenced by its Tailscale host name; the SSH user comes from
# ~/.ssh/config (or the BT_REMOTE_SSH_USER override), so none is pinned here.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
REMOTE_POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

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
  local ip="$1" host="$2" file="$RUNTIME_DIR/remote-ssh-known_hosts"
  command -v tailscale &>/dev/null || return 1
  command -v jq &>/dev/null || return 1
  tailscale status --json 2>/dev/null |
    jq -r --arg ip "$ip" --arg host "$host" \
      '.Peer[]? | select(.TailscaleIPs | index($ip)) | .sshHostKeys[]? | "\($host) \(.)"' \
      > "$file" 2>/dev/null || true
  [[ -s "$file" ]] || return 1
  printf '%s' "$file"
}

cache_ttl() {
  if ssh_client_ip &>/dev/null; then
    printf '%s' "$REMOTE_CACHE_TTL"
  else
    printf '%s' "$CACHE_TTL"
  fi
}

gdbus_prop() {
  local path="$1" iface="$2" prop="$3"
  local out
  out=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$path" \
    --method org.freedesktop.DBus.Properties.Get \
    "$iface" "$prop" 2>/dev/null) || return 1
  out="${out#*<}"
  out="${out%%>*}"
  out="${out#\'}"
  out="${out%\'}"
  printf '%s' "$out"
}

gdbus_read_value() {
  local path="$1" val
  val=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$path" \
    --method org.bluez.GattCharacteristic1.ReadValue {} 2>/dev/null |
    grep -o '0x[0-9a-f][0-9a-f]' | head -1 | sed 's/0x//') || true
  [[ -z "$val" ]] && return 1
  printf '%s' "$val"
}

read_battery_gdbus() {
  local dev_path="" battery_val=""
  local svc_uuid char_uuid

  while read -r dev; do
    local name con
    name=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Alias) || continue
    con=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Connected) || continue
    if [[ "$con" != "true" ]]; then continue; fi
    if [[ "$name" != *LIFT* ]]; then continue; fi
    dev_path="$DBUS_PATH/$dev"
    break
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$DBUS_PATH" 2>/dev/null |
    grep -o 'dev_[A-Z0-9_]*')

  [[ -z "$dev_path" ]] && return 1

  while read -r svc; do
    svc_uuid=$(gdbus_prop "$dev_path/$svc" org.bluez.GattService1 UUID) || continue
    [[ "$svc_uuid" != "$BATTERY_SVC_UUID" ]] && continue

    while read -r chr; do
      char_uuid=$(gdbus_prop "$dev_path/$svc/$chr" org.bluez.GattCharacteristic1 UUID) || continue
      [[ "$char_uuid" != "$BATTERY_LEVEL_UUID" ]] && continue

      raw_val=$(gdbus_read_value "$dev_path/$svc/$chr") || continue
      [[ -z "$raw_val" ]] && continue
      hex_val=$((16#$raw_val))
      [[ "$hex_val" -gt 100 ]] && continue
      battery_val="$hex_val"
    done < <(gdbus introspect --system --only-properties \
      --dest "$DBUS_CONN" --object-path "$dev_path/$svc" 2>/dev/null |
      grep -o 'char[0-9a-f][0-9a-f]*')
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$dev_path" 2>/dev/null |
    grep -o 'service[0-9a-f][0-9a-f]*')

  if [[ -n "$battery_val" ]]; then
    printf '%s' "$battery_val"
    return 0
  fi
  return 1
}

read_battery_wsl() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v powershell.exe &>/dev/null || return 1
  grep -qi microsoft /proc/version 2>/dev/null || return 1

  local result val
  result=$(timeout 10 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WSL_PS1" 2>/dev/null | tr -d '\r') || return 1
  val="${result%% *}"
  [[ -z "$val" ]] && return 1
  printf '%s' "$val"
  return 0
}

read_batteries_remote() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v ssh &>/dev/null || return 1

  local client_ip host dest kh b64 result val
  client_ip=$(ssh_client_ip) || return 1
  host=$(ssh_client_host "$client_ip") || return 1
  dest="${BT_REMOTE_SSH_USER:+$BT_REMOTE_SSH_USER@}$host"
  [[ -n "$dest" ]] || return 1
  b64=$(iconv -f UTF-8 -t UTF-16LE "$WSL_PS1" | base64 -w0) || return 1
  [[ -n "$b64" ]] || return 1

  local ssh_opts=(-o BatchMode=yes -o ConnectTimeout=5)
  if kh=$(remote_known_hosts "$client_ip" "$host"); then
    ssh_opts+=(-o StrictHostKeyChecking=yes -o UserKnownHostsFile="$kh")
  fi

  result=$(timeout 20 ssh "${ssh_opts[@]}" "$dest" \
    "$REMOTE_POWERSHELL -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $b64" \
    2>/dev/null | tr -d '\r') || return 1

  val="${result%% *}"
  [[ -z "$val" ]] && return 1
  printf '%s' "$val"
}

read_batteries() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    read_battery_wsl && return 0
    return 1
  fi
  read_batteries_remote && return 0
  if command -v gdbus &>/dev/null; then
    read_battery_gdbus && return 0
  fi
  return 1
}

fetch_async() {
  (
    flock -xn 200 2>/dev/null || exit 1

    local now ts battery_val
    now=$(date +%s)

    if [[ -f "$CACHEFILE" ]]; then
      read -r battery_val ts < "$CACHEFILE" 2>/dev/null || true
      if [[ -n "$battery_val" ]] && [[ $(( now - ts )) -lt "$(cache_ttl)" ]]; then
        exit 0
      fi
    fi

    local result
    result=$(read_batteries 2>/dev/null) || { rm -f "$CACHEFILE"; exit 1; }
    printf '%s %s\n' "$result" "$now" > "$CACHEFILE"
  ) 200>"$LOCKFILE" >/dev/null 2>&1 & disown
}

main() {
  mkdir -p /tmp

  local now ts battery_val
  now=$(date +%s)

  if [[ -f "$CACHEFILE" ]]; then
    read -r battery_val ts < "$CACHEFILE" 2>/dev/null || true
    if [[ -n "$battery_val" ]]; then
      if [[ $(( now - ts )) -lt "$(cache_ttl)" ]]; then
        printf '%s\n' "$battery_val"
        return 0
      fi
      fetch_async
      printf '%s\n' "$battery_val"
      return 0
    fi
  fi

  fetch_async
  return 1
}

main "$@"
