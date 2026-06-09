# Environment variables for nushell
# Loaded before config.nu

$env.EDITOR = (if (which nvim | length) > 0 { "nvim" } else if (which vim | length) > 0 { "vim" } else { "nano" })

$env.PAGER = (
    if (which batcat | length) > 0 { "batcat" }
    else if (which bat | length) > 0 { "bat" }
    else if (which less | length) > 0 { "less" }
    else { "more" }
)

$env.PATH = ($env.PATH | prepend [
    $"($env.HOME)/.cargo/bin"
    $"($env.HOME)/.local/bin"
])

# Eza colors (Tokyo Night inspired)
$env.EZA_COLORS = (
    "ur=33:uw=31:ux=32:ue=32:gr=33:gw=31:gx=32:tr=33:tw=31:tx=32:su=35:sf=35:xa=36:oc=37"
    + ":di=34:ex=32:fi=37:pi=35:so=35:bd=35:cd=35:ln=36:or=31:sp=35:mp=34"
    + ":im=36:vi=33:mu=32:lo=32:cr=32:do=31:co=33:tm=90:cm=33:bu=33:sc=33:ic=36"
    + ":sn=37:nb=37:nk=37:nm=37:ng=37:nt=37:sb=37:ub=37:uk=37:um=37:ug=37:ut=37"
    + ":df=37:ds=37"
    + ":uu=37:uR=31:un=37:gu=37:gR=31:gn=37"
    + ":lc=37:lm=33"
    + ":ga=32:gm=33:gd=31:gv=36:gt=33:gi=90:gc=31"
    + ":Gm=34:Go=36:Gc=32:Gd=33"
    + ":xx=37:da=36:in=37:bl=37:hd=33:lp=36:cc=37:bO=90:ff=37:Sn=37:Su=37:Sr=37:St=37:Sl=37"
)

# AI provider environment variables
let claude_settings = (try { open ~/.claude/settings.json } catch { null })
let anthropic_base_url = ($claude_settings | default {} | get --optional env | default {} | get --optional ANTHROPIC_BASE_URL | default "https://api.deepseek.com/anthropic")
let anthropic_auth_token = ($claude_settings | default {} | get --optional env | default {} | get --optional ANTHROPIC_AUTH_TOKEN | default "")

if (which copilot | length) > 0 {
    $env.COPILOT_PROVIDER_TYPE = "anthropic"
    $env.COPILOT_PROVIDER_BASE_URL = $anthropic_base_url
    $env.COPILOT_PROVIDER_API_KEY = $anthropic_auth_token
    $env.COPILOT_MODEL = "deepseek-v4-flash[1m]"
    $env.COPILOT_OFFLINE = true
    $env.COPILOT_PROVIDER_MAX_PROMPT_TOKENS = "840000"
    $env.COPILOT_PROVIDER_MAX_OUTPUT_TOKENS = "128000"
}

if (which aichat | length) > 0 {
    $env.DEEPSEEK_API_KEY = $anthropic_auth_token
}

# fzf integration
if (which fzf | length) > 0 {
    let bat_cmd = (if (which batcat | length) > 0 { "batcat --color=always" } else { "bat --color=always" })
    let preview = ('[ -d {} ] && (eza -lah --icons --group --color=always {} 2>/dev/null || ls -lah {}) || (' + $bat_cmd + ' {} 2>/dev/null || cat {})')

    $env.FZF_DEFAULT_OPTS = ("--popup 60%,60% --reverse --multi --wrap-sign='' --ellipsis='··' --preview '" + $preview + "' --preview-window down:40%,wrap --preview-wrap-sign='' --bind 'ctrl-d:preview-down,ctrl-u:preview-up'")
    $env.FZF_COMPLETION_TRIGGER = "**"
    $env.FZF_CTRL_R_OPTS = "--preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\"' --with-nth 2.."
    $env.FZF_COMPLETION_OPTS = ""
}

# Generate starship init if needed
if (which starship | length) > 0 {
    mkdir ~/.cache/starship
    starship init nu | save -f ~/.cache/starship/init.nu
    $env.STARSHIP_CONFIG = $"($env.HOME)/.config/starship/starship.toml"
    $env.STARSHIP_SHELL = "nu"
}

# Generate zoxide init if needed
if (which zoxide | length) > 0 {
    mkdir ~/.cache/zoxide
    zoxide init nushell | save -f ~/.cache/zoxide/init.nu
}

