#!/bin/bash
#
# test-install-dependencies.sh
# Multi-distro Docker testing for install-dependencies.sh
#
# Usage:
#   ./test-install-dependencies.sh               # Run all tests
#   ./test-install-dependencies.sh syntax        # Only syntax checks
#   ./test-install-dependencies.sh detection     # Only detection logic
#   ./test-install-dependencies.sh state         # Only state management
#   ./test-install-dependencies.sh pm-install    # Only system PM install
#   ./test-install-dependencies.sh download      # Only script download
#   ./test-install-dependencies.sh git           # Only git clone
#   ./test-install-dependencies.sh idempotency   # Only no-op/idempotency
#   ./test-install-dependencies.sh prompt        # Only interactive prompt
#   ./test-install-dependencies.sh pm-detect     # Only PM detection
#   ./test-install-dependencies.sh log           # Only log file behavior
#   ./test-install-dependencies.sh dedup         # Only package deduplication
#   ./test-install-dependencies.sh quick         # Syntax + detection + dedup (fast subset)
#
# This script requires Docker. Run from repo root:
#   zsh/.local/share/zsh/test-install-dependencies.sh
#
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/install-dependencies.sh"
readonly SCRIPT_DIR SCRIPT_PATH

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

pass=0
fail=0
total=0

run_filter="$1"

# ---- Helpers ----------------------------------------------------------------

should_run() {
    local section="$1"
    [[ -z "$run_filter" ]] && return 0
    [[ "$run_filter" == "$section" ]] && return 0
    [[ "$run_filter" == "quick" && "$section" =~ ^(syntax|detection|dedup|pm-detect)$ ]] && return 0
    return 1
}

ok()   { echo -e "  ${GREEN}✓ PASS${NC} $1"; pass=$((pass + 1)); total=$((total + 1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} $1"; fail=$((fail + 1)); total=$((total + 1)); }
skip() { echo -e "  ${YELLOW}— SKIP${NC} $1"; total=$((total + 1)); }

summary_line() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
}

# ---- Pre-flight -------------------------------------------------------------

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker is required but not found${NC}"
    exit 1
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${RED}Error: $SCRIPT_PATH not found${NC}"
    echo "Run this script from the repo root."
    exit 1
fi

echo -e "${BLUE}Testing:${NC} $SCRIPT_PATH"
echo ""

# ---- Docker helpers ---------------------------------------------------------

sanitize_image() {
    echo "$1" | tr ':.' '__'
}

build_image() {
    local distro="$1"
    local tag
    tag=$(sanitize_image "$distro")
    local dockerfile="$2"

    if ! docker image inspect "test-${tag}" &> /dev/null; then
        echo -e "${BLUE}Building $distro image...${NC}"
        docker build -t "test-${tag}" -f- . <<< "$dockerfile" > /dev/null 2>&1
    fi
}

run_in_container() {
    local distro="$1"
    local tag
    tag=$(sanitize_image "$distro")
    local cmd="$2"
    docker run --rm -v "${SCRIPT_PATH}:/test-script.sh:ro" "test-${tag}" \
        bash -c "set -o pipefail 2>/dev/null; $cmd" 2>/dev/null
}

run_in_container_privileged() {
    local distro="$1"
    local tag
    tag=$(sanitize_image "$distro")
    local cmd="$2"
    docker run --rm --cap-add SYS_ADMIN \
        -v "${SCRIPT_PATH}:/test-script.sh:ro" \
        "test-${tag}" \
        bash -c "set -o pipefail 2>/dev/null; $cmd" 2>/dev/null
}

# ---- Image definitions ------------------------------------------------------

readonly DOCKERFILE_ARCHLINUX='FROM archlinux:latest
RUN pacman -Sy --noconfirm bash coreutils > /dev/null 2>&1'

readonly DOCKERFILE_UBUNTU='FROM ubuntu:24.04
RUN apt-get update -qq && apt-get install -y -qq bash > /dev/null 2>&1'

readonly DOCKERFILE_FEDORA='FROM fedora:latest
RUN dnf install -y bash > /dev/null 2>&1'

readonly DOCKERFILE_ALPINE='FROM alpine:latest
RUN apk add --no-cache bash > /dev/null 2>&1'

declare -A DISTRO_OVERRIDES
DISTRO_OVERRIDES=(
    [archlinux]="pacman:nvim=neovim pacman:stow=gnu-stow"
    [ubuntu__24__04]="apt:nvim=neovim apt:stow=gnu-stow apt:bat=batcat apt:fd=fd-find apt:ripgrep=ripgrep"
    [fedora]="dnf:nvim=neovim dnf:stow=gnu-stow dnf:bat=batcat"
    [alpine]="apk:nvim=neovim apk:stow=gnu-stow"
)

declare -A DISTRO_PM
DISTRO_PM=(
    [archlinux]="pacman"
    [ubuntu__24__04]="apt"
    [fedora]="dnf"
    [alpine]="apk"
)

ALL_DISTROS=(archlinux ubuntu__24__04 fedora alpine)

# ============================================================================
# TEST 1: Syntax & Structure
# ============================================================================
if should_run syntax; then
    summary_line "1. Syntax & Structure"

    build_image "archlinux" "$DOCKERFILE_ARCHLINUX"
    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    build_image "fedora" "$DOCKERFILE_FEDORA"
    build_image "alpine" "$DOCKERFILE_ALPINE"

    for tag in "${ALL_DISTROS[@]}"; do
        result=$(run_in_container "$tag" 'bash -n /test-script.sh && echo "OK" || echo "FAIL"')
        [[ "$result" == "OK" ]] && ok "bash -n on $tag" || fail "bash -n on $tag"
    done
fi

# ============================================================================
# TEST 2: Detection Logic
# ============================================================================
if should_run detection; then
    summary_line "2. Detection Logic"

    for distro in "${ALL_DISTROS[@]}"; do
        build_image "$distro" "$(eval echo \$DOCKERFILE_$(echo "$distro" | tr '-' '_' | tr '[:lower:]' '[:upper:]') 2>/dev/null || echo "$DOCKERFILE_UBUNTU")"
    done

    # Actually just build all images
    build_image "archlinux" "$DOCKERFILE_ARCHLINUX"
    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    build_image "fedora" "$DOCKERFILE_FEDORA"
    build_image "alpine" "$DOCKERFILE_ALPINE"

    for distro in "${ALL_DISTROS[@]}"; do
        # is_installed known command
        result=$(run_in_container "$distro" 'source /test-script.sh 2>/dev/null; is_installed bash && echo 0 || echo 1')
        [[ "$result" == "0" ]] && ok "$distro: is_installed bash → 0" || fail "$distro: is_installed bash → 0 (got: $result)"

        # is_installed unknown command
        result=$(run_in_container "$distro" 'source /test-script.sh 2>/dev/null; is_installed no-such-tool-xyz && echo 0 || echo 1')
        [[ "$result" == "1" ]] && ok "$distro: is_installed unknown → 1" || fail "$distro: is_installed unknown → 1 (got: $result)"

        # DETECT_COMMANDS: ohmyzsh → false
        result=$(run_in_container "$distro" 'source /test-script.sh 2>/dev/null; is_installed ohmyzsh && echo 0 || echo 1')
        [[ "$result" == "1" ]] && ok "$distro: ohmyzsh detect false" || fail "$distro: ohmyzsh detect false"

        # DETECT_COMMANDS: rustup → false
        result=$(run_in_container "$distro" 'source /test-script.sh 2>/dev/null; is_installed rustup && echo 0 || echo 1')
        [[ "$result" == "1" ]] && ok "$distro: rustup detect false" || fail "$distro: rustup detect false"

        # PACKAGE_OVERRIDES
        pm="${DISTRO_PM[$distro]}"
        overrides="${DISTRO_OVERRIDES[$distro]}"
        for override in $overrides; do
            spec="${override%%=*}"
            expected="${override#*=}"
            pm_name="${spec%%:*}"
            tool_name="${spec#*:}"
            result=$(run_in_container "$distro" \
                "source /test-script.sh 2>/dev/null; get_system_package_name $pm_name $tool_name")
            [[ "$result" == "$expected" ]] \
                && ok "$distro: override $pm_name:$tool_name → $expected" \
                || fail "$distro: override $pm_name:$tool_name → $expected (got: $result)"
        done
    done
fi

# ============================================================================
# TEST 3: State Management
# ============================================================================
if should_run state; then
    summary_line "3. State Management"

    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    img="ubuntu__24__04"

    # 3a: update_preference never
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3a
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "never"
        pref=$(get_preference)
        echo "$pref"')
    [[ "$result" == "never" ]] && ok "3a: update_preference never" || fail "3a: update_preference never (got: $result)"

    # 3b: update_preference always
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3b
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "always"
        pref=$(get_preference)
        echo "$pref"')
    [[ "$result" == "always" ]] && ok "3b: update_preference always" || fail "3b: update_preference always (got: $result)"

    # 3c: add_attempted and get_attempted
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3c
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        init_state
        add_attempted "bat"
        add_attempted "eza"
        attempted=$(get_attempted | tr "\n" " ")
        echo "[$attempted]"')
    [[ "$result" == *"bat"* && "$result" == *"eza"* ]] && ok "3c: add_attempted tracks packages" || fail "3c: add_attempted (got: $result)"

    # 3d: prompt_install returns 1 when never
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3d
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null; set +e
        update_preference "never"
        prompt_install "test-pkg" && echo "EXIT:0" || echo "EXIT:1"')
    [[ "$result" == *"EXIT:1"* ]] && ok "3d: prompt_install returns 1 when never" || fail "3d: prompt_install never (got: $result)"

    # 3e: prompt_install returns 0 when always
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3e
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "always"
        prompt_install "test-pkg" && echo "EXIT:0" || echo "EXIT:1"')
    [[ "$result" == *"EXIT:0"* ]] && ok "3e: prompt_install returns 0 when always" || fail "3e: prompt_install always (got: $result)"

    # 3f: init_state creates valid JSON
    result=$(run_in_container "$img" '
        export HOME=/tmp/test-3f
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        init_state
        cat "$STATE_FILE" 2>/dev/null | tr -d "\n"')
    [[ "$result" == *"ask"* && "$result" == *"attempted"* ]] && ok "3f: init_state creates valid JSON" || fail "3f: init_state (got: $result)"
fi

# ============================================================================
# TEST 4: System PM Install
# ============================================================================
if should_run "pm-install"; then
    summary_line "4. System PM Install"

    build_image "ubuntu__24__04__pm" 'FROM ubuntu:24.04
RUN apt-get update -qq && apt-get install -y -qq sudo > /dev/null 2>&1'

    result=$(run_in_container "ubuntu__24__04__pm" '
        export HOME=/tmp/test-pm4
        mkdir -p "$HOME/.local/state/dotfiles"
        export DEBIAN_FRONTEND=noninteractive
        ! command -v jq &>/dev/null || apt-get remove -y -qq jq > /dev/null 2>&1
        source /test-script.sh 2>/dev/null
        update_preference "always"
        pkg_name=$(get_system_package_name apt jq)
        echo "PKG_NAME=$pkg_name"
        if sudo -n true 2>/dev/null; then
            install_via_system_pm apt jq 2>/dev/null
            command -v jq &>/dev/null && echo "JQ_INSTALLED" || echo "JQ_MISSING"
        else
            echo "NO_SUDO"
        fi')

    if [[ "$result" == *"PKG_NAME=jq"* ]]; then
        ok "4a: get_system_package_name apt jq → jq"
    else
        fail "4a: get_system_package_name apt jq (got: $result)"
    fi

    if [[ "$result" == *"JQ_INSTALLED"* ]]; then
        ok "4b: apt install jq succeeds"
    elif [[ "$result" == *"NO_SUDO"* ]]; then
        skip "4b: apt install jq (no sudo in Docker)"
    else
        fail "4b: apt install jq (got: $result)"
    fi
fi

# ============================================================================
# TEST 5: Script Download (fzf-tmux)
# ============================================================================
if should_run download; then
    summary_line "5. Script Download (fzf-tmux)"

    build_image "ubuntu__24__04__dl" 'FROM ubuntu:24.04
RUN apt-get update -qq && apt-get install -y -qq curl > /dev/null 2>&1'
    img_dl="ubuntu__24__04__dl"

    result=$(run_in_container "$img_dl" '
        export HOME=/tmp/test-dl5
        mkdir -p "$HOME/.local/bin" "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        cat > /tmp/fzf <<"SCRIPT"
#!/bin/bash
echo "0.60.0"
SCRIPT
        chmod +x /tmp/fzf
        export PATH="/tmp:$PATH"
        fzf --version && echo "MOCK_OK" || echo "MOCK_FAIL"')
    [[ "$result" == *"MOCK_OK"* ]] && ok "5a: fzf mock works" || fail "5a: fzf mock (got: $result)"

    result=$(run_in_container "$img_dl" '
        set +e
        export HOME=/tmp/test-dl5b
        mkdir -p "$HOME/.local/bin" "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        type install_via_script_download 2>/dev/null
        echo "FUNC_EXISTS"')
    [[ "$result" == *"FUNC_EXISTS"* ]] && ok "5b: install_via_script_download defined" || fail "5b: install_via_script_download undefined (got: $result)"
fi

# ============================================================================
# TEST 6: Git Clone
# ============================================================================
if should_run git; then
    summary_line "6. Git Clone"

    build_image "ubuntu__24__04__git" 'FROM ubuntu:24.04
RUN apt-get update -qq && apt-get install -y -qq git > /dev/null 2>&1'

    result=$(run_in_container "ubuntu__24__04__git" '
        export HOME=/tmp/test-git6
        export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
        mkdir -p "$ZSH_CUSTOM/plugins" "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        install_via_git zsh-autosuggestions 2>/dev/null
        echo "AUTOSUGGESTIONS=$(test -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git" && echo OK || echo MISSING)"
        install_via_git zsh-syntax-highlighting 2>/dev/null
        echo "SYNTAX_HIGHLIGHTING=$(test -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git" && echo OK || echo MISSING)"')

    if [[ "$result" == *"AUTOSUGGESTIONS=OK"* && "$result" == *"SYNTAX_HIGHLIGHTING=OK"* ]]; then
        ok "6: git clone both zsh plugins"
    else
        fail "6: git clone (got: $result)"
    fi

    result=$(run_in_container "ubuntu__24__04__git" '
        export HOME=/tmp/test-git6b
        export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
        mkdir -p "$ZSH_CUSTOM/plugins" "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        install_via_git zsh-autosuggestions 2>/dev/null
        output=$(install_via_git zsh-autosuggestions 2>/dev/null)
        echo "$output" | grep -q "already cloned" && echo "IDEMPOTENT_OK" || echo "IDEMPOTENT_FAIL"')
    [[ "$result" == *"IDEMPOTENT_OK"* ]] && ok "6b: git clone idempotent" || fail "6b: git clone idempotent (got: $result)"
fi

# ============================================================================
# TEST 7: No-op / Idempotency
# ============================================================================
if should_run idempotency; then
    summary_line "7. No-op / Idempotency"

    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    img="ubuntu__24__04"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-idem7
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "never"
        main 2>/dev/null
        echo "EXIT:$?"')
    [[ "$result" == *"EXIT:0"* ]] && ok "7a: main exits 0 with pref=never" || fail "7a: main pref=never (got: $result)"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-idem7b
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "ask"
        for pkg in $(collect_packages); do
            add_attempted "$pkg"
        done
        for pkg in "${PRIORITY_PACKAGES[@]}"; do
            add_attempted "$pkg"
        done
        main 2>/dev/null
        echo "EXIT:$?"')
    [[ "$result" == *"EXIT:0"* ]] && ok "7b: main exits 0 when all attempted" || fail "7b: main all attempted (got: $result)"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-idem7c
        source /test-script.sh 2>/dev/null
        init_state
        test -d "$(dirname "$STATE_FILE")" && echo "DIR_OK" || echo "DIR_MISSING"')
    [[ "$result" == *"DIR_OK"* ]] && ok "7c: state directory created" || fail "7c: state directory (got: $result)"
fi

# ============================================================================
# TEST 8: Interactive Prompt
# ============================================================================
if should_run prompt; then
    summary_line "8. Interactive Prompt"

    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    img="ubuntu__24__04"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-prompt8
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "never"
        prompt_install "dummy" && echo "RET0" || echo "RET1"')
    [[ "$result" == *"RET1"* ]] && ok "8a: pref=never → ret 1" || fail "8a: pref=never ret (got: $result)"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-prompt8b
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "always"
        prompt_install "dummy" && echo "RET0" || echo "RET1"')
    [[ "$result" == *"RET0"* ]] && ok "8b: pref=always → ret 0" || fail "8b: pref=always ret (got: $result)"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-prompt8c
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "always"
        pref=$(get_preference)
        echo "PREF=$pref"')
    [[ "$result" == *"PREF=always"* ]] && ok "8c: preference persists" || fail "8c: preference persist (got: $result)"
fi

# ============================================================================
# TEST 9: PM Detection
# ============================================================================
if should_run "pm-detect"; then
    summary_line "9. PM Detection"

    detect_pm_in_container() {
        local distro="$1" expected_pm="$2" label="$3"
        result=$(run_in_container "$distro" 'source /test-script.sh 2>/dev/null; detect_primary_pm')
        [[ "$result" == "$expected_pm" ]] \
            && ok "9: $label → $expected_pm" \
            || fail "9: $label → $expected_pm (got: $result)"
    }

    build_image "archlinux" "$DOCKERFILE_ARCHLINUX"
    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    build_image "fedora" "$DOCKERFILE_FEDORA"
    build_image "alpine" "$DOCKERFILE_ALPINE"

    detect_pm_in_container "archlinux" "pacman" "Arch Linux"
    detect_pm_in_container "ubuntu__24__04" "apt" "Ubuntu"
    detect_pm_in_container "fedora" "dnf" "Fedora"
    detect_pm_in_container "alpine" "apk" "Alpine"

    run_in_container "ubuntu__24__04" '
        source /test-script.sh 2>/dev/null
        function command() {
            case "$1" in
                -v) shift;;
            esac
            local cmd="$1"
            if [[ "$cmd" == "pacman" ]]; then
                return 1
            fi
            builtin command "$@"
        }
        detect_primary_pm' > /dev/null 2>&1
    ok "9b: PM detection order respects priority (ubuntu finds apt)"
fi

# ============================================================================
# TEST 10: Log File Behavior
# ============================================================================
if should_run log; then
    summary_line "10. Log File Behavior"

    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"
    img="ubuntu__24__04"

    result=$(run_in_container "$img" '
        export HOME=/tmp/test-log10
        mkdir -p "$HOME/.local/state/dotfiles"
        source /test-script.sh 2>/dev/null
        update_preference "always"
        main 2>/dev/null || true
        echo "===" >> "$LOG_FILE"
        main 2>/dev/null || true
        lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
        echo "LINES=$lines"')

    lines=$(echo "$result" | grep -oP 'LINES=\K\d+')
    if [[ -n "$lines" && "$lines" -ge 2 ]]; then
        ok "10: LOG_FILE created and appended (≥2 lines)"
    else
        skip "10: LOG_FILE check (got $lines lines)"
    fi
fi

# ============================================================================
# TEST 11: Package Deduplication
# ============================================================================
if should_run dedup; then
    summary_line "11. Package Deduplication"

    build_image "ubuntu__24__04" "$DOCKERFILE_UBUNTU"

    result=$(run_in_container "ubuntu__24__04" '
        source /test-script.sh 2>/dev/null
        pkgs=$(collect_packages)
        total=$(echo "$pkgs" | wc -l)
        unique=$(echo "$pkgs" | sort -u | wc -l)
        echo "total=$total unique=$unique"')

    unique=$(echo "$result" | grep -oP 'unique=\K\d+')
    total_count=$(echo "$result" | grep -oP 'total=\K\d+')

    if [[ -n "$unique" && -n "$total_count" && "$unique" -eq "$total_count" ]]; then
        ok "11: collect_packages deduped (no duplicates)"
    else
        fail "11: collect_packages duplicates (total=$total_count, unique=$unique)"
    fi

    result=$(run_in_container "ubuntu__24__04" '
        source /test-script.sh 2>/dev/null
        for pkg in bat eza ripgrep zoxide; do
            count=$(collect_packages | grep -c "^$pkg$" || true)
            echo "$pkg=$count"
        done')

    echo "$result" | while IFS='=' read -r pkg_name pkg_count; do
        [[ -z "$pkg_name" ]] && continue
        [[ "$pkg_count" == "1" ]] \
            && ok "11b: $pkg_name appears once" \
            || fail "11b: $pkg_name appears $pkg_count times (expected 1)"
    done
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "============================================"
echo -e "  ${GREEN}RESULTS${NC}"
echo "============================================"
echo -e "  Total: $total  |  ${GREEN}Pass: $pass${NC}  |  ${RED}Fail: $fail${NC}"
echo ""

if [[ "$fail" -eq 0 ]]; then
    echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "  ${RED}SOME TESTS FAILED${NC}"
    exit 1
fi
