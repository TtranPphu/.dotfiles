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
    let active = $"(char --integer 0x1b)[1;34m"
    let reset = $"(char --integer 0x1b)[0m"

    if $has_tmux and $has_zellij {
        let has_zsh = (which zsh | length) > 0
        print ("Shells:       " + $green + "N" + $reset + "ushell (default)" + (if $has_zsh { " | " + $green + "Z" + $reset + "sh" } else { "" }))
        print ("Multiplexers: " + $green + "T" + $reset + "mux | Zelli" + $green + "j" + $reset)
        print -n "Pick: "
                let choice = (input --numchar 1 --suppress-output | str downcase)
                $env.DOTFILES_SHELL_PICKED = "1"
                match $choice {
            "n" | "N" => { clear }
            "z" | "Z" => { clear; zsh; exit }
            "t" | "T" => {
                clear
                $env.DOTFILES_SHELL_PICKED = "1"
                let presets = {
                    default: { key: "", name: "default", dir: $env.PWD, windows: [] }
                    d: { key: "d", name: "dotfiles", dir: ($env.HOME | path join ".dotfiles"), windows: [[opencode], [nvim], []] }
                    t: { key: "t", name: "tiny-repository", dir: ($env.HOME | path join "projects" "tiny-repository"), windows: [[opencode], [nvim], []] }
                }
                print "Session presets:"
                let items = ($presets | transpose key val | where key != "default")
                let max_len = ($items | each { |p| $p.val.name | str length } | math max)
                for p in $items {
                    let hc = ($p.val.name | str substring 0..0)
                    let rest = ($p.val.name | str substring 1..)
                    let icons = ($p.val.windows | enumerate | each { |it|
                        if $it.index == 0 {
                            if ($it.item | length) == 0 { $"($active)  $shell ($reset)" } else { $"($active)  ($it.item | first) ($reset)" }
                        } else {
                            if ($it.item | length) == 0 { $"  $shell " } else { $"  ($it.item | first) " }
                        }
                    } | str join)
                    let pad = ($max_len - ($p.val.name | str length) + 1)
                    let padding = ("" | fill -c " " -w $pad -a l)
                    print $"   ($green)($hc)($reset)($rest):($padding)($icons)"
                }
                print -n "Pick: "
                let choice = (input --numchar 1 --suppress-output | str downcase)
                let preset = ($presets | get -o $choice | default ($presets | get -o "default"))
                if ($preset | is-empty) {
                    tmux new -A -s ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-') nu; exit
                }
                let dir = $preset.dir
                let session = ($dir | path basename | str replace --regex '^\.' '' | str replace --all '.' '-')
                if (tmux has-session -t $session | complete | get exit_code) == 0 {
                    clear; tmux attach-session -t $session; exit
                }
                let windows = $preset.windows
                if ($windows | length) == 0 {
                    tmux new-session -d -s $session -c $dir; clear; tmux attach-session -t $session; exit
                }
                let first = ($windows | first)
                tmux new-session -d -s $session -c $dir -n ($first | first)
                tmux send-keys -t $"($session):1.1" $"($first | first)" Enter
                mut pane = "1"
                for app in ($first | skip 1) {
                    let geo = (tmux display-message -p -t $"($session):1.($pane)" '#{pane_width} #{pane_height}')
                    let dims = ($geo | split row " ")
                    let w = ($dims | first | into int)
                    let h = ($dims | last | into int)
                    if $w > $h * 2 {
                        $pane = (tmux split-window -h -t $"($session):1.($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                    } else {
                        $pane = (tmux split-window -v -t $"($session):1.($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                    }
                    tmux send-keys -t $"($session):1.($pane)" $"$app" Enter
                }
                mut win_idx = 2
                for win_def in ($windows | skip 1) {
                    if ($win_def | length) == 0 {
                        tmux new-window -t $session -c $dir
                    } else {
                        tmux new-window -t $session -c $dir -n ($win_def | first)
                        tmux send-keys -t $"($session):($win_idx).1" $"($win_def | first)" Enter
                        mut pane = "1"
                        for app in ($win_def | skip 1) {
                            let geo = (tmux display-message -p -t $"($session):($win_idx).($pane)" '#{pane_width} #{pane_height}')
                            let dims = ($geo | split row " ")
                            let w = ($dims | first | into int)
                            let h = ($dims | last | into int)
                            if $w > $h * 2 {
                                $pane = (tmux split-window -h -t $"($session):($win_idx).($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                            } else {
                                $pane = (tmux split-window -v -t $"($session):($win_idx).($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                            }
                            tmux send-keys -t $"($session):($win_idx).($pane)" $"$app" Enter
                        }
                    }
                    $win_idx += 1
                }
                tmux select-window -t $"($session):1"
                clear; tmux attach-session -t $session; exit
            }
            "j" | "J" => { clear; $env.SHELL = "nu"; zellij attach -c ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-'); clear; exit }
            _ => { clear }
        }
    } else if $has_tmux {
        clear
        $env.DOTFILES_SHELL_PICKED = "1"
        let presets = {
            default: { key: "", name: "default", dir: $env.PWD, windows: [] }
            d: { key: "d", name: "dotfiles", dir: ($env.HOME | path join ".dotfiles"), windows: [[opencode], [nvim], []] }
            t: { key: "t", name: "tiny-repository", dir: ($env.HOME | path join "projects" "tiny-repository"), windows: [[opencode], [nvim], []] }
        }
        print "Session presets:"
        let items = ($presets | transpose key val | where key != "default")
        let max_len = ($items | each { |p| $p.val.name | str length } | math max)
        for p in $items {
            let hc = ($p.val.name | str substring 0..0)
            let rest = ($p.val.name | str substring 1..)
            let icons = ($p.val.windows | enumerate | each { |it|
                if $it.index == 0 {
                    if ($it.item | length) == 0 { $"($active)  $shell ($reset)" } else { $"($active)  ($it.item | first) ($reset)" }
                } else {
                    if ($it.item | length) == 0 { $"  $shell " } else { $"  ($it.item | first) " }
                }
            } | str join)
            let pad = ($max_len - ($p.val.name | str length) + 1)
            let padding = ("" | fill -c " " -w $pad -a l)
            print $"   ($green)($hc)($reset)($rest):($padding)($icons)"
        }
        print -n "Pick: "
        let choice = (input --numchar 1 --suppress-output | str downcase)
        let preset = ($presets | get -o $choice | default ($presets | get -o "default"))
        if ($preset | is-empty) {
            tmux new -A -s ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-') nu; exit
        }
        let dir = $preset.dir
        let session = ($dir | path basename | str replace --regex '^\.' '' | str replace --all '.' '-')
        if (tmux has-session -t $session | complete | get exit_code) == 0 {
            clear; tmux attach-session -t $session; exit
        }
        let windows = $preset.windows
        if ($windows | length) == 0 {
            tmux new-session -d -s $session -c $dir; clear; tmux attach-session -t $session; exit
        }
        let first = ($windows | first)
        tmux new-session -d -s $session -c $dir -n ($first | first)
        tmux send-keys -t $"($session):1.1" $"($first | first)" Enter
        mut pane = "1"
        for app in ($first | skip 1) {
            let geo = (tmux display-message -p -t $"($session):1.($pane)" '#{pane_width} #{pane_height}')
            let dims = ($geo | split row " ")
            let w = ($dims | first | into int)
            let h = ($dims | last | into int)
            if $w > $h * 2 {
                $pane = (tmux split-window -h -t $"($session):1.($pane)" -c $dir -P -F '#{pane_index}' | str trim)
            } else {
                $pane = (tmux split-window -v -t $"($session):1.($pane)" -c $dir -P -F '#{pane_index}' | str trim)
            }
            tmux send-keys -t $"($session):1.($pane)" $"$app" Enter
        }
        mut win_idx = 2
        for win_def in ($windows | skip 1) {
            if ($win_def | length) == 0 {
                tmux new-window -t $session -c $dir
            } else {
                tmux new-window -t $session -c $dir -n ($win_def | first)
                tmux send-keys -t $"($session):($win_idx).1" $"($win_def | first)" Enter
                mut pane = "1"
                for app in ($win_def | skip 1) {
                    let geo = (tmux display-message -p -t $"($session):($win_idx).($pane)" '#{pane_width} #{pane_height}')
                    let dims = ($geo | split row " ")
                    let w = ($dims | first | into int)
                    let h = ($dims | last | into int)
                    if $w > $h * 2 {
                        $pane = (tmux split-window -h -t $"($session):($win_idx).($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                    } else {
                        $pane = (tmux split-window -v -t $"($session):($win_idx).($pane)" -c $dir -P -F '#{pane_index}' | str trim)
                    }
                    tmux send-keys -t $"($session):($win_idx).($pane)" $"$app" Enter
                }
            }
            $win_idx += 1
        }
        tmux select-window -t $"($session):1"
        clear; tmux attach-session -t $session; exit
    } else if $has_zellij {
        $env.DOTFILES_SHELL_PICKED = "1"; clear; $env.SHELL = "nu"; zellij attach -c ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-'); clear; exit
    }
}

# --- Dependency installer ---
let install_script = $"($env.HOME)/.local/share/zsh/install-dependencies.sh"
if ($install_script | path exists) {
    ^$install_script
}
