# Zoxide configuration - smart cd replacement

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

cd() {
  if (( $+functions[z] )); then
    builtin cd "$@" 2>/dev/null || z "$@"
  else
    builtin cd "$@"
  fi
}
