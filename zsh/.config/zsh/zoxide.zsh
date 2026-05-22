# Zoxide configuration - smart cd replacement

# Initialize zoxide if available
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"

  # Alias cd to zoxide
  alias cd='z'
fi
