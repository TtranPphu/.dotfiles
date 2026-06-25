# Handoff: STT — Tmux Integration

## Goal

Wire the M-r toggle, confirmation menu, and send-keys plumbing. This layer owns all tmux interaction and delegates recording/transcription to an external script.

## Deliverables

### 1. Keybinding

**File:** `tmux/.config/tmux/keys.conf`

```
bind-key -n M-r run "tmux-speech.sh toggle"
```

No prefix needed (`-n`). First M-r starts recording, second stops.

### 2. Orchestration script

**File:** `tmux/.config/tmux/scripts/tmux-speech.sh`

- `tmux-speech.sh toggle` with no active recording → starts `ffmpeg` in background, saves PID to `/tmp/tmux-speech.pid`, shows "Recording..." in tmux message
- `tmux-speech.sh toggle` with active recording → kills ffmpeg via PID file, waits for WAV, calls transcribe script, parses result
- On transcribe success → calls rephrase script via aichat
- On transcribe empty/short → shows "No speech detected" and bails
- Shows `tmux display-menu` with:
  - `r` — send raw transcript
  - `R` — send rephrased version
  - `e` — edit raw in $EDITOR, send on save
  - `E` — edit rephrased in $EDITOR, send on save
  - `c` — cancel

### 3. Send-keys helper

```
tmux send-keys -t $(tmux display -p '#{pane_id}') -- "{text}"
```

Need to escape `$`, `"`, `\`, and backticks before sending.

### 4. State management

Use `/tmp/tmux-speech-pid` for recording state. On tmux server restart or crash, stale PID files should be detected (check if process still exists).

## Key Findings

- `bind-key -n` avoids prefix chord — global Alt+R works from any mode
- `display-menu` supports single-key shortcuts with `key` field
- PID file approach is simple but needs cleanup handlers

## Potential Issues

- **M-r conflict** — check `tmux list-keys -n` for existing M-r binds
- **Race on rapid toggle** — debounce or ignore if called while processing
- **Stale PID** — if tmux or script crashes, ffmpeg orphan may hold mic; kill on next invocation
- **$EDITOR not set** — fallback to `vim` or `nano`

## Verification

1. `M-r` → "Recording..." shows in tmux message
2. `M-r` again → recording stops, transcription runs
3. Menu appears with all options
4. `r` sends raw text, `R` sends rephrased, `e`/`E` opens editor
5. `c` dismisses cleanly
