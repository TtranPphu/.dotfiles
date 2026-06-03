# Pager function (use function, not alias, since $PAGER may not be set at load time)
pg() { "${PAGER:-less}" "$@"; }

alias gs='git status' # What the f*ck is GhostScript, anyway?

# Alias eza -> ls if available
if command -v eza &>/dev/null; then
  alias ls='eza -ah --icons'

  alias la='eza -lah --icons --group'
  alias lt='eza -lah --tree --icons --ignore-glob=.git --group'
  alias ld='eza -lah --only-dirs --icons --group'
  alias lf='eza -lah --only-files --icons --group'
  alias lh='eza -lad .* --icons --group'

  lap() { eza -lah --icons --group --color=always "$@" | ${PAGER:-less}; }
  ltp() { eza -lah --tree --icons --ignore-glob=.git --group --color=always "$@" | ${PAGER:-less}; }
  ldp() { eza -lah --only-dirs --icons --group --color=always "$@" | ${PAGER:-less}; }
  lfp() { eza -lah --only-files --icons --group --color=always "$@" | ${PAGER:-less}; }
  lhp() { eza -lad .* --icons --group --color=always "$@" | ${PAGER:-less}; }
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

# Alias cd -> zoxide is handled in zoxide.zsh

# Alias vi and vim -> nvim if available
if command -v nvim &>/dev/null; then
  alias vi='nvim'
  alias vim='nvim'
fi

if command -v thefuck &>/dev/null; then
  eval $(thefuck --alias)
fi
