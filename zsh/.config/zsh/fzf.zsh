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
    bat_cmd='batcat --color=always --style=plain'
  else
    bat_cmd='bat --color=always --style=plain'
  fi

  local fzf_file_preview
  fzf_file_preview="if [ -d {} ]; then"
  fzf_file_preview+="  eza -lah --icons --group --color=always {} 2>/dev/null || ls -lah {};"
  fzf_file_preview+=" else"
  fzf_file_preview+="  $bat_cmd {} 2>/dev/null || cat {};"
  fzf_file_preview+=" fi"

  # fzf options with smart preview for files/dirs
  export FZF_DEFAULT_OPTS="--popup 60%,60% --reverse --multi \
    --wrap-sign='' --ellipsis='··' \
    --preview '$fzf_file_preview' \
    --preview-window down:40%,nowrap --preview-wrap-sign='' \
    --bind 'ctrl-d:preview-down,ctrl-u:preview-up'"

  export FZF_COMPLETION_TRIGGER='**'

  # For history search - use sed inline to strip line numbers and leading spaces
  export FZF_CTRL_R_OPTS="--preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\"' --with-nth 2.."

  # For file completion - inherit from DEFAULT
  export FZF_COMPLETION_OPTS=""

  # Widget: pick a git branch (inserts branch name at cursor)
  fzf-branch-widget() {
    local selected saved_stty
    saved_stty=$(stty -g 2>/dev/null || true)
    stty intr '^C' 2>/dev/null || true
    if selected=$(git branch --all --format='%(refname:short)' 2>/dev/null \
      | fzf --popup 60%,60% \
          --preview 'git log --graph \
            --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" \
            {} 2>/dev/null | head -30' \
          --preview-window 'down:50%,nowrap'); then
      LBUFFER="${LBUFFER}${selected} "
    fi
    stty "$saved_stty" 2>/dev/null || true
    zle reset-prompt
    zle -R
  }
  zle -N fzf-branch-widget

  # Widget: pick a git commit hash (inserts hash at cursor)
  fzf-commit-widget() {
    local selected saved_stty
    saved_stty=$(stty -g 2>/dev/null || true)
    stty intr '^C' 2>/dev/null || true
    selected=$(git log --oneline --all 2>/dev/null \
      | fzf --popup 60%,60% \
          --preview 'git show --stat --color=always {1} 2>/dev/null \
            | (batcat --color=always --paging=never --style=plain 2>/dev/null \
              || bat --color=always --paging=never --style=plain 2>/dev/null || cat) \
            | head -60' \
          --preview-window 'down:50%,wrap' \
      | awk '{print $1}')
    stty "$saved_stty" 2>/dev/null || true
    if [[ -n "$selected" ]]; then
      LBUFFER="${LBUFFER}${selected} "
    fi
    zle reset-prompt
    zle -R
  }
  zle -N fzf-commit-widget

  # Bind Ctrl+S to mirror Ctrl+R for history search
  bindkey '^S' fzf-history-widget

  # Replace Ctrl+T with Ctrl+F for file completion
  bindkey '^F' fzf-file-widget
  bindkey -r '^T'

  # Git branch picker: Ctrl+B
  bindkey '^B' fzf-branch-widget

  # Git commit picker: Ctrl+G (unbind first; also ensure terminal doesn't treat ^G as intr)
  stty intr '^C' 2>/dev/null || true
  bindkey -r '^G'
  bindkey '^G' fzf-commit-widget
fi
