#!/usr/bin/env bash

# Restyle tmux's native window-list clipping markers.
#
# tmux clips the status window list and renders the text between
# #[list=left-marker]/#[list=right-marker] only when the list is trimmed on
# that side. The default markers are "<" and ">"; replace them with the
# overflow indicators the bar uses, padded with a space on each side and
# styled like the other dividers.
#
# Idempotent: the upstream default pair, the earlier unspaced pair, and the
# intermediate right-unpadded pair are matched once; once the final padded
# form is in place a re-run is a no-op.
set -euo pipefail

socket_path="$1"

fmt="$(tmux -S "$socket_path" show -gv 'status-format[0]')"

old_default='#[list=left-marker]<#[list=right-marker]>'
old_unspaced='#[list=left-marker]#[fg=brightblack,bold]❮#[list=right-marker]#[fg=brightblack,bold]❯'
old_right_unpadded='#[list=left-marker]#[fg=brightblack,bold] ❮ #[list=right-marker]#[fg=brightblack,bold]❯ '
new_pair='#[list=left-marker]#[fg=brightblack,bold] ❮ #[list=right-marker]#[fg=brightblack,bold] ❯ '

changed=0
for old in "$old_default" "$old_unspaced" "$old_right_unpadded"; do
  if [[ "$fmt" == *"$old"* ]]; then
    fmt="${fmt//"$old"/"$new_pair"}"
    changed=1
  fi
done

if (( changed )); then
  tmux -S "$socket_path" set -g 'status-format[0]' "$fmt"
fi
