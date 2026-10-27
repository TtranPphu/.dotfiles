# Command duration for the starship custom.duration segment. Starship's
# built-in cmd_duration prints compact units (1m30s) with no spacing option,
# so measure here and let duration.sh format it.

zmodload zsh/datetime
autoload -Uz add-zsh-hook

# preexec: a command is about to run, mark the start.
_dotfiles_duration_preexec() {
  _dotfiles_duration_start=$EPOCHREALTIME
}

# precmd: runs before starship renders (this file is sourced before
# `starship init`). Only a command that actually ran has a start mark, so a
# bare Enter or prompt refresh clears the stale value instead of re-showing it.
_dotfiles_duration_precmd() {
  local start=${_dotfiles_duration_start:-}
  unset _dotfiles_duration_start

  if [[ $start =~ '^[0-9]+(\.[0-9]+)?$' ]]; then
    local -i ms=$(( (EPOCHREALTIME - start) * 1000 ))
    ((ms < 0)) && ms=0
    export DOTFILES_CMD_DURATION_MS=$ms
  else
    unset DOTFILES_CMD_DURATION_MS
  fi
}

add-zsh-hook preexec _dotfiles_duration_preexec
add-zsh-hook precmd _dotfiles_duration_precmd
