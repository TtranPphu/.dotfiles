# Command-not-found fallback: route unknown commands to LLM
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

  _llm_cache_file=/tmp/llm-cache-$$

  _llm_setup_hint() {
    if [ -z "$AICHAT_FUNCTIONS_DIR" ] || [ ! -f "$AICHAT_FUNCTIONS_DIR/functions.json" ]; then
      local setup="$HOME/.local/bin/aichat-setup"
      if [ -x "$setup" ]; then
        echo $'\n\033[33m>\033[0m To enable filesystem tools, run:'
        echo $'  \033[32maichat-setup\033[0m'
      fi
    fi
  }

  _llm_dispatch() {
    local route=$1; shift
    echo "$route" > /tmp/llm-route
    echo "$(( $(date +%s) + 300 ))|$route" > "$_llm_cache_file"
    case $route in
      claude-pro) ANTHROPIC_MODEL=deepseek-v4-pro[1m] _claude_fallback "$@" ;;
      claude-flash) ANTHROPIC_MODEL=deepseek-v4-flash[1m] _claude_fallback "$@" ;;
      aichat-reasoner)
        aichat -m deepseek:deepseek-reasoner -s thinkie -r general --save-session "$*"
        _llm_setup_hint ;;
      aichat-chat)
        aichat -m deepseek:deepseek-chat -s talkie -r general --save-session "$*"
        _llm_setup_hint ;;
      aichat-qwen)
        aichat -m ollama:qwen3:4b-instruct -s qwenie -r general --save-session "$*"
        _llm_setup_hint ;;
    esac
    echo "$(( $(date +%s) + 300 ))|$route" > "$_llm_cache_file"
  }

  command_not_found_handler() {
    local first_five="${*: :5}"
    local lower="${first_five:l}"
    local cache_file=$_llm_cache_file

    local -a words=(${=lower})
    local -a clean_words=()
    local w
    for w in ${words[@]:0:5}; do
      clean_words+=(${w%%[^[:alpha:]]*})
    done

    if (( $clean_words[(Ie)probe] )) && (( $+commands[claude] )); then
      _llm_dispatch claude-pro "$@"

    elif (( $clean_words[(Ie)seekie] || $clean_words[(Ie)flashy] )) && (( $+commands[claude] )); then
      _llm_dispatch claude-flash "$@"

    elif (( $clean_words[(Ie)thinkie] )) && (( $+commands[aichat] )); then
      _llm_dispatch aichat-reasoner "$@"

    elif (( $clean_words[(Ie)talkie] )) && (( $+commands[aichat] )); then
      _llm_dispatch aichat-chat "$@"

    elif (( $clean_words[(Ie)qwenie] )) && (( $+commands[aichat] )); then
      _llm_dispatch aichat-qwen "$@"

    else
      if [[ -f $cache_file ]]; then
        local expiry route
        IFS='|' read expiry route < "$cache_file" 2>/dev/null
        if [[ -n $route ]] && (( $(date +%s) < expiry )); then
          echo "$(( $(date +%s) + 300 ))|$route" > "$cache_file"
          _llm_dispatch "$route" "$@"
          return
        fi
        rm -f "$cache_file"
      fi
      (( $+commands[aichat] )) || return 1
      _llm_dispatch aichat-chat "$@"
    fi
  }
fi
