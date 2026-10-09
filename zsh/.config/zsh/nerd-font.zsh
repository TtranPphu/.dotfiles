# Icons mode: resolved per terminal client from the state file
# (~/.local/state/dotfiles/nerd-font-clients) with a first-run font check.

_nerd_font_sh() { "$HOME/.config/zsh/nerd-font.sh" "$@"; }

_nerd_font_apply() {
  if [[ -n "${TMUX:-}" ]]; then
    "$HOME/.config/tmux/scripts/support/nerd-font-tmux.sh" "${TMUX%%,*}" >/dev/null 2>&1
  fi
}

_nerd_font_needs_setup() {
  local id; id="$(_nerd_font_sh client-id)"
  [[ -z "$(_nerd_font_sh lookup "$id")" ]]
}

# p10k-style single-key prompt: invalid keys are ignored, `q` aborts.
# Sets REPLY to the chosen key and returns 0; on `q` returns 1.
_nerd_font_ask() {
  local choices="$1" key
  print -rn -- "   Choice [${choices}q]: "
  while true; do
    read -rs -k1 key || return 1
    key="${(L)key}"
    if [[ "$key" == q ]]; then
      print
      return 1
    fi
    if [[ "$choices" == *"$key"* ]]; then
      REPLY="$key"
      print
      return 0
    fi
  done
}

# First-run (or `nerd-font setup`) font check, à la p10k: derive the font
# family from glyph questions instead of asking the user for a version.
nerd_font_setup() {
  local id; id="$(_nerd_font_sh client-id)"
  local type="" up3=$'\U000F0737' up2=$'\uFC35'
  local down=$'\U000F0734' left=$'\U000F072E'

  print
  print -r -- "Font check — terminal client: $id"
  print -r -- "This terminal can't be probed for font support, so confirm the glyphs below."
  print -r -- "Press q at any question to skip without storing anything."
  print

  # Nerd Font v3 moved the arrows into plane 15; ask about one of those first.
  print -r -- "Does this look like an upwards arrow?"
  print -r -- "     --->  $up3  <---"
  print -r -- "reference: https://www.nerdfonts.com/cheat-sheet"
  print -r -- "   (y)  Yes"
  print -r -- "   (n)  No"
  _nerd_font_ask yn || { print -r -- "nerd-font: skipped (nothing stored)"; return 0; }

  if [[ "$REPLY" == y ]]; then
    print
    print -r -- "What digit is the downwards arrow pointing at?"
    print -r -- "        $down $down $down $left"
    print -r -- "             111222"
    print -r -- "   (1)  It is pointing at '1'."
    print -r -- "   (2)  It is pointing at '2'."
    print -r -- "   (3)  Something else."
    _nerd_font_ask 123 || { print -r -- "nerd-font: skipped (nothing stored)"; return 0; }
    [[ "$REPLY" == 1 ]] && type=nerd
  fi

  if [[ -z "$type" ]]; then
    print
    print -r -- "Let's try another one. Does this look like an upwards arrow?"
    print -r -- "     --->  $up2  <---"
    print -r -- "reference: https://www.nerdfonts.com/cheat-sheet"
    print -r -- "   (y)  Yes"
    print -r -- "   (n)  No"
    _nerd_font_ask yn || { print -r -- "nerd-font: skipped (nothing stored)"; return 0; }
    [[ "$REPLY" == y ]] && type=nerd-v2
  fi

  if [[ -z "$type" ]]; then
    print
    print -r -- "No Nerd Font glyphs detected — using lame icons."
    type=lame
  fi

  if [[ "$type" != lame ]]; then
    local g1 g2 g3 g4 g5
    g1="$(DOTFILES_NERD_FONT=nerd _nerd_font_sh get branch)"
    g2="$(DOTFILES_NERD_FONT=nerd _nerd_font_sh get battery.full)"
    g3="$(DOTFILES_NERD_FONT=nerd _nerd_font_sh get os.arch)"
    g4="$(DOTFILES_NERD_FONT=nerd _nerd_font_sh get pane)"
    g5="$(DOTFILES_NERD_FONT=nerd _nerd_font_sh get session)"

    print
    print -r -- "Do the icons fit between the crosses without overlapping them?"
    print -r -- "     |X $g1 X $g2 X $g3 X $g4 X $g5 X|"
    print -r -- "   (y)  Yes. Icons are very close to the crosses but there is no overlap."
    print -r -- "   (n)  No. Some icons overlap neighbouring crosses."
    _nerd_font_ask yn || { print -r -- "nerd-font: skipped (nothing stored)"; return 0; }
    [[ "$REPLY" == y && "$type" == nerd ]] && type=nerd-mono
  fi

  _nerd_font_sh store "$id" "$type"
  unset DOTFILES_NERD_FONT
  _nerd_font_apply
  print -r -- "nerd-font: $(_nerd_font_sh type) (client: $id)"
}

nerd-font() {
  case "${1:-}" in
    nerd | lame) export DOTFILES_NERD_FONT="$1" ;;
    plain) export DOTFILES_NERD_FONT=lame ;;
    auto)
      unset DOTFILES_NERD_FONT
      ;;
    setup) nerd_font_setup; return 0 ;;
    "")
      local _id
      _id="$(_nerd_font_sh client-id)"
      print -r -- "nerd-font: $(_nerd_font_sh type) (client: $_id; override: ${DOTFILES_NERD_FONT:-none})"
      return 0
      ;;
    *)
      print -ru2 -- "usage: nerd-font nerd|lame|auto|setup"
      return 1
      ;;
  esac
  _nerd_font_apply
  zle reset-prompt 2>/dev/null || true
  print -r -- "nerd-font: $(_nerd_font_sh type)"
}

_nerd_font_apply
