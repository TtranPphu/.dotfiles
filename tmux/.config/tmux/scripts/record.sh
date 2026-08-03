#!/usr/bin/env bash

PIDFILE="/tmp/tmux-speech.pid"
WAVFILE="/tmp/tmux-speech.wav"
TEXTFILE="${WAVFILE%.wav}.txt"
TRANSFILE="/tmp/tmux-speech-transcribing"
PLAYERFILE="/tmp/tmux-speech-players"
PANEFILE="/tmp/tmux-speech-pane"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WSL_SCRIPT="$SCRIPT_DIR/record-wsl.ps1"
SPEECH_PREFIX="This is the user via speech: "

coding_agents=('claude' 'copilot' 'opencode' 'pi')

is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

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

    if is_wsl; then
        rm -f "$WAVFILE"
        powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File "$(wslpath -w "$WSL_SCRIPT")" -Action start &>/dev/null &
        PID=$!
        echo "$PID" > "$PIDFILE"
        tmux display-message -p '#{pane_id}' > "$PANEFILE"
        tmux refresh-client
        return
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
    tmux display-message -p '#{pane_id}' > "$PANEFILE"

    tmux refresh-client
}

wsl_resolve_wav() {
    local win_temp wav
    win_temp=$(powershell.exe -NoProfile -NoLogo -Command '$env:TEMP' 2>/dev/null | tr -d '\r\n')
    [[ -z "$win_temp" ]] && return 1
    wav=$(wslpath "${win_temp}\\tmux-speech.wav" 2>/dev/null) || return 1
    printf '%s' "$wav"
}

stop() {
    if is_wsl; then
        powershell.exe -NoProfile -NoLogo -ExecutionPolicy Bypass -File "$(wslpath -w "$WSL_SCRIPT")" -Action stop &>/dev/null
        rm -f "$PIDFILE"
        WAVFILE=$(wsl_resolve_wav) || { echo "wsl_resolve_wav failed" > /tmp/speech-debug.log; exit 1; }

        if [ ! -f "$WAVFILE" ]; then
            echo "WAV not found: $WAVFILE" > /tmp/speech-debug.log
            exit 1
        fi

        touch "$TRANSFILE"
        tmux refresh-client

        (
            export WHISPER_MODEL="${HOME}/.local/share/whisper/ggml-medium.en.bin"
            export WHISPER_ARGS="-t 8"

            TEXT=$("$SCRIPT_DIR/transcribe.py" "$WAVFILE" 2>/dev/null)
            RET=$?

            rm -f "$TRANSFILE"
            tmux refresh-client

            if [ $RET -eq 2 ]; then
                echo "$(date): transcribe.py returned 2 (blank audio)" >> /tmp/speech-debug.log
                exit 2
            fi

            echo "$TEXT" > "$TEXTFILE"
            echo "$(date): transcribed OK: ${TEXT:0:50}..." >> /tmp/speech-debug.log
            PANE_ID=$(cat "$PANEFILE" 2>/dev/null)
            if [ -n "$PANE_ID" ]; then
                tmux send-keys -t "$PANE_ID" "$SPEECH_PREFIX$TEXT" Enter
            else
                tmux display-message "Not a coding agent pane — text saved to $TEXTFILE"
            fi
            rm -f "$PANEFILE"
        ) & disown
        return
    fi

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
    PANE_ID=$(cat "$PANEFILE" 2>/dev/null)
    if [ -n "$PANE_ID" ]; then
        tmux send-keys -t "$PANE_ID" "$SPEECH_PREFIX$TEXT" Enter
    else
        tmux display-message "Not a coding agent pane — text saved to $TEXTFILE"
    fi
    rm -f "$PANEFILE"
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    *)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            stop
        elif is_coding_agent; then
            start
        else
            tmux display-message "Speech-to-Text only support coding agents!"
            exit 0
        fi
        ;;
esac