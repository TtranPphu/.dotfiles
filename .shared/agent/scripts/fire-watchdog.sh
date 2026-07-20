#!/usr/bin/env bash
# fire-watchdog — wait for a PID to exit, then notify the initiating agent
#
# Usage:
#   fire-watchdog.sh <pid-file> <notify-pane-id> <label> [target-pane-id] [interval]
#   target-pane-id: pane where the command ran (default: label only)
#   interval: polling interval in seconds (default: 1)
#
# Waits for the PID file to appear (written by the command inside tmux),
# then polls kill -0 until the process exits. Sends a self-identifying
# completion message to <notify-pane-id> via send-keys.

set -euo pipefail

PID_FILE=$1
NOTIFY_PANE=$2
LABEL="${3:-command}"
TARGET_PANE="${4:-}"
INTERVAL="${5:-1}"

# Wait for PID file to appear
for i in $(seq 1 10); do
  if [[ -f "$PID_FILE" ]]; then
    break
  fi
  sleep 0.5
done

if [[ ! -f "$PID_FILE" ]]; then
  if [[ -n "$TARGET_PANE" ]]; then
    LOCATION=" in pane $TARGET_PANE"
  else
    LOCATION=""
  fi
  tmux send-keys -t "$NOTIFY_PANE" \
    "Pane $NOTIFY_PANE watchdog: \"$LABEL\" failed$LOCATION — PID file never appeared. Over." Enter
  exit 1
fi

PID=$(cat "$PID_FILE")

# Wait for process to die
while kill -0 "$PID" 2>/dev/null; do
  sleep "$INTERVAL"
done

# Clean up
rm -f "$PID_FILE"

if [[ -n "$TARGET_PANE" ]]; then
  LOCATION=" in pane $TARGET_PANE"
else
  LOCATION=""
fi

tmux send-keys -t "$NOTIFY_PANE" \
  "Pane $NOTIFY_PANE watchdog: \"$LABEL\" completed$LOCATION. Inspect the results. Over." Enter
