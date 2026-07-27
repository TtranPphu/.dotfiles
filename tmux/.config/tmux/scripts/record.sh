#!/usr/bin/env bash

PIDFILE="/tmp/tmux-speech.pid"
WAVFILE="/tmp/tmux-speech.wav"
TEXTFILE="${WAVFILE%.wav}.txt"
TRANSFILE="/tmp/tmux-speech-transcribing"
PLAYERFILE="/tmp/tmux-speech-players"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

coding_agents=('claude' 'copilot' 'opencode' 'pi')

is_coding_agent() {
    local cmd
    cmd=$(tmux display-message -p '#{pane_current_command}' 2>/dev/null)
    for agent in "${coding_agents[@]}"; do
        [[ "$cmd" == "$agent" ]] && return 0
    done
    return 1
}

pause_players() {
    if ! command -v playerctl &>/dev/null; then
        return
    fi
    > "$PLAYERFILE"
    while IFS= read -r player; do
        if playerctl --player="$player" status 2>/dev/null | grep -q "Playing"; then
            echo "$player" >> "$PLAYERFILE"
        fi
    done < <(playerctl --list-all 2>/dev/null)
    playerctl --all-players pause 2>/dev/null
}

resume_players() {
    if [ ! -f "$PLAYERFILE" ]; then
        return
    fi
    sleep 2
    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        playerctl --player="$player" play 2>/dev/null
    done < "$PLAYERFILE"
    rm -f "$PLAYERFILE"
}

start() {
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        exit 0
    fi

    if ! command -v ffmpeg &>/dev/null; then
        exit 1
    fi

    if ! pactl info &>/dev/null; then
        exit 1
    fi

    PULSE_SOURCE=$(pactl info 2>/dev/null | sed -n 's/^Default Source: //p')
    [[ -z "$PULSE_SOURCE" ]] && exit 1

    rm -f "$WAVFILE"
    pause_players

    ffmpeg -y -f pulse -i "$PULSE_SOURCE" -ac 1 -ar 16000 "$WAVFILE" &
    PID=$!
    echo "$PID" > "$PIDFILE"

    tmux refresh-client
}

stop() {
    if [ ! -f "$PIDFILE" ]; then
        exit 0
    fi

    PID=$(cat "$PIDFILE")
    if ! kill -0 "$PID" 2>/dev/null; then
        rm -f "$PIDFILE"
        exit 0
    fi

    kill -INT "$PID" 2>/dev/null
    rm -f "$PIDFILE"

    for i in $(seq 1 10); do
        if [ -f "$WAVFILE" ]; then
            break
        fi
        sleep 0.1
    done

    for i in $(seq 1 30); do
        if ! kill -0 "$PID" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

    (resume_players) &

    touch "$TRANSFILE"
    tmux refresh-client

    if [ ! -f "$WAVFILE" ]; then
        rm -f "$TRANSFILE"
        tmux refresh-client
        exit 1
    fi

    if [ ! -f "$SCRIPT_DIR/transcribe.py" ]; then
        rm -f "$TRANSFILE"
        tmux refresh-client
        exit 1
    fi

    TEXT=$("$SCRIPT_DIR/transcribe.py" "$WAVFILE" 2>/dev/null)
    RET=$?

    rm -f "$TRANSFILE"
    tmux refresh-client

    if [ $RET -eq 2 ]; then
        exit 2
    fi

    echo "$TEXT" > "$TEXTFILE"
    if is_coding_agent; then
        tmux send-keys "$TEXT"
    else
        tmux display-message "Not a coding agent pane — text saved to $TEXTFILE"
    fi
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    *)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            stop
        else
            start
        fi
        ;;
esac
