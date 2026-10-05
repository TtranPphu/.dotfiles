#!/bin/bash

# omarchy:summary=Send files to a machine on your tailnet with Taildrop
# omarchy:args=<machine> [file...]

# Clone of omarchy-tailscale-send that runs tailscale file cp as a tracked
# child so the bar widget can show progress and cancel just this transfer.
# It prints "pid <n>" on stdout once cp starts; the widget kills that pid to
# abort. Everything else matches the stock script: the portal file chooser
# when no files are given, and the same notifications on success, failure,
# and cancellation.

set -uo pipefail

if (($# < 1)); then
  echo "Usage: ttranpphu-tailscale-send <machine> [file...]" >&2
  exit 1
fi

machine="$1"
shift

# Address the machine by whatever name we were handed, but talk about it by
# its short name, so a MagicDNS name does not spill into every message.
name="${machine%%.*}"

files=("$@")

if ((${#files[@]} == 0)); then
  # Command substitution so the chooser's exit status survives: reading it
  # through a process substitution reports success for a chooser that never
  # opened, which is indistinguishable here from someone deciding not to send.
  picked=$(omarchy-file-select --title "Send to $name" --multiple) || status=$?

  if ((${status:-0} > 1)); then
    omarchy-notification-send -g "󰒊" -u critical "Could not send to $name" \
      "The file chooser did not open"
    exit 1
  fi

  readarray -t files <<<"$picked"
  [[ -n $picked ]] || exit 0
fi

if ((${#files[@]} == 1)); then
  what=$(basename "${files[0]}")
else
  what="${#files[@]} files"
fi

# cp's stderr is held for the failure notification. XDG_RUNTIME_DIR, not /tmp:
# this only needs to live as long as the transfer.
err_file="${XDG_RUNTIME_DIR:-$HOME/.cache}/ttranpphu-tailscale-send.$$.err"

tailscale file cp --update-interval=0 -- "${files[@]}" "$machine:" 2>"$err_file" &
cp_pid=$!
echo "pid $cp_pid"

cancelled=0
stop() {
  cancelled=1
  kill -TERM "$cp_pid" 2>/dev/null
}
trap stop TERM INT HUP

wait "$cp_pid"
status=$?
trap - TERM INT HUP

error=$(cat "$err_file" 2>/dev/null)
rm -f "$err_file"

if ((status == 0)); then
  omarchy-notification-send -g "󰒊" "Sent to $name" "$what"
elif ((cancelled)) || ((status == 143 || status == 130 || status == 129)); then
  omarchy-notification-send -g "󰒊" "Cancelled sending to $name" "$what"
  exit 143
else
  omarchy-notification-send -g "󰒊" -u critical "Could not send to $name" \
    "${error:-Taildrop transfer failed}"
  exit 1
fi
