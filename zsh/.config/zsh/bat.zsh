# Bat configuration - cat replacement with syntax highlighting

# Set pager with fallback chain
if command -v bat &>/dev/null; then
  export PAGER=bat
elif command -v batcat &>/dev/null; then
  export PAGER=batcat
elif command -v most &>/dev/null; then
  export PAGER=most
else
  export PAGER=less
fi

# Alias bat/batcat to cat if available
if command -v bat &>/dev/null; then
  alias cat=bat
elif command -v batcat &>/dev/null; then
  alias cat=batcat
fi
