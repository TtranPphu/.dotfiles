# Command-not-found fallback: route unknown commands to AI
if (( $+commands[aichat] )) || (( $+commands[claude] )); then
  command_not_found_handler() {
    # Check if "claude" is mentioned in the first 3 words (case insensitive)
    local first_three="${*: :3}"
    if [[ "${first_three:l}" == *claude* ]] && (( $+commands[claude] )); then
      claude -c -p "$*"
    elif (( $+commands[aichat] )); then
      aichat -r general -s default --save-session "$*"
      if [ -z "$AICHAT_FUNCTIONS_DIR" ] || [ ! -f "$AICHAT_FUNCTIONS_DIR/functions.json" ]; then
        local setup="$HOME/.local/bin/aichat-setup"
        if [ -x "$setup" ]; then
          echo $'\n\033[33m>\033[0m To enable filesystem tools, run:'
          echo $'  \033[32maichat-setup\033[0m'
        fi
      fi
    else
      return 1
    fi
  }
fi