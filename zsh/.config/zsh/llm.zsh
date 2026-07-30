if command -v copilot &>/dev/null && [[ -n "$ANTHROPIC_BASE_URL" && -n "$ANTHROPIC_AUTH_TOKEN" ]]; then
  export COPILOT_PROVIDER_TYPE=anthropic
  export COPILOT_PROVIDER_BASE_URL="$ANTHROPIC_BASE_URL"
  export COPILOT_PROVIDER_API_KEY="$ANTHROPIC_AUTH_TOKEN"
  export COPILOT_MODEL="${ANTHROPIC_MODEL:-deepseek-v4-flash[1m]}"
  export COPILOT_OFFLINE=true
  export COPILOT_PROVIDER_MAX_PROMPT_TOKENS=840000
  export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=128000
fi

if command -v ollama &>/dev/null; then
  alias aigc='git commit -m "$(AICHAT_MODEL="ollama:qwen3.5:9b-q4_K_M" ; echo "$(git diff --staged), $AICHAT_MODEL" | aichat -m "$AICHAT_MODEL" -r messager)"'
fi
