# Pager function (use function, not alias, since $PAGER may not be set at load time)
pg() { "${PAGER:-less}" "$@"; }

alias gs='git status' # What the f*ck is GhostScript, anyway?

# Alias eza -> ls if available
if command -v eza &>/dev/null; then
  # Confirm if output exceeds 64 lines: y/N/p (p = pager)
  local _confirm() {
    local output
    output=$("$@") || return
    local lines=${#${(f)output}}
    if (( lines > 64 )); then
      local reply
      echo -n "Display ${lines} lines of output? [y/N/p/e] "
      read -k 1 reply; echo
      case $reply in
        [pP]) echo "$output" | ${PAGER:-less}; return ;;
        [eE]) echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | ${EDITOR:-vim}; return ;;
        [yY]) ;;
        *) return 1 ;;
      esac
    fi
    echo "$output"
  }

  alias ls='eza -ah --icons'

  alias la='_confirm eza -lah --icons --group --color=always'
  alias lt='_confirm eza -lah --tree --icons --ignore-glob=".git|node_modules" --group --color=always'
  alias ld='_confirm eza -lah --only-dirs --icons --group --color=always'
  alias lf='_confirm eza -lah --only-files --icons --group --color=always'
  alias lh='_confirm eza -lad .* --icons --group --color=always'

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
