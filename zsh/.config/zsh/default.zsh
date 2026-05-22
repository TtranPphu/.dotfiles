# Default environment variables

# Set $EDITOR with priority: nvim > vim > nano
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
elif command -v vim &>/dev/null; then
  export EDITOR=vim
else
  export EDITOR=nano
fi

# Set $PAGER with priority: bat/batcat > less > more
if command -v batcat &>/dev/null; then
  export PAGER=batcat
elif command -v bat &>/dev/null; then
  export PAGER=bat
elif command -v less &>/dev/null; then
  export PAGER=less
else
  export PAGER=more
fi
