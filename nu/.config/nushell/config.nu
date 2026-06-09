# Nushell configuration
# Loaded after env.nu

# Source generated init files
source ~/.cache/starship/init.nu
source ~/.cache/zoxide/init.nu

# --- Aliases ---

# Pager function
def pg [] {
    ^$env.PAGER $in
}

# Git status
alias gs = git status

# eza
if (which eza | length) > 0 {
    alias ls = eza -ah --icons
    alias la = eza -lah --icons --group
    alias lt = eza -lah --tree --icons --ignore-glob=.git --group
    alias ld = eza -lah --only-dirs --icons --group
    alias lf = eza -lah --only-files --icons --group
    alias lh = eza -lad .* --icons --group
}

# cat -> bat
if (which batcat | length) > 0 {
    alias cat = batcat
} else if (which bat | length) > 0 {
    alias cat = bat
}

# grep -> ripgrep
if (which rg | length) > 0 {
    alias grep = rg
}

# vi/vim -> nvim
if (which nvim | length) > 0 {
    alias vi = nvim
    alias vim = nvim
}

# cd -> zoxide
alias cd = __zoxide_z

# --- Auto-start tmux/zellij ---

if ((($env.TMUX? | is-empty) and ($env.ZELLIJ? | is-empty)) and ($env.DOTFILES_SHELL_PICKED? | is-empty)) {
    let has_tmux = (which tmux | length) > 0
    let has_zellij = (which zellij | length) > 0
    let has_aichat = (which aichat | length) > 0
    let blue = $"(char --integer 0x1b)[34m"
    let reset = $"(char --integer 0x1b)[0m"

    if $has_tmux and $has_zellij {
        let has_zsh = (which zsh | length) > 0
        print ("Shells:       " + $blue + "N" + $reset + "ushell (default)" + (if $has_zsh { " | " + $blue + "Z" + $reset + "sh" } else { "" }))
        print ("Multiplexers: " + $blue + "T" + $reset + "mux | Zelli" + $blue + "j" + $reset)
        print ("Applications: " + $blue + "A" + $reset + "ichat")
        print -n "Pick: "
        let choice = (input --numchar 1 --suppress-output)
        $env.DOTFILES_SHELL_PICKED = "1"
        match $choice {
            "n" | "N" => { clear }
            "z" | "Z" => { clear; zsh; exit }
            "t" | "T" => { clear; tmux new -A -s default; exit }
            "j" | "J" => { clear; zellij attach -c default; exit }
            "a" | "A" => { clear; aichat; exit }
            _ => { clear }
        }
    } else if $has_tmux {
        $env.DOTFILES_SHELL_PICKED = "1"; clear; tmux new -A -s default; exit
    } else if $has_zellij {
        $env.DOTFILES_SHELL_PICKED = "1"; clear; zellij attach -c default; exit
    }
}

# --- Dependency installer ---
let install_script = $"($env.HOME)/.local/share/zsh/install.sh"
if ($install_script | path exists) {
    ^$install_script
}
