# Pager alias
alias pg="$PAGER"

# Configure eza if available
if command -v eza &>/dev/null; then
  alias ls='eza -ah --icons'

  alias la='eza -lah --icons --group'
  alias lt='eza -lah --tree --icons --ignore-glob=.git --group'
  alias ld='eza -lah --only-dirs --icons --group'
  alias lf='eza -lah --only-files --icons --group'
  alias lh='eza -lad .* --icons --group'

  lap() { eza -lah --icons --group --color=always "$@" | $PAGER; }
  ltp() { eza -lah --tree --icons --ignore-glob=.git --group --color=always "$@" | $PAGER; }
  ldp() { eza -lah --only-dirs --icons --group --color=always "$@" | $PAGER; }
  lfp() { eza -lah --only-files --icons --group --color=always "$@" | $PAGER; }
  lhp() { eza -lad .* --icons --group --color=always "$@" | $PAGER; }
fi
