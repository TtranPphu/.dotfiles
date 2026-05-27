# fzf integration
if command -v fzf &> /dev/null; then
  # Source fzf keybindings and completion
  source <(fzf --zsh)

  # Helper function to strip history line numbers
  _fzf_strip_history() {
    echo "$1" | sed 's/^[0-9 ]*//'
  }

  # Preview commands with proper tool detection
  local bat_cmd
  if command -v batcat &>/dev/null; then
    bat_cmd='batcat --color=always'
  else
    bat_cmd='bat --color=always'
  fi

  local fzf_file_preview="if [ -d {} ]; then eza -lah --icons --group --color=always {} 2>/dev/null || ls -lah {}; else $bat_cmd {} 2>/dev/null || cat {}; fi"

  # fzf options with smart preview for files/dirs
  export FZF_DEFAULT_OPTS="--height 60% --reverse --multi --wrap-sign='' --ellipsis='··' --preview '$fzf_file_preview' --preview-window down:40%,wrap --preview-wrap-sign='' --bind 'ctrl-d:preview-down,ctrl-u:preview-up'"

  export FZF_COMPLETION_TRIGGER='~~'

  # For history search - use sed inline to strip line numbers and leading spaces
  export FZF_CTRL_R_OPTS="--preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\"' --with-nth 2.."

  # For file completion - inherit from DEFAULT
  export FZF_COMPLETION_OPTS=""

  # Bind Ctrl+S to mirror Ctrl+R for history search
  bindkey '^S' fzf-history-widget

  # Replace Ctrl+T with Ctrl+F for file completion
  bindkey '^F' fzf-file-widget
  bindkey -r '^T'
fi
