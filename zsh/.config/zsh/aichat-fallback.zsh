# Command-not-found fallback: send unknown commands to aichat
if (( $+commands[aichat] )); then
  command_not_found_handler() {
    aichat -r general -s default --save-session "$*"
    if [ -z "$AICHAT_FUNCTIONS_DIR" ] || [ ! -f "$AICHAT_FUNCTIONS_DIR/functions.json" ]; then
      local setup="$HOME/.local/bin/aichat-setup"
      if [ -x "$setup" ]; then
        echo $'\n\033[33m>\033[0m To enable filesystem tools, run:'
        echo $'  \033[32maichat-setup\033[0m'
      fi
    fi
  }
fi