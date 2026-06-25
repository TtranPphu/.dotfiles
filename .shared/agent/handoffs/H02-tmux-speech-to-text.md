# Handoff: Speech-to-Text — Overview

## Goal

Pipe microphone input into a text buffer via Whisper, refine with a local LLM, and send to the active tmux pane.

## Flow

```
M-r (start) → record mic → M-r (stop) → Whisper transcribe
    → raw transcript
    → local LLM rephrase (context-aware: file paths, repo refs)
    → tmux menu: [Raw] [Rephrased] [Edit raw] [Edit rep] [Cancel]
    → send-keys to active pane
```

## Sub-handoffs

This is split into three independent handoffs so each layer can be iterated separately:

| Handoff | Focus |
|---------|-------|
| `H03-stt-tmux-integration` | Keybinding, menu, send-keys, state mgmt |
| `H04-stt-capture-transcribe` | ffmpeg recording, faster-whisper, model mgmt |
| `H05-stt-rephrase-agent` | LLM prompt, context resolution, rewrite rules |
