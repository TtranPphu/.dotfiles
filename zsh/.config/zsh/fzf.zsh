# fzf integration
if command -v fzf &> /dev/null; then
  # Source fzf keybindings and completion
  source <(fzf --zsh)

  # fzf options
  export FZF_DEFAULT_OPTS="--height 40% --reverse --multi --preview 'echo {}' --preview-window down:30%,wrap --preview-wrap-sign='' --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up'"

  # Bind Ctrl+S to mirror Ctrl+R for history search
  bindkey '^S' fzf-history-widget
fi
