# Nushell configuration
# Loaded after env.nu

# Source generated init files
source ~/.cache/nu/starship.nu
source ~/.cache/nu/zoxide.nu
source ~/.cache/nu/aliases.nu

# --- Picker: choose shell (nushell/zsh) and multiplexer (tmux/zellij) at startup ---
if ((($env.TMUX? | is-empty) and ($env.ZELLIJ? | is-empty)) and ($env.DOTFILES_SHELL_PICKED? | is-empty)) {
    let has_tmux = (which tmux | length) > 0
    let has_zellij = (which zellij | length) > 0
    let green = $"(char --integer 0x1b)[1;32m"
    let reset = $"(char --integer 0x1b)[0m"

    if $has_tmux and $has_zellij {
        let has_zsh = (which zsh | length) > 0
        print ("Shells:       " + $green + "N" + $reset + "ushell (default)" + (if $has_zsh { " | " + $green + "Z" + $reset + "sh" } else { "" }))
        print ("Multiplexers: " + $green + "T" + $reset + "mux | Zelli" + $green + "j" + $reset)
        print -n "Pick: "
        let choice = (input --numchar 1 --suppress-output)
        $env.DOTFILES_SHELL_PICKED = "1"
        match $choice {
            "n" | "N" => { clear }
            "z" | "Z" => { clear; zsh; exit }
            "t" | "T" => { clear; tmux new -A -s ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-') nu; exit }
            "j" | "J" => { clear; $env.SHELL = "nu"; zellij attach -c ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-'); clear; exit }
            _ => { clear }
        }
    } else if $has_tmux {
        $env.DOTFILES_SHELL_PICKED = "1"; clear; tmux new -A -s ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-') nu; exit
    } else if $has_zellij {
        $env.DOTFILES_SHELL_PICKED = "1"; clear; $env.SHELL = "nu"; zellij attach -c ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-'); clear; exit
    }
}

# --- Dependency installer ---
let install_script = $"($env.HOME)/.local/share/zsh/install-dependencies.sh"
if ($install_script | path exists) {
    ^$install_script
}
source "~/.cargo/env.nu"
