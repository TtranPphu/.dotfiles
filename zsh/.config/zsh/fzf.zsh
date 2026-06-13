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

  # File/dir preview with fallbacks
  local fzf_file_preview
  fzf_file_preview="if [ -d {} ]; then"
  fzf_file_preview+="  eza -lah --icons --group --color=always {} 2>/dev/null || ls -lah {};"
  fzf_file_preview+=" else"
  fzf_file_preview+="  $bat_cmd {} 2>/dev/null || cat {};"
  fzf_file_preview+=" fi"

  # Bat preview chain: try batcat, bat, then cat
  local bat_chain
  bat_chain="batcat --color=always --paging=never --style=plain 2>/dev/null"
  bat_chain+=" || bat --color=always --paging=never --style=plain 2>/dev/null"
  bat_chain+=" || cat"

  # Shared fzf layout flags
  local fzf_layout="--popup 60%,60% --reverse"

  # fzf options with smart preview for files/dirs
  export FZF_DEFAULT_OPTS="\
    $fzf_layout --multi \
    --wrap-sign='' --ellipsis='··' \
    --preview '$fzf_file_preview' \
    --preview-window 'down:40%,wrap' \
    --preview-wrap-sign='' \
    --bind 'ctrl-d:preview-down,ctrl-u:preview-up'"

  export FZF_COMPLETION_TRIGGER='**'

  # For file completion - inherit from DEFAULT
  export FZF_COMPLETION_OPTS=""

  # For history search - strip line numbers
  export FZF_CTRL_R_OPTS="\
    --preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\"' \
    --with-nth 2.."

  # Widget: pick a git branch (inserts branch name at cursor)
  fzf-insert-branch-name() {
    local selected
    if selected=$(
      git branch --all --format='%(refname:short)' 2>/dev/null \
      | fzf $fzf_layout \
          --preview 'git log --graph \
            --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" \
            {} 2>/dev/null | head -30' \
          --preview-window 'down:50%,wrap'
    ); then
      LBUFFER="${LBUFFER}${selected} "
    fi
    zle reset-prompt
    zle -R
  }
  zle -N fzf-insert-branch-name

  # Widget: pick a git commit hash (inserts hash at cursor)
  fzf-insert-commit-hash() {
    local selected
    selected=$(
      git log --oneline --all 2>/dev/null \
      | fzf $fzf_layout \
          --preview 'git show --stat --color=always {1} 2>/dev/null \
            | ('"$bat_chain"') \
            | head -60' \
          --preview-window 'down:50%,wrap' \
      | awk '{print $1}'
    )
    if [[ -n "$selected" ]]; then
      LBUFFER="${LBUFFER}${selected} "
    fi
    zle reset-prompt
    zle -R
  }
  zle -N fzf-insert-commit-hash

  # Bind Ctrl+S to mirror Ctrl+R for history search
  bindkey '^S' fzf-history-widget

  # Replace Ctrl+T with Ctrl+F for file completion
  bindkey '^F' fzf-file-widget
  bindkey -r '^T'

  # Git branch picker: Ctrl+B
  bindkey '^B' fzf-insert-branch-name

  # Git commit picker: Ctrl+G
  bindkey -r '^G'
  bindkey '^G' fzf-insert-commit-hash
fi
