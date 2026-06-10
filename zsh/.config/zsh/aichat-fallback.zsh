# Command-not-found fallback: route unknown commands to AI
if (( $+commands[aichat] )) || (( $+commands[claude] )); then
  command_not_found_handler() {
    # Per-session cache: once routed to claude, keep routing for 5min
    # Mention "aichat" (case insensitive) in first 5 words to opt out
    local cache_file="/tmp/claude-cache-$$"
    local first_five="${*: :5}"
    local to_claude=false
    if [[ "${first_five:l}" == *aichat* ]]; then
      rm -f "$cache_file"
    elif [[ -f $cache_file ]] && (( $(date +%s) < $(<$cache_file) )) && (( $+commands[claude] )); then
      to_claude=true
    else
      if [[ "${first_five:l}" == *claude* ]] && (( $+commands[claude] )); then
        echo $(( $(date +%s) + 300 )) > "$cache_file"
        to_claude=true
      fi
    fi
    if [[ $to_claude == true ]]; then
      local filler=(
        Accomplishing    Actioning          Actualizing     Architecting    Baking
        Beaming          Beboppin\'         Befuddling      Billowing       Blanching
        Bloviating       Boogieing          Boondoggling    Booping         Bootstrapping
        Brewing          Burrowing          Calculating     Canoodling      Caramelizing
        Cascading        Catapulting        Cerebrating     Channeling      Channelling
        Choreographing   Churning           Clauding        Coalescing      Cogitating
        Combobulating    Composing          Computing       Concocting      Considering
        Contemplating    Cooking            Crafting        Creating        Crunching
        Crystallizing    Cultivating        Deciphering     Deliberating    Determining
        Dilly-dallying   Discombobulating   Doing           Doodling        Drizzling
        Ebbing           Effecting          Elucidating     Embellishing    Enchanting
        Envisioning      Evaporating        Fermenting      Fiddle-faddling Finagling
        Flambeing        Flibbertigibbeting Flowing         Flummoxing      Fluttering
        Forging          Forming            Frolicking      Frosting        Gallivanting
        Galloping        Garnishing         Generating      Germinating     Gitifying
        Grooving         Gusting            Harmonizing     Hashing         Hatching
        Herding          Honking            Hullaballooing  Hyperspacing    Ideating
        Imagining        Improvising        Incubating      Inferring       Infusing
        Ionizing         Jitterbugging      Julienning      Kneading        Leavening
        Levitating       Lollygagging       Manifesting     Marinating      Meandering
        Metamorphosing   Misting            Moonwalking     Moseying        Mulling
        Musing           Mustering          Nebulizing      Nesting         Newspapering
        Noodling         Nucleating         Orbiting        Orchestrating   Osmosing
        Perambulating    Percolating        Perusing        Philosophising  Photosynthesizing
        Pollinating      Pondering          Pontificating   Pouncing        Precipitating
        Prestidigitating Processing         Proofing        Propagating     Puttering
        Puzzling         Quantumizing       Razzle-dazzling Razzmatazzing   Recombobulating
        Reticulating     Roosting           Ruminating      Sauteing        Scampering
        Schlepping       Scurrying          Seasoning       Shenaniganing   Shimmying
        Simmering        Skedaddling        Sketching       Slithering      Smooshing
        Sock-hopping     Spelunking         Spinning        Sprouting       Stewing
        Sublimating      Swirling           Swooping        Symbioting      Synthesizing
        Tempering        Thinking           Thundering      Tinkering       Tomfoolering
        Topsy-turvying   Transfiguring      Transmuting     Twisting        Undulating
        Unfurling        Unravelling        Vibing          Waddling        Wandering
        Warping          Whatchamacalliting Whirlpooling    Whirring        Whisking
        Wibbling         Working            Wrangling       Zesting         Zigzagging
      )
      local tmp=$(mktemp /tmp/claude-fallbak.XXXXXX)
      claude --permission-mode auto -c -p "$*" > "$tmp" 2>&1 &
      local pid=$!

      local colors=(
        '\033[31m' '\033[91m' '\033[31m' '\033[91m' '\033[31m' '\033[91m' '\033[31m' '\033[91m' # Reds
        '\033[33m' '\033[93m' '\033[33m' '\033[93m' '\033[33m' '\033[93m' '\033[33m' '\033[93m' # Yellows
        '\033[32m' '\033[92m' '\033[32m' '\033[92m' '\033[32m' '\033[92m' '\033[32m' '\033[92m' # Greens
        '\033[34m' '\033[94m' '\033[34m' '\033[94m' '\033[34m' '\033[94m' '\033[34m' '\033[94m' # Blues
        '\033[35m' '\033[95m' '\033[35m' '\033[95m' '\033[35m' '\033[95m' '\033[35m' '\033[95m' # Purples
        '\033[36m' '\033[96m' '\033[36m' '\033[96m' '\033[36m' '\033[96m' '\033[36m' '\033[96m' # Cyans
        '\033[37m' '\033[97m' '\033[37m' '\033[97m' '\033[37m' '\033[97m' '\033[37m' '\033[97m' # Whites
      )
      local spinner=('·' '✶' '✢' '✻' '✽' '✻' '✢' '✶')
      local p=$((RANDOM % 7 + 1)) w=1 s=1 d=1
      local next_change=$((RANDOM % 28 + 20)) tick=0
      while kill -0 $pid 2>/dev/null && [ ! -s "$tmp" ]; do
        printf "\r${colors[(p-1)*8 + s]}%s %s…\033[0m\033[K" "$spinner[$s]" "$filler[$w]"
        ((++tick >= next_change)) && ((w = (w % $#filler) + 1)) && p=$((RANDOM % 7 + 1)) && next_change=tick+$((RANDOM % 28 + 20))
        ((s += d))
        ((s == $#spinner || s == 1)) && ((d *= -1))
        sleep 0.15
      done

      printf "\r\033[K"
      if (( $+commands[bat] )); then
        tail -n +1 -f --pid="$pid" "$tmp" 2>/dev/null | bat --style=plain --paging=never -l md
      elif (( $+commands[batcat] )); then
        tail -n +1 -f --pid="$pid" "$tmp" 2>/dev/null | batcat --style=plain --paging=never -l md
      else
        tail -n +1 -f --pid="$pid" "$tmp" 2>/dev/null
      fi
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
