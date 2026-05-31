if (( $+commands[copilot] )); then
  export COPILOT_PROVIDER_TYPE=anthropic
  export COPILOT_PROVIDER_BASE_URL="${$(jq -r '.env.ANTHROPIC_BASE_URL' ~/.claude/settings.json 2>/dev/null):-https://api.deepseek.com/anthropic}"
  export COPILOT_PROVIDER_API_KEY="${$(jq -r '.env.ANTHROPIC_AUTH_TOKEN' ~/.claude/settings.json 2>/dev/null):-}"
  export COPILOT_MODEL="${$(jq -r '.env.ANTHROPIC_MODEL' ~/.claude/settings.json 2>/dev/null):-deepseek-v4-flash[1m]}"
  export COPILOT_OFFLINE=true
  export COPILOT_PROVIDER_MAX_PROMPT_TOKENS=840000
  export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=128000
fi
