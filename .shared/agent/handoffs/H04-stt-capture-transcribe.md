# Handoff: STT — Audio Capture & Transcription

## Goal

Record microphone input via ffmpeg and transcribe with a local Whisper model. This layer is a standalone pipeline: WAV in → text out.

## Deliverables

### 1. Recording via ffmpeg

**File:** `tmux/.config/tmux/scripts/record.sh` (or inline in tmux-speech.sh)

```
ffmpeg -y -f alsa -i default -ac 1 -ar 16000 /tmp/tmux-speech.wav
```

- `-y` overwrites without prompt
- `-ac 1` mono (Whisper expects mono)
- `-ar 16000` 16kHz sample rate (Whisper standard)
- Runs in background; PID tracked for stop signal (`kill -INT` or `kill`)

On stop: send SIGINT to ffmpeg to finish the file cleanly, then wait for the WAV to be ready.

### 2. Python transcribe wrapper

**File:** `tmux/.config/tmux/scripts/transcribe.py`

```python
#!/usr/bin/env python3
import sys
from faster_whisper import WhisperModel

model = WhisperModel("base.en", device="cpu", compute_type="int8")
segments, info = model.transcribe(sys.argv[1], beam_size=5)
print(" ".join(seg.text for seg in segments))
```

- `base.en` (~150MB) — good accuracy/size. `small.en` (~500MB) for noisy environments.
- `compute_type="int8"` for CPU speed; `"float16"` if GPU available
- `beam_size=5` balances speed vs accuracy
- Outputs plain text to stdout, one line

### 3. First-run model cache

Model auto-downloads to `~/.cache/faster-whisper/` on first run. No separate install. Download is ~150MB for base.en — warn user if on slow connection.

### 4. Noise gate / empty detection

If transcribed text is empty or under 3 chars (likely silence/noise), exit with code 2 so the caller knows to discard.

## Key Findings

- ALSA device `default` should work on Ubuntu with a mic plugged in
- 16kHz mono WAV is the faster-whisper sweet spot
- ffmpeg handles mic input more reliably than raw `arecord`
- Model stays loaded in memory after first inference; subsequent calls are faster
- `faster-whisper` over `openai-whisper`: ~4x faster on CPU, lower memory

## Potential Issues

- **No mic** — ffmpeg will error; script should detect and show "No mic found"
- **Model download** — first run needs internet; slow on metered connections
- **Long recordings** — memory use scales with audio length; consider chunking if >30s
- **ffmpeg start/stop race** — need to ensure WAV is fully written before transcribing
- **ALSA device name** — may differ across hardware; make device configurable via env var
- **CPU usage** — Whisper on CPU uses 100% of one core during transcription

## Verification

1. Run `ffmpeg -y -f alsa -i default -ac 1 -ar 16000 -t 3 /tmp/test.wav` → records 3s
2. Run `transcribe.py /tmp/test.wav` → prints text
3. Silence test: record with no input → exits code 2
