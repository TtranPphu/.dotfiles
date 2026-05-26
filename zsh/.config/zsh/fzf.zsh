# fzf integration
if command -v fzf &> /dev/null; then
  # Source fzf keybindings and completion
  source <(fzf --zsh)

  # fzf options with smart preview for files/dirs
  export FZF_DEFAULT_OPTS="--height 40% --reverse --multi --wrap-sign='' --ellipsis='··' --preview 'if [ -d {} ]; then eza -lah --icons --group {} 2>/dev/null || ls -lah {}; else bat --color=always {} 2>/dev/null || cat {}; fi' --preview-window down:30%,wrap --preview-wrap-sign='' --bind 'ctrl-d:half-page-down,ctrl-u:half-page-up'"

  export FZF_COMPLETION_TRIGGER='~~'

  # For history search - override preview to strip line numbers and add field filtering
  export FZF_CTRL_R_OPTS="--preview 'echo {} | sed \"s/^[0-9]*[[:space:]]*//\"' --with-nth 2.."

  # For file completion - inherit from DEFAULT
  export FZF_COMPLETION_OPTS=""

  # Bind Ctrl+S to mirror Ctrl+R for history search
  bindkey '^S' fzf-history-widget
fi
