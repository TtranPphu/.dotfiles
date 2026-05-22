# Pager alias
alias pg="$PAGER"

# Alias eza -> ls if available
if command -v eza &>/dev/null; then
  alias ls='eza -ah --icons'

  alias la='eza -lah --icons --group'
  alias lt='eza -lah --tree --icons --ignore-glob=.git --group'
  alias ld='eza -lah --only-dirs --icons --group'
  alias lf='eza -lah --only-files --icons --group'
  alias lh='eza -lad .* --icons --group'

  lap() { eza -lah --icons --group --color=always "$@" | eval $PAGER; }
  ltp() { eza -lah --tree --icons --ignore-glob=.git --group --color=always "$@" | eval $PAGER; }
  ldp() { eza -lah --only-dirs --icons --group --color=always "$@" | eval $PAGER; }
  lfp() { eza -lah --only-files --icons --group --color=always "$@" | eval $PAGER; }
  lhp() { eza -lad .* --icons --group --color=always "$@" | eval $PAGER; }
fi

# Alias cat -> batcat/bat if available
if command -v batcat &>/dev/null; then
  alias cat=batcat
elif command -v bat &>/dev/null; then
  alias cat=bat
fi

# Alias grep -> ripgrep if available
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# Alias cd -> zoxide if available
if command -v zoxide &>/dev/null; then
  alias cd='z'
fi
