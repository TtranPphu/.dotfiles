# Icons mode: nerd | plain | auto
# Detection lives in .shared/scripts/icons.sh.

_icons_starship_config() {
  local src="$HOME/.config/starship/starship.toml"
  local out="$HOME/.config/starship/starship-plain.toml"
  local catalog="$(dirname "$(readlink -f "$HOME/.config/zsh/icons.sh")")/icons.tsv"
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

_icons_apply() {
  if [[ "${DOTFILES_ICONS:-nerd}" == plain ]]; then
    _icons_starship_config
    export STARSHIP_CONFIG="$HOME/.config/starship/starship-plain.toml"
  else
    export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  fi
  if [[ -n "${TMUX:-}" ]]; then
    "$HOME/.config/tmux/scripts/support/icons-tmux.sh" "${TMUX%%,*}" >/dev/null 2>&1
  fi
}

icons() {
  case "${1:-}" in
    nerd | plain) export DOTFILES_ICONS="$1" ;;
    auto)
      unset DOTFILES_ICONS
      export DOTFILES_ICONS="$("$HOME/.config/zsh/icons.sh" mode)"
      ;;
    "")
      print -r -- "icons: ${DOTFILES_ICONS:-unset}"
      return 0
      ;;
    *)
      print -ru2 -- "usage: icons nerd|plain|auto"
      return 1
      ;;
  esac
  _icons_apply
  zle reset-prompt 2>/dev/null || true
  print -r -- "icons: $DOTFILES_ICONS"
}

_icons_apply
