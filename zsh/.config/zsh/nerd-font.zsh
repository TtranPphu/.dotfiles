# Icons mode: resolved per terminal client from the state file
# (~/.local/state/dotfiles/nerd-font-clients) with a first-run font check.

_nerd_font_sh() { "$HOME/.config/zsh/nerd-font.sh" "$@"; }

_nerd_font_starship_config() {
  local src="$HOME/.config/starship/starship.toml"
  local out="$HOME/.config/starship/starship-plain.toml"
  local catalog="$(dirname "$(readlink -f "$HOME/.config/zsh/nerd-font.sh")")/nerd-font.tsv"
  if [[ -f "$src" && (! -f "$out" || "$src" -nt "$out" || "$catalog" -nt "$out") ]]; then
    perl -CSD -e '
      my %map;
      open my $fh, "<:encoding(UTF-8)", $ARGV[0] or die "$ARGV[0]: $!";
      while (<$fh>) {
        chomp;
        my ($key, $nerd, $plain) = split /\t/;
        next unless defined $nerd && length $nerd;
        $map{$nerd} = (defined $plain ? $plain : "");
      }
      close $fh;
      local $/;
      my $data = <STDIN>;
      for my $g (keys %map) {
        $data =~ s/\Q$g\E/$map{$g}/ge;
      }
      $data =~ s/[\x{e000}-\x{f8ff}\x{f0000}-\x{ffffd}]//g;
      print $data;
    ' "$catalog" < "$src" > "$out"
  fi
}

_nerd_font_apply() {
  local mode="$(_nerd_font_sh mode)"
  if [[ "$mode" == plain ]]; then
    _nerd_font_starship_config
    export STARSHIP_CONFIG="$HOME/.config/starship/starship-plain.toml"
  else
    export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  fi
  if [[ -n "${TMUX:-}" ]]; then
    "$HOME/.config/tmux/scripts/support/nerd-font-tmux.sh" "${TMUX%%,*}" >/dev/null 2>&1
  fi
}

_nerd_font_needs_setup() {
  local id; id="$(_nerd_font_sh client-id)"
  [[ -z "$(_nerd_font_sh lookup "$id")" ]]
}

# First-run (or `nerd-font setup`) font check, à la p10k.
nerd_font_setup() {
  local id; id="$(_nerd_font_sh client-id)"
  print
  print -r -- "Font check — terminal client: $id"
  print -r -- "If these glyphs render as distinct nerd-font (not boxes or '?'), pick your font:"
  print -r -- "   󰂅  󰍽  󰢱  󱡏  󰅸  󱘗  󰌠"
  print -rn -- "   [3] Nerd Font v3   [2] Nerd Font v2   [n] none/plain: "
  local a; read -rs -k1 a; print
  case "$a" in
    3) _nerd_font_sh store "$id" nf3 ;;
    2) _nerd_font_sh store "$id" nf2 ;;
    *) _nerd_font_sh store "$id" plain ;;
  esac
  unset DOTFILES_NERD_FONT
  _nerd_font_apply
  print -r -- "nerd-font: $( [[ "$(_nerd_font_sh mode)" == plain ]] && echo plain || echo nerd )"
}

nerd-font() {
  case "${1:-}" in
    nerd | plain) export DOTFILES_NERD_FONT="$1" ;;
    auto)
      unset DOTFILES_NERD_FONT
      ;;
    setup) nerd_font_setup; return 0 ;;
    "")
      print -r -- "nerd-font: $(_nerd_font_sh mode) (override: ${DOTFILES_NERD_FONT:-none})"
      return 0
      ;;
    *)
      print -ru2 -- "usage: nerd-font nerd|plain|auto|setup"
      return 1
      ;;
  esac
  _nerd_font_apply
  zle reset-prompt 2>/dev/null || true
  print -r -- "nerd-font: $(_nerd_font_sh mode)"
}

_nerd_font_apply
