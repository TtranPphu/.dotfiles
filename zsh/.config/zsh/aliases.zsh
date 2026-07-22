# Pager function (use function, not alias, since $PAGER may not be set at load time)
pg() { "${PAGER:-less}" "$@"; }

alias gs='git status' # What the f*ck is GhostScript, anyway?

# Confirm if output exceeds 64 lines: y/N/p (p = pager)
confirm() {
  local output
  output=$("$@") || return
  local lines=${#${(f)output}}
  if (( lines > 64 )); then
    local reply
    echo -n "Display ${lines} lines of output? [y/N/p] "
    read -k 1 reply; echo
    case $reply in
      [pP]) echo "$output" | ${PAGER:-less}; return ;;
      [yY]) ;;
      *) return 1 ;;
    esac
  fi
  echo "$output"
}

# Alias eza -> ls if available
if command -v eza &>/dev/null; then
  alias ls='eza -ah --icons'

  alias la='confirm eza -lah --icons --group --color=always'
  alias lt='confirm eza -lah --tree --icons --ignore-glob=".git|node_modules" --group --color=always'
  alias ld='confirm eza -lah --only-dirs --icons --group --color=always'
  alias lf='confirm eza -lah --only-files --icons --group --color=always'
  alias lh='confirm eza -lad .* --icons --group --color=always'

  lap() { eza -lah --icons --group --color=always "$@" | ${PAGER:-less}; }
  ltp() { eza -lah --tree --icons --ignore-glob='.git|node_modules' --group --color=always "$@" | ${PAGER:-less}; }
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
