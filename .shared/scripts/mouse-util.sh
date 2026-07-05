#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/tmp/mouse-battery.lock"
CACHEFILE="/tmp/mouse-battery.json"
CACHE_TTL=5
DBUS_TIMEOUT=2

DBUS_CONN="org.bluez"
DBUS_PATH="/org/bluez/hci0"
BATTERY_SVC_UUID="0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID="00002a19-0000-1000-8000-00805f9b34fb"

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

fetch_async() {
  (
    flock -xn 200 2>/dev/null || exit 1

    local now ts battery_val
    now=$(date +%s)

    if [[ -f "$CACHEFILE" ]]; then
      read -r battery_val ts < "$CACHEFILE" 2>/dev/null || true
      if [[ -n "$battery_val" ]] && [[ $(( now - ts )) -lt "$CACHE_TTL" ]]; then
        exit 0
      fi
    fi

    local result
    result=$(read_battery_gdbus 2>/dev/null) || exit 1
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
      if [[ $(( now - ts )) -lt "$CACHE_TTL" ]]; then
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
