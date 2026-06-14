if (( $+commands[copilot] )); then
  export COPILOT_PROVIDER_TYPE=openai
  export COPILOT_PROVIDER_BASE_URL=http://localhost:11434/v1
  export COPILOT_PROVIDER_API_KEY=ollama
  export COPILOT_MODEL=qwen3.5:latest
  export COPILOT_OFFLINE=true
  export COPILOT_PROVIDER_MAX_PROMPT_TOKENS=32768
  export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=8192
fi

if (( $+commands[aichat] )); then
  export DEEPSEEK_API_KEY="${$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' ~/.claude/settings.json 2>/dev/null):-}"
fi
