# Handoff: STT — Rephrase Agent

## Goal

Pass raw Whisper output through a local LLM (Ollama/Qwen) to produce a clean, context-aware version. The agent resolves file paths, repo references, and applies configurable rewrite rules.

## Deliverables

### 1. Rephrase script

**File:** `tmux/.config/tmux/scripts/rephrase.sh`

Pipes raw text through aichat with a dedicated system prompt:

```bash
#!/usr/bin/env bash
raw="$(cat /tmp/tmux-speech-raw.txt)"
workspace="$(tmux display -p '#{pane_current_path}')"

aichat -m qwen3:4b-instruct --prompt "$(cat <<EOF
You are a speech-to-text post-processor running inside a dev workspace.
Clean up the raw transcript: remove filler words, fix grammar, restore punctuation.
Resolve context references:

- If the user says "this file" or "the current file", resolve to the active buffer or
  the most recently modified file in the workspace.
- If the user mentions a filename or path, check if it exists relative to the workspace
  root ($workspace) and expand it to the absolute or repo-relative path.
- If the user references a function, class, or symbol, check the workspace for
  definitions and append the file:line location in parentheses.
- If the user says "the previous command" or "that thing I ran", include the last
  shell command from tmux history if available.

Rules:
- Preserve intent and all technical details (flags, args, paths, code snippets)
- Output only the cleaned text, no explanations
- If the input is noise/gibberish (no recognizable words), output "ERR_NOISE"
EOF
)" <<< "$raw"
```

### 2. Aichat persona (optional)

**File:** `aichat/.config/aichat/roles/stt-rephrase.md`

A dedicated aichat role for the rephrase step so it can be iterated independently of the orchestration script.

### 3. Context sourcing

- **Workspace root** — from `tmux display -p '#{pane_current_path}'`
- **Current file** — from `$EDITOR` IPC if possible (e.g., nvim `:echo expand('%:p')`), otherwise last modified `*.{py,rs,js,ts,sh,md}` in workspace
- **Shell history** — `tail -1 ~/.bash_history` or `fc -ln -1`
- **File existence check** — `find "$workspace" -maxdepth 3 -name "{name}" 2>/dev/null`

These should be collected before calling aichat and injected into the prompt.

## Key Findings

- Existing Ollama Qwen model is sufficient; no new infra
- Prompt is the main lever — iterate on the system prompt to tune behavior
- Context injection keeps the rephrase accurate without expensive RAG
- `ERR_NOISE` sentinel lets the caller know to discard

## Potential Issues

- **LLM latency** — aichat/Ollama call adds 1-5s; show spinner or "Rephrasing..." in tmux
- **Prompt brevity** — LLM may still add explanations despite "Output only the cleaned text"
- **Context staleness** — last modified file heuristic may pick wrong file in hot directories
- **Path expansion** — user may say "the config file" — ambiguous; the agent should guess or leave as-is
- **No aichat** — fallback to just return raw text if aichat is unavailable
- **Over-correction** — LLM may rewrite code snippets or technical terms; prompt needs to stress "preserve technical details verbatim"

## Verification

1. Feed `"I need to fix the bug in this file maybe it's in the utils dot py"` → resolves `utils.py` path in workspace
2. Feed `"run the test with dash dash verbose"` → `run the test --verbose`
3. Feed gibberish `"asdfghjk"` → outputs `ERR_NOISE`
