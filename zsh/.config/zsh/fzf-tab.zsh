# fzf-tab configuration
if command -v fzf &> /dev/null; then
  # Detect bat/batcat availability
  local cat_cmd
  if command -v batcat &>/dev/null; then
    cat_cmd='batcat --color=always'
  elif command -v bat &>/dev/null; then
    cat_cmd='bat --color=always'
  else
    cat_cmd='cat'
  fi

  # Detect eza availability
  local ls_cmd
  if command -v eza &>/dev/null; then
    ls_cmd='eza -lah --icons'
  else
    ls_cmd='ls -lah'
  fi

  # Always show menu with fzf (don't auto-complete)
  zstyle ':completion:*' menu select

  # Descriptions
  zstyle ':completion:*:descriptions' format '[%d]'

  # Colors
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

  # FZF options - consistent with FZF_DEFAULT_OPTS
  zstyle ':fzf-tab:*' fzf-flags --popup 60%,60% --reverse --multi --wrap-sign='' --ellipsis='··' --preview-window=down:40%,wrap --preview-wrap-sign='' --bind=ctrl-d:preview-down,ctrl-u:preview-up

  # Git previews
  zstyle ':fzf-tab:complete:git-add:*' fzf-preview 'git diff --no-color HEAD -- $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --decorate $word -- $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:git-branch:*' fzf-preview 'git log --oneline --decorate $word -- $realpath 2>/dev/null'
  zstyle ':fzf-tab:complete:git-diff:*' fzf-preview 'git diff $word --no-color $realpath 2>/dev/null'

  # File/dir previews with fallbacks
  zstyle ':fzf-tab:complete:cd:*' fzf-preview "$ls_cmd \$realpath 2>/dev/null"
  zstyle ':fzf-tab:complete:z:*' fzf-preview "$ls_cmd \$realpath 2>/dev/null"
  zstyle ':fzf-tab:complete:_files' fzf-preview "[[ -f \$realpath ]] && $cat_cmd \$realpath 2>/dev/null || $ls_cmd \$realpath 2>/dev/null"
fi
