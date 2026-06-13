#!/usr/bin/env bash

line="$1"
pane_mode="$2"

p1s_man='#[fg=brightblack]󰧮 #[fg=blue]M#[fg=brightblack]anual'
p1s_cnf=' #[fg=blue]q#[fg=brightblack]: 󱑠 '
p1s_dth=' 󰛉 #[fg=blue]d#[fg=brightblack]etach'
p1_sys="$p1s_man  $p1s_cnf  $p1s_dth"
p2_pan='#[fg=brightblack] #[fg=blue]Szx#[fg=brightblack]: splitzoomkill pane'
p1_win=' #[fg=blue]crknp#[fg=brightblack]: createrenamekillnextprevious window '
p2_ses=' #[fg=blue]CRKNP#[fg=brightblack]: createrenamekillnextprevious session'
p1_tre='󰙅 #[fg=blue]s#[fg=brightblack]: TREE'
p2_cpy=' #[fg=blue]e#[fg=brightblack]: COPY'
prefix_line_1="$p1_sys  $p1_win  $p1_tre"
prefix_line_2="$p2_pan  $p2_ses  $p2_cpy"

c1_nav='#[fg=blue]hjkl#[fg=brightblack]: move'
c2_nav='#[fg=blue]C-uC-d#[fg=brightblack]: page'
c1_act='#[fg=blue]v󱁐 #[fg=brightblack]: select'
c2_act='#[fg=blue]y󰌑 #[fg=brightblack]: copy  '
c1_srh='#[fg=blue]/?#[fg=brightblack]: '
c2_bck='#[fg=blue] q #[fg=brightblack]: '
copy_line_1="$c1_nav  $c1_act  $c1_srh"
copy_line_2="$c2_nav  $c2_act  $c2_bck"

t1_nav='#[fg=blue]jk#[fg=brightblack]: move  '
t2_sel='#[fg=blue] 󰌑 #[fg=brightblack]: choose'
t1_tag='#[fg=blue]hl#[fg=brightblack]: expandcollapse  #[fg=blue]tT#[fg=brightblack]: tagclear'
t2_tag='#[fg=blue]xX#[fg=brightblack]: kill onetagged  #[fg=blue]C-t#[fg=brightblack]: tag all  '
t1_prv='#[fg=blue]v#[fg=brightblack]: '
t2_bck='#[fg=blue]q#[fg=brightblack]: '
tree_line_1="$t1_nav  $t1_tag  $t1_prv"
tree_line_2="$t2_sel  $t2_tag  $t2_bck"

strip_tmux() {
  printf '%s' "$1" | sed -E 's/#\[[^]]*\]//g'
}

visible_width() {
  strip_tmux "$1" | awk '{ print length($0) }'
}

pair_width() {
  left="$1"
  right="$2"
  left_width="$(visible_width "$left")"
  right_width="$(visible_width "$right")"

  if ((left_width > right_width)); then
    printf '%s' "$left_width"
  else
    printf '%s' "$right_width"
  fi
}

pad_to_width() {
  text="$1"
  width="$2"
  text_width="$(visible_width "$text")"
  padding=$((width - text_width))

  if ((padding < 0)); then
    padding=0
  fi

  printf '%s%*s' "$text" "$padding" ''
}

box_top() {
  text="$1"
  width="$2"
  printf '#[align=centre]#[fg=blue,dim]┌─#[default] %s #[fg=blue,dim]─┐' "$(pad_to_width "$text" "$width")"
}

box_bottom() {
  text="$1"
  width="$2"
  printf '#[align=centre]#[fg=blue,dim]└─#[default] %s #[fg=blue,dim]─┘' "$(pad_to_width "$text" "$width")"
}

if [[ "$line" == 'init' ]]; then
  socket_path="$pane_mode"
  prefix_width="$(pair_width "$prefix_line_1" "$prefix_line_2")"
  tmux -S "$socket_path" set -gq @status-hint-prefix-1 "$(box_top "$prefix_line_1" "$prefix_width")"
  tmux -S "$socket_path" set -gq @status-hint-prefix-2 "$(box_bottom "$prefix_line_2" "$prefix_width")"
  exit 0
fi

if [[ "$pane_mode" == 'copy-mode' ]]; then
  copy_width="$(pair_width "$copy_line_1" "$copy_line_2")"
  case "$line" in
  1) box_top "$copy_line_1" "$copy_width" ;;
  2) box_bottom "$copy_line_2" "$copy_width" ;;
  esac
  exit 0
fi

if [[ "$pane_mode" == 'tree-mode' ]]; then
  tree_width="$(pair_width "$tree_line_1" "$tree_line_2")"
  case "$line" in
  1) box_top "$tree_line_1" "$tree_width" ;;
  2) box_bottom "$tree_line_2" "$tree_width" ;;
  esac
  exit 0
fi
