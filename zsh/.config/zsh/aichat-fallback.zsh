# Command-not-found fallback: send unknown commands to aichat
if (( $+commands[aichat] )); then
  command_not_found_handler() {
    aichat -r general -s default --save-session "$*"
  }
fi
