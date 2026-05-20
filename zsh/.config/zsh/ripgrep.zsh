# Ripgrep configuration - faster grep replacement

# Alias grep to ripgrep if available
if command -v rg &> /dev/null; then
  alias grep='rg'
fi
