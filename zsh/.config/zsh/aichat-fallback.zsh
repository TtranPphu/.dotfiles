# Command-not-found fallback: route unknown commands to AI
if (( $+commands[aichat] )) || (( $+commands[claude] )); then
  command_not_found_handler() {
    # Per-session cache: once routed to claude, keep routing for 5min
    local cache_file="/tmp/claude-cache-$$"
    local to_claude=false
    if [[ -f $cache_file ]] && (( $(date +%s) < $(<$cache_file) )) && (( $+commands[claude] )); then
      to_claude=true
    else
      local first_five="${*: :5}"
      if [[ "${first_five:l}" == *claude* ]] && (( $+commands[claude] )); then
        echo $(( $(date +%s) + 300 )) > "$cache_file"
        to_claude=true
      fi
    fi
    if [[ $to_claude == true ]]; then
      local filler=(
        Cogitating Reticulating Synthesizing Ruminating Percolating
        Contemplating Manifesting Ideating Mulling Tinkering
        Orchestrating Incubating Concocting Brewing Fermenting
        Churning Forging Crystallizing Noodling Marinating
        Simmering Stewing Processing Calculating Crunching
        Spelunking Galumphing Discombobulating Recombobulating
        Razzle-dazzling Prestidigitating Flibbertigibbeting
      )
      local tmp=$(mktemp /tmp/claude-fallbak.XXXXXX)
      claude --permission-mode auto -c -p "$*" > "$tmp" 2>&1 &
      local pid=$!

      local colors=(
        # Reds:           ·        ✻        ✽        ✶        ✢
        '\033[31m' '\033[91m' '\033[38;5;196m' '\033[38;5;160m' '\033[38;5;124m'
        # Oranges
        '\033[38;5;202m' '\033[38;5;208m' '\033[38;5;214m' '\033[38;5;209m' '\033[38;5;215m'
        # Yellows
        '\033[33m' '\033[93m' '\033[38;5;226m' '\033[38;5;220m' '\033[38;5;228m'
        # Greens
        '\033[32m' '\033[92m' '\033[38;5;28m' '\033[38;5;34m' '\033[38;5;46m'
        # Blues
        '\033[34m' '\033[94m' '\033[38;5;27m' '\033[38;5;33m' '\033[38;5;51m'
        # Purples
        '\033[35m' '\033[95m' '\033[38;5;164m' '\033[38;5;171m' '\033[38;5;177m'
        # Cyans
        '\033[36m' '\033[96m' '\033[38;5;44m' '\033[38;5;50m' '\033[38;5;87m'
      )
      local spinner=('·' '✻' '✽' '✶' '✢')
      local p=$((RANDOM % 7 + 1)) w=1 s=1 d=1
      local next_change=$((RANDOM % 28 + 20)) tick=0
      while kill -0 $pid 2>/dev/null && [ ! -s "$tmp" ]; do
        printf "\r${colors[(p-1)*5 + s]}%s %s…\033[0m\033[K" "$spinner[$s]" "$filler[$w]"
        ((++tick >= next_change)) && ((w = (w % $#filler) + 1)) && p=$((RANDOM % 7 + 1)) && next_change=tick+$((RANDOM % 28 + 20))
        ((s += d))
        ((s == $#spinner || s == 1)) && ((d *= -1))
        sleep 0.15
      done

      printf "\r\033[K"
      tail -n +1 -f --pid="$pid" "$tmp" 2>/dev/null
      rm -f "$tmp"
    elif (( $+commands[aichat] )); then
      aichat -r general -s default --save-session "$*"
      if [ -z "$AICHAT_FUNCTIONS_DIR" ] || [ ! -f "$AICHAT_FUNCTIONS_DIR/functions.json" ]; then
        local setup="$HOME/.local/bin/aichat-setup"
        if [ -x "$setup" ]; then
          echo $'\n\033[33m>\033[0m To enable filesystem tools, run:'
          echo $'  \033[32maichat-setup\033[0m'
        fi
      fi
    else
      return 1
    fi
  }
fi