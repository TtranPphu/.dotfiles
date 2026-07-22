if (( $+commands[copilot] )); then
  local claude_settings=~/.claude/settings.json
  local base_url; base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$claude_settings" 2>/dev/null)
  base_url=${base_url:-https://api.deepseek.com/anthropic}
  local api_key; api_key=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$claude_settings" 2>/dev/null)
  local model; model=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$claude_settings" 2>/dev/null)
  model=${model:-deepseek-v4-flash[1m]}

  export COPILOT_PROVIDER_TYPE=anthropic
  export COPILOT_PROVIDER_BASE_URL="$base_url"
  export COPILOT_PROVIDER_API_KEY="$api_key"
  export COPILOT_MODEL="$model"
  export COPILOT_OFFLINE=true
  export COPILOT_PROVIDER_MAX_PROMPT_TOKENS=840000
  export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=128000
fi

if (( $+commands[ollama] )); then
  alias aigc='git commit -m "$(AICHAT_MODEL="ollama:qwen3.5:9b-q4_K_M" ; echo "$(git diff --staged), $AICHAT_MODEL" | aichat -m "$AICHAT_MODEL" -r messager)"'
fi
