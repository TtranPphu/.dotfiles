# Conceptual "AI" → "LLM" rename (including our own script names)

## Context
Rename "AI" to "LLM" in comments and our own script/module names. External tool references (`aichat` command, `mini.ai` plugin, `claude.ai` URL, `.ai` filetype) stay as-is.

## File renames (git mv)

1. `starship/.config/starship/ai-route.sh` → `starship/.config/starship/llm-route.sh`
2. `starship/.config/starship/ai-route-when.sh` → `starship/.config/starship/llm-route-when.sh`
3. `zsh/.config/zsh/ai.zsh` → `zsh/.config/zsh/llm.zsh`
4. `zsh/.config/zsh/ai-fallback.zsh` → `zsh/.config/zsh/llm-fallback.zsh`

No sourcing changes needed — `.zshrc` uses `for config in ~/.config/zsh/*.zsh` (glob).

## Content changes

### `llm-route.sh`
- Comment: "Output AI route icon" → "Output LLM route icon"
- `/tmp/ai-route` → `/tmp/llm-route`

### `llm-route-when.sh`
- `/tmp/ai-route` → `/tmp/llm-route`

### `starship.toml`
- Format names: `ai_os` → `llm_os`, `ai_pro` → `llm_pro`, `ai_flash` → `llm_flash`, `ai_reasoner` → `llm_reasoner`, `ai_chat` → `llm_chat`
- Section headers: `[custom.ai_*]` → `[custom.llm_*]`
- Command paths: `ai-route.sh` → `llm-route.sh`, `ai-route-when.sh` → `llm-route-when.sh`

### `llm-fallback.zsh`
- Comment: "route unknown commands to AI" → "route unknown commands to LLM"
- Variables: `_ai_cache_file` → `_llm_cache_file`, `/tmp/ai-cache-` → `/tmp/llm-cache-`
- Functions: `_ai_setup_hint` → `_llm_setup_hint`, `_ai_dispatch` → `_llm_dispatch`
- Temp file: `/tmp/ai-route` → `/tmp/llm-route`

### `env.nu`
- Comment: "# AI provider environment variables" → "# LLM provider environment variables"

## Not changing
- `aichat` command references (external tool name)
- `aichat-setup` script (our script, but name references the `aichat` tool name)
- `mini.ai` nvim plugin ID
- `claude.ai` URL
- Yazi `{ name = "ai" }` — Adobe Illustrator filetype

## Verification
- `git diff --stat` to confirm expected file list
- `grep -rn '\bai\b' -- '*.sh' '*.zsh' '*.toml' '*.nu'` to check for remaining references
- Shellcheck on renamed scripts
