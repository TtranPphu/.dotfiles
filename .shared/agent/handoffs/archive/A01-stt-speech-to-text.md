# Speech-to-Text Pipeline

## Summary

Speech-to-Text lets the user speak a message that gets transcribed by Whisper and typed into the active coding-agent pane (claude, copilot, opencode, pi). Toggle with `M-v` (`tmux/.config/tmux/bindings.conf:114`): first press starts recording (pausing players), second stops, transcribes, and submits. Transcriptions are prefixed with `This is the user via speech: ` and followed by Enter so the agent handles them automatically. Agents load `.shared/agent/speech-input.md` on start for how to interpret spoken input.

## Files

- `tmux/.config/tmux/scripts/record.sh` — orchestration: start/stop ffmpeg or WSL recording, transcribe, send-keys with prefix + Enter
- `tmux/.config/tmux/scripts/transcribe.py` — calls `whisper-cli` (large-v3, Vulkan GPU), strips timestamps, exits 2 on silence
- `tmux/.config/tmux/scripts/record-wsl.ps1` — Windows-side recording when running under WSL
- `tmux/.config/tmux/scripts/status/speech.sh` — status-right indicator: 󰦚 recording, 󰔮 transcribing
- `tmux/.config/tmux/bindings.conf` — `bind -n M-v run-shell -b '#{@tmux-scripts}/record.sh'`
- `.shared/agent/speech-input.md` — agent guidance for spoken input; linked from `.claude/CLAUDE.md`, `.opencode/AGENTS.md`, `.pi/AGENTS.md`
- `tmux/.config/tmux/scripts/rephrase.sh` — NOT built (see Future iteration)

## Key decisions

- `M-v` (not the proposed `M-r`) is the toggle binding; no prefix needed.
- Text is sent only to recognized coding-agent panes via `#{pane_current_command}`; other panes get "Not a coding agent pane".
- send-keys appends the `This is the user via speech: ` prefix and an Enter key so the message submits itself.
- Mis-transcription recovery is delegated to the receiving agent, not a separate rephrase script: `speech-input.md` (loaded on start) tells agents to interpret spoken input from context. The proposed `rephrase.sh` layer was deliberately skipped.
- Whisper large-v3 on Vulkan; HIP backend disabled (`libggml-hip.so` moved to `.bak`) due to ROCm crash.
- State via `/tmp/tmux-speech-{pid,pid?}.pid`, `transcribing`, `raw.txt`, `pane` files; stale PIDs are detected by `kill -0`.

## Future iteration notes

- No separate rephrase layer is planned — mis-transcriptions are handled by the receiving agent (see `speech-input.md`). Revisit only if raw transcripts prove too noisy for agents.
- Bluetooth headset pauses with a 2s delayed resume; glitch unresolved.
- Whisper uses `ggml-large-v3.bin` (2.9GB); faster-whisper CT2 format is an alternative if HIP ever gets fixed.
- WSL path diverges from native; keep both in sync when changing record.sh.
