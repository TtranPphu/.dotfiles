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

# LLM provider environment variables
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
mkdir ~/.cache/nu
if (which starship | length) > 0 {
    starship init nu | save -f ~/.cache/nu/starship.nu
    $env.STARSHIP_CONFIG = $"($env.HOME)/.config/starship/starship.toml"
    $env.STARSHIP_SHELL = "nu"
} else {
    "" | save -f ~/.cache/nu/starship.nu
}

# Generate zoxide init if needed (sourced in config.nu for top-level access)
if (which zoxide | length) > 0 {
    zoxide init nushell | save -f ~/.cache/nu/zoxide.nu
} else {
    "" | save -f ~/.cache/nu/zoxide.nu
}

# Generate aliases.nu with tool conditionals (written directly to avoid stow-managed paths)
mut _aliases = [
    "# Tool aliases and enhancements"
    ""
    "def pg [...args: string] { if ($args | length) > 0 { ^$env.PAGER ...$args } else { $in | ^$env.PAGER } }"
]

if (which eza | length) > 0 {
    $_aliases = ($_aliases | append [
        ""
        "alias la = eza -lah --icons --group"
        "alias lt = eza -lah --tree --icons --ignore-glob=.git --group"
        "alias ld = eza -lah --only-dirs --icons --group"
        "alias lf = eza -lah --only-files --icons --group"
        "alias lh = eza -lad .* --icons --group"
        "def lap [...args: string] { eza -lah --icons --group --color=always ...$args | ^$env.PAGER }"
        "def ltp [...args: string] { eza -lah --tree --icons --ignore-glob=.git --group --color=always ...$args | ^$env.PAGER }"
        "def ldp [...args: string] { eza -lah --only-dirs --icons --group --color=always ...$args | ^$env.PAGER }"
        "def lfp [...args: string] { eza -lah --only-files --icons --group --color=always ...$args | ^$env.PAGER }"
        "def lhp [...args: string] { eza -lad .* --icons --group --color=always ...$args | ^$env.PAGER }"
    ])
}

if (which batcat | length) > 0 {
    $_aliases = ($_aliases | append ["", "alias cat = batcat"])
} else if (which bat | length) > 0 {
    $_aliases = ($_aliases | append ["", "alias cat = bat"])
}

if (which rg | length) > 0 {
    $_aliases = ($_aliases | append ["", "alias grep = rg"])
}

if (which nvim | length) > 0 {
    $_aliases = ($_aliases | append ["", "alias vi = nvim", "alias vim = nvim"])
}

if (which zoxide | length) > 0 {
    $_aliases = ($_aliases | append ["", "alias cd = __zoxide_z"])
}

$_aliases = ($_aliases | append ["", "alias gs = git status", ""])
$_aliases = ($_aliases | append [
    "alias g = git",
    "alias ga = git add",
    "alias gaa = git add --all",
    "alias gapa = git add --patch",
    "alias gau = git add --update",
    "alias gb = git branch",
    "alias gba = git branch -a",
    "alias gbd = git branch -d",
    "alias gbD = git branch -D",
    "alias gbl = git blame -b -w",
    "alias gbnm = git branch --no-merged",
    "alias gbr = git branch --remote",
    "alias gbs = git bisect",
    "alias gbsb = git bisect bad",
    "alias gbsg = git bisect good",
    "alias gbsr = git bisect reset",
    "alias gbss = git bisect start",
    "alias gc = git commit -v",
    "alias gc! = git commit -v --amend",
    "alias gca = git commit -v -a",
    "alias gca! = git commit -v -a --amend",
    "alias gcam = git commit -a -m",
    "alias gcmsg = git commit -m",
    "alias gcb = git checkout -b",
    "alias gcf = git config --list",
    "alias gcl = git clone --recurse-submodules",
    "alias gclean = git clean -id",
    "alias gclf = git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules",
    "alias gcd = git checkout develop",
    "alias gco = git checkout",
    "alias gcount = git shortlog -sn",
    "alias gcp = git cherry-pick",
    "alias gcpa = git cherry-pick --abort",
    "alias gcpc = git cherry-pick --continue",
    "alias gd = git diff",
    "alias gdca = git diff --cached",
    "alias gdcw = git diff --cached --word-diff",
    "alias gds = git diff --staged",
    "alias gdw = git diff --word-diff",
    "alias gf = git fetch",
    "alias gfa = git fetch --all --tags --prune",
    "alias gfo = git fetch origin",
    "alias gg = git gui citool",
    "alias gga = git gui citool --amend",
    "alias ggf = git push --force origin HEAD:HEAD",
    "alias ggfl = git push --force-with-lease origin HEAD:HEAD",
    "alias ggl = git pull origin HEAD",
    "alias ggp = git push origin HEAD",
    "alias ggpull = git pull origin",
    "alias ggpush = git push origin",
    "alias ggsup = git branch --set-upstream-to origin/HEAD",
    "alias ghh = git help",
    "alias gl = git pull",
    "alias glg = git log --stat",
    "alias glgp = git log --stat -p",
    "alias glgg = git log --graph",
    "alias glgga = git log --graph --decorate --all",
    "alias glgm = git log --graph --max-count=10",
    "alias glo = git log --oneline --decorate",
    "alias gluc = git pull upstream HEAD",
    "alias glum = git pull upstream main",
    "alias glod = git log --graph --format=\"%C(auto)%h %d %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\"",
    "alias glods = git log --graph --format=\"%C(auto)%h %d %s %Cgreen(%ad) %C(bold blue)<%an>%Creset\" --date=short",
    "alias glol = git log --graph --format=\"%C(auto)%h %d %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\"",
    "alias glola = git log --graph --format=\"%C(auto)%h %d %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --all",
    "alias glols = git log --graph --format=\"%C(auto)%h %d %s %Cgreen(%ar) %C(bold blue)<%an>%Creset\" --stat",
    "alias glog = git log --oneline --decorate --graph",
    "alias gloga = git log --oneline --decorate --graph --all",
    "alias gap = git apply",
    "alias gapt = git apply --3way",
    "alias gcB = git checkout -B",
    "alias gcm = git checkout main",
    "alias gcn = git commit -v --no-edit",
    "alias gcn! = git commit -v --no-edit --amend",
    "alias gcor = git checkout --recurse-submodules",
    "alias gcs = git commit -S",
    "alias gcsm = git commit -s -m",
    "alias gcssm = git commit -S -s -m",
    "alias gcfu = git commit --fixup",
    "alias gdct = git describe --tags --abbrev=0",
    "alias gdt = git diff-tree --no-commit-id -r",
    "alias gdup = git diff @{upstream}",
    "alias gm = git merge",
    "alias gma = git merge --abort",
    "alias gmc = git merge --continue",
    "alias gmff = git merge --ff-only",
    "alias gmom = git merge origin/master",
    "alias gms = git merge --squash",
    "alias gmtl = git mergetool --no-prompt",
    "alias gmum = git merge upstream/master",
    "alias gp = git push",
    "alias gpd = git push --dry-run",
    "alias gpf = git push --force-with-lease",
    "alias gpf! = git push --force",
    "alias gpod = git push origin --delete",
    "alias gpr = git pull --rebase",
    "alias gpra = git pull --rebase --autostash",
    "alias gprav = git pull --rebase --autostash -v",
    "alias gprom = git pull --rebase origin master",
    "alias gpsup = git push --set-upstream origin HEAD",
    "alias gpu = git push upstream",
    "alias gpv = git push -v",
    "alias gr = git remote",
    "alias gra = git remote add",
    "alias grb = git rebase",
    "alias grba = git rebase --abort",
    "alias grbc = git rebase --continue",
    "alias grbi = git rebase -i",
    "alias grbm = git rebase master",
    "alias grbs = git rebase --skip",
    "alias grev = git revert",
    "alias greva = git revert --abort",
    "alias grevc = git revert --continue",
    "alias grf = git reflog",
    "alias grh = git reset HEAD",
    "alias grhh = git reset HEAD --hard",
    "alias grhk = git reset HEAD --keep",
    "alias grhs = git reset HEAD --soft",
    "alias grm = git rm",
    "alias grmc = git rm --cached",
    "alias grmv = git remote rename",
    "alias grrm = git remote remove",
    "alias groh = git reset origin/HEAD --hard",
    "alias grs = git reset",
    "alias grset = git remote set-url",
    "alias grss = git restore --source",
    "alias grst = git restore --staged",
    "def grt [] { cd (git rev-parse --show-toplevel) }",
    "alias gru = git reset --",
    "alias grup = git remote update",
    "alias grv = git remote -v",
    "alias gsb = git status -sb",
    "alias gsh = git show",
    "alias gsi = git submodule init",
    "alias gsps = git show --pretty=short --show-signature",
    "alias gsr = git svn rebase",
    "alias gss = git status -s",
    "alias gst = git status",
    "alias gsta = git stash push",
    "alias gstaa = git stash apply",
    "alias gstall = git stash --all",
    "alias gstc = git stash clear",
    "alias gstd = git stash drop",
    "alias gstl = git stash list",
    "alias gstp = git stash pop",
    "alias gsts = git stash show -p",
    "alias gstu = git stash push --include-untracked",
    "alias gsu = git submodule update",
    "alias gsw = git switch",
    "alias gswc = git switch -c",
    "alias gswd = git switch develop",
    "alias gswm = git switch main",
    "alias gta = git tag -a",
    "alias gts = git tag -s",
    "def gtv [] { git tag | ^sort -V }",
    "alias gtl = git tag -l",
    "alias gunignore = git update-index --no-assume-unchanged",
    "alias gunwip = git reset HEAD~",
    "alias gup = git pull --rebase",
    "alias gupa = git pull --rebase --autostash",
    "alias gupav = git pull --rebase --autostash -v",
    "alias gupom = git pull --rebase origin master",
    "alias gv = git --version",
    "alias gwch = git whatchanged -p --abbrev-commit --pretty=medium",
    "alias gwip = git add -A",
    "def gwipe [] { git reset --hard; git clean -df }",
    "alias gwt = git worktree",
    "alias gwta = git worktree add",
    "alias gwtls = git worktree list",
    "alias gwtmv = git worktree move",
    "alias gwtrm = git worktree remove"
])

$_aliases | str join (char newline) | save -f ~/.cache/nu/aliases.nu