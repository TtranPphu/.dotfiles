# Plan: Integrate Ollama + Qwen into Aichat

## Context

**Problem:** aichat currently only connects to remote API providers (DeepSeek, OpenAI, Claude). The user has Ollama running locally with Qwen models (already configured for `gh copilot` in `llm.zsh`), but aichat can't use it.

**Goal:** Add an Ollama client to aichat, create a dispatch route (`aichat-qwen`) so the command-not-found fallback can route to the local model, and add a Starship indicator for it.

## Changes

### 1. `aichat/.config/aichat/config.yaml` — Add Ollama client

Insert after the `deepseek` client block:

```yaml
- type: openai-compatible
  name: ollama
  api_base: http://localhost:11434/v1
```

Models are then addressed as `ollama:qwen3:4b-instruct` (`client_name:model_name`).

### 2. `zsh/.config/zsh/llm-fallback.zsh` — Add dispatch route + update existing routes

**2a** — When adding the new `aichat-qwen` case, also update the existing `aichat-chat` and `aichat-reasoner` cases to use dedicated sessions instead of the shared `-s default`:

| Route (nickname) | Current | New |
|-------|---------|-----|
| `aichat-chat` (talkie) | `-m deepseek:deepseek-chat -s default --save-session` | `-m deepseek:deepseek-chat -s talkie --save-session` |
| `aichat-reasoner` (thinkie) | `-m deepseek:deepseek-reasoner -s default --save-session` | `-m deepseek:deepseek-reasoner -s thinkie --save-session` |

**2b** — New case in `_llm_dispatch()` (insert after `aichat-chat)`):

```zsh
aichat-qwen)
  aichat -m ollama:qwen3:4b-instruct -s qwenie --save-session "$*"
  _llm_setup_hint ;;
```

**2c** — New keyword trigger in `command_not_found_handler()` (after `talkie` block, before `else`):

```zsh
elif (( $clean_words[(Ie)qwenie] )) && (( $+commands[aichat] )); then
  _llm_dispatch aichat-qwen "$@"
```

Keyword: `qwenie`.

### 3. `starship/.config/starship/llm-route.sh` — Add route icon

New case in `case $route in` (after `aichat-chat)`):

```bash
aichat-qwen)    echo " " ;;
```

Same spark icon (` `) used by all other routes.

### 4. `starship/.config/starship/starship.toml` — Add custom module

**4a** — Add `${custom.llm_qwen}\` to the format string after `llm_chat`.

**4b** — Register the module after `[custom.llm_chat]`:

```toml
[custom.llm_qwen]
command = 'config_dir="${STARSHIP_CONFIG%/*}"; ${config_dir:-$HOME/.config/starship}/llm-route.sh'
when = 'config_dir="${STARSHIP_CONFIG%/*}"; ${config_dir:-$HOME/.config/starship}/llm-when.sh aichat-qwen'
shell = ["bash"]
style = "white"
format = "[$output]($style)  "
```

### 5. `starship/.config/starship/llm-when.sh` — **No change needed**

## Verification

1. Start aichat with the Ollama model: `aichat -m ollama:qwen3:4b-instruct` — should connect to local Ollama
2. Test dispatch: type any unknown command prefixed with `qwenie` (e.g., `qwenie hello`) — should route to `aichat-qwen`
3. Check session isolation: `cat ~/.config/aichat/sessions/qwen.yaml` — should have `model: ollama:qwen3:4b-instruct`
4. Verify default session isn't corrupted: `grep model: ~/.config/aichat/sessions/default.yaml` — should still show `deepseek:deepseek-chat`
5. Check Starship: activate the qwen route and verify the white indicator appears (if running in a terminal that supports it)
