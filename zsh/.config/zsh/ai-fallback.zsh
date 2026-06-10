# Command-not-found fallback: route unknown commands to AI
if (( $+commands[aichat] )) || (( $+commands[claude] )); then
  _claude_fallback() {
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
      '\033[31m' '\033[91m' '\033[33m' '\033[93m' # Red & Yellow
      '\033[34m' '\033[94m' '\033[36m' '\033[96m' # Blue & Cyan
      '\033[32m' '\033[92m' '\033[33m' '\033[93m' # Green & Yellow
      '\033[36m' '\033[96m' '\033[37m' '\033[97m' # Cyan & White
      '\033[35m' '\033[95m' '\033[34m' '\033[94m' # Magenta & Blue
    )
    local spinner=('·' '✶' '✢' '✻' '✽' '✻' '✢' '✶')
    local p w s=1 d=1
    RANDOM=$(( $$ + $(date +%s) ))
    ((p = RANDOM % 5 + 1, w = RANDOM % $#filler + 1))
    local tick=0 next_change
    ((next_change = RANDOM % 28 + 20))
    while kill -0 $pid 2>/dev/null && [ ! -s "$tmp" ]; do
      printf "\r${colors[(p-1)*4 + tick % 4 + 1]}%s %s…\033[0m\033[K" "$spinner[$s]" "$filler[$w]"
      if ((++tick >= next_change)); then
        w=$((RANDOM % $#filler + 1))
        p=$((RANDOM % 5 + 1))
        next_change=tick+$((RANDOM % 28 + 20))
      fi
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
  }

  _ai_cache_file=/tmp/ai-cache-$$

  _ai_setup_hint() {
    if [ -z "$AICHAT_FUNCTIONS_DIR" ] || [ ! -f "$AICHAT_FUNCTIONS_DIR/functions.json" ]; then
      local setup="$HOME/.local/bin/aichat-setup"
      if [ -x "$setup" ]; then
        echo $'\n\033[33m>\033[0m To enable filesystem tools, run:'
        echo $'  \033[32maichat-setup\033[0m'
      fi
    fi
  }

  _ai_dispatch() {
    local route=$1; shift
    case $route in
      claude-pro)  ANTHROPIC_MODEL=deepseek-v4-pro[1m]  _claude_fallback "$@" ;;
      claude-flash) ANTHROPIC_MODEL=deepseek-v4-flash[1m] _claude_fallback "$@" ;;
      aichat-reasoner)
        aichat -m deepseek:deepseek-reasoner -s default --save-session "$*"
        _ai_setup_hint ;;
      aichat-chat)
        aichat -m deepseek:deepseek-chat -s default --save-session "$*"
        _ai_setup_hint ;;
    esac
  }

  command_not_found_handler() {
    local first_five="${*: :5}"
    local lower="${first_five:l}"
    local cache_file=$_ai_cache_file

    if [[ $lower == *pro* ]] && (( $+commands[claude] )); then
      echo "$(( $(date +%s) + 300 ))|claude-pro" > "$cache_file"
      _ai_dispatch claude-pro "$@"

    elif [[ $lower == *claude* || $lower == *deepseek* || $lower == *flash* ]] && (( $+commands[claude] )); then
      echo "$(( $(date +%s) + 300 ))|claude-flash" > "$cache_file"
      _ai_dispatch claude-flash "$@"

    elif [[ $lower == *reasoner* ]] && (( $+commands[aichat] )); then
      echo "$(( $(date +%s) + 300 ))|aichat-reasoner" > "$cache_file"
      _ai_dispatch aichat-reasoner "$@"

    elif [[ $lower == *aichat* || $lower == *chat* ]] && (( $+commands[aichat] )); then
      echo "$(( $(date +%s) + 300 ))|aichat-chat" > "$cache_file"
      _ai_dispatch aichat-chat "$@"

    else
      [[ -f $cache_file ]] || return 1
      local expiry route
      IFS='|' read expiry route < "$cache_file" 2>/dev/null || return 1
      [[ -n $route ]] || return 1
      (( $(date +%s) < expiry )) || { rm -f "$cache_file"; return 1; }
      _ai_dispatch "$route" "$@"
    fi
  }
fi
