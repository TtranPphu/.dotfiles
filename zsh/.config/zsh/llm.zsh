if command -v ollama &>/dev/null; then
  alias aigc='git commit -m "$(AICHAT_MODEL="ollama:qwen3.5:9b-q4_K_M" ; echo "$(git diff --staged), $AICHAT_MODEL" | aichat -m "$AICHAT_MODEL" -r messager)"'
fi
