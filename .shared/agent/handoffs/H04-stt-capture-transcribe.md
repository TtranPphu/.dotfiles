# Handoff: STT — Audio Capture & Transcription

## Goal

Record microphone via ffmpeg and transcribe with whisper-cpp on AMD GPU (Vulkan). Toggle with `M-v` in tmux — types into coding agent panes (claude, copilot, opencode, pi).

## Pipeline

**File:** `tmux/.config/tmux/scripts/record.sh` — toggle script:
- Start: checks ffmpeg/pulse, saves playing players to PLAYERFILE, pauses them, records 16kHz mono WAV via ffmpeg
- Stop: SIGINT ffmpeg, waits for exit, resumes players async (2s delay), runs transcribe.py, types text or displays message
- `$PULSE_SOURCE` derived from pactl default source (Bluetooth/Laptop mic)
- `$PLAYERFILE` only saves players with "Playing" status — manual pauses stay paused
- `is_coding_agent()` checks `#{pane_current_command}` against claude/copilot/opencode/pi

**File:** `tmux/.config/tmux/scripts/transcribe.py` — calls `whisper-cli` with large-v3 on Vulkan GPU device 1 (RX 6800S), strips timestamps, exits 2 on silence.

**File:** `tmux/.config/tmux/scripts/status/speech.sh` — shows  (recording) / 󰔮 (transcribing) in status-right.

**Binding:** `bind -n M-v run-shell -b '#{@tmux-scripts}/record.sh'`

## Model

`/mnt/shared/whisper-models/ggml-large-v3.bin` (2.9 GB, GGML format). Downloaded from Hugging Face.

## Dependencies

- `whisper-cpp` (pacman) — whisper-cli binary
- `ffmpeg` — audio capture
- `playerctl` — media pause/resume
- `pulseaudio-utils` — pactl for source detection

## Known Issues

- **HIP assertion crash**: `/usr/lib/ggml/libggml-hip.so` causes abort on this ROCm version. Workaround: moved to `.bak`. Vulkan backend works fine.
- **Bluetooth headset pause**: headset switches to HSP/HFP during recording, causing playback glitch. Workaround: 2s async delay + retry resume logic. Root cause unresolved.

## Future Work

- Fix ROCm HIP runtime to re-enable HIP backend
- Test `erax-ai/EraX-WoW-Turbo-V1.1-CT2` model (needs GGUF conversion for whisper-cpp)
- Explore `Systran/faster-whisper-large-v3` CT2 format if CTranslate2 HIP build can be fixed

## Verification

1. `M-v` → status shows , speak
2. `M-v` → status shows 󰔮, text appears in pane (if coding agent) or saved to `/tmp/tmux-speech.txt`
3. `M-v` in non-agent pane → display-message "Not a coding agent pane"
