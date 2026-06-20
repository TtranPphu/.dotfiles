#!/bin/bash

# Installation script for dotfiles dependencies
# Detects package managers and attempts to install missing tools
# Tracks user preferences and skips installation based on previous choices

set -e

# Colors for output
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # No Color

# State file to track user preferences
STATE_FILE="$HOME/.local/state/dotfiles/install-state.json"
STATE_DIR="$(dirname "$STATE_FILE")"

# Log file for installation output
LOG_FILE="$HOME/.local/state/dotfiles/install.log"
LOG_DIR="$(dirname "$LOG_FILE")"

# ---------------------------------------------------------------------------
# Package category arrays
# ---------------------------------------------------------------------------

# Priority packages — custom curl | sh + setup logic, installed FIRST
declare -a PRIORITY_PACKAGES=(
  rustup
  uv
  ohmyzsh
)

# Cargo-installable packages (tried before system PM)
declare -a CARGO_PACKAGES=(
  bat
  eza
  starship
  fd
  ripgrep
  aichat
  zoxide
  zellij
  nu
  argc
  llmfit
)

# System package manager packages (pacman > apt > dnf > zypper > apk)
declare -a SYSTEM_PACKAGES=(
  tmux
  nvim
  zsh
  yazi
  gdu
  fzf
  lazygit
  lazydocker
  ollama
  stow
  jq
  bat
  eza
  ripgrep
  zoxide
  opencode
)

# Secondary package manager (yay > paru > brew when not primary)
declare -a SECONDARY_PACKAGES=(
)

# Packages installed via `uv tool install`
declare -a UV_PACKAGES=(
  llmfit
  vllm
)

# Packages installed via npm
declare -a NPM_PACKAGES=(
  neovim
  opencode-ai
)

# Packages installed via curl | sh (pipe)
declare -a SCRIPT_INSTALL_PACKAGES=(
  ollama
)

# Packages downloaded as scripts to ~/.local/bin
declare -a SCRIPT_DOWNLOAD_PACKAGES=(
  fzf-tmux
)

# Packages installed via git clone
declare -a GIT_PACKAGES=(
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# ---------------------------------------------------------------------------
# Auxiliary arrays
# ---------------------------------------------------------------------------

# Alternative command names for tools on different systems
declare -A COMMAND_NAMES=(
  [bat]="batcat"
  [ripgrep]="rg"
)

# Custom detection commands for tools not found via command -v.
# Value is a command/eval string that returns 0 if installed.
declare -A DETECT_COMMANDS=(
  [ohmyzsh]="test -d \"\$HOME/.oh-my-zsh\""
  [rustup]="command -v rustup &>/dev/null || test -x \"\$HOME/.rustup/rustup-init\""
  [uv]="command -v uv &>/dev/null || test -x \"\$HOME/.local/bin/uv\""
)

# Per-package-manager package name overrides.
# Key format: "<pm>:<tool>"
declare -A PACKAGE_OVERRIDES=(
  [apt:bat]="batcat"
  [apt:fd]="fd-find"
  [apt:nvim]="neovim"
  [apt:stow]="gnu-stow"
  [apt:ripgrep]="ripgrep"
  [dnf:bat]="batcat"
  [dnf:nvim]="neovim"
  [dnf:stow]="gnu-stow"
  [pacman:nvim]="neovim"
  [pacman:stow]="gnu-stow"
  [zypper:bat]="batcat"
  [zypper:nvim]="neovim"
  [zypper:stow]="gnu-stow"
  [apk:nvim]="neovim"
  [apk:stow]="gnu-stow"
  [brew:nvim]="neovim"
  [brew:stow]="gnu-stow"
  [brew:ripgrep]="ripgrep"
  [brew:opencode]="anomalyco/tap/opencode"
)

# ---------------------------------------------------------------------------
# Mapping from package name → metadata for git/special installs
# ---------------------------------------------------------------------------

# Git clone targets: package → "url|dest_dir"
declare -A GIT_SOURCES=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions|${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting|${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
)

# Script download URLs. Use {version} as a placeholder — it's resolved
# from the version of the matching parent tool (e.g. fzf-tmux → fzf).
declare -A SCRIPT_DOWNLOAD_URLS=(
  [fzf-tmux]="https://raw.githubusercontent.com/junegunn/fzf/v{version}/bin/fzf-tmux"
)

# Script install (pipe) URLs — fetched and piped through sh.
# Use {version} as a placeholder, resolved from the matching parent tool.
declare -A SCRIPT_INSTALL_URLS=(
  [ollama]="https://ollama.com/install.sh"
)

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# Resolve the command name(s) to check for a given package
get_command_names() {
  local pkg=$1
  local alias=${COMMAND_NAMES[$pkg]}
  if [ -n "$alias" ]; then
    echo "$pkg $alias"
  else
    echo "$pkg"
  fi
}

# Initialize state file
init_state() {
  if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$STATE_DIR"
    cat > "$STATE_FILE" <<'EOF'
{
  "preference": "ask",
  "attempted": []
}
EOF
  fi
}

# Get user preference from state
get_preference() {
  init_state
  if command -v jq &> /dev/null; then
    jq -r '.preference' "$STATE_FILE" 2>/dev/null || echo "ask"
  else
    grep -oP '"preference":\s*"\K[^"]+' "$STATE_FILE" || echo "ask"
  fi
}

# Get list of attempted installations
get_attempted() {
  init_state
  if command -v jq &> /dev/null; then
    jq -r '.attempted[]' "$STATE_FILE" 2>/dev/null || true
  else
    grep -oP '"attempted":\s*\[\K[^\]]*' "$STATE_FILE" | tr ',' '\n' | sed 's/"//g' | sed 's/^ *//;s/ *$//' || true
  fi
}

# Update state preference
update_preference() {
  local pref=$1
  init_state
  if command -v jq &> /dev/null; then
    jq ".preference = \"$pref\"" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  else
    sed -i "s/\"preference\":[^,]*/\"preference\": \"$pref\"/" "$STATE_FILE"
  fi
}

# Add to attempted list
add_attempted() {
  local package=$1
  init_state
  if command -v jq &> /dev/null; then
    jq ".attempted += [\"$package\"]" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  else
    local attempted
    attempted=$(grep -oP '"attempted":\s*\[\K[^\]]*' "$STATE_FILE" || echo "")
    if [ -z "$attempted" ]; then
      sed -i "s/\"attempted\": \[\]/\"attempted\": [\"$package\"]/" "$STATE_FILE"
    else
      sed -i "s/\"attempted\": \[/\"attempted\": [\"$package\", /" "$STATE_FILE"
    fi
  fi
}

# Detect primary package manager
detect_primary_pm() {
  if command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v apt-get &> /dev/null; then
    echo "apt"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  elif command -v zypper &> /dev/null; then
    echo "zypper"
  elif command -v apk &> /dev/null; then
    echo "apk"
  elif command -v brew &> /dev/null; then
    echo "brew"
  else
    echo "unknown"
  fi
}

# Detect secondary package manager (AUR helper or brew when not primary)
detect_secondary_pm() {
  local primary=$1
  if command -v yay &> /dev/null; then
    echo "yay"
  elif command -v paru &> /dev/null; then
    echo "paru"
  elif [ "$primary" != "brew" ] && command -v brew &> /dev/null; then
    echo "brew"
  else
    echo ""
  fi
}

# Get system package name for a tool, checking overrides then defaulting to tool key
get_system_package_name() {
  local pm=$1
  local tool=$2
  local override_key="${pm}:${tool}"
  if [ -n "${PACKAGE_OVERRIDES[$override_key]}" ]; then
    echo "${PACKAGE_OVERRIDES[$override_key]}"
  else
    echo "$tool"
  fi
}

# Check if package is installed
is_installed() {
  local pkg=$1

  # Custom detection for non-command tools
  local detect=${DETECT_COMMANDS[$pkg]}
  if [ -n "$detect" ]; then
    eval "$detect" && return 0 || return 1
  fi

  local commands
  commands=$(get_command_names "$pkg")

  for cmd in $commands; do
    if command -v "$cmd" &> /dev/null; then
      return 0
    fi
  done
  return 1
}

# Collect all packages from every array (excluding priority — those are handled separately)
collect_packages() {
  (
    for pkg in "${CARGO_PACKAGES[@]}";              do echo "$pkg"; done
    for pkg in "${SYSTEM_PACKAGES[@]}";              do echo "$pkg"; done
    for pkg in "${SECONDARY_PACKAGES[@]}";           do echo "$pkg"; done
    for pkg in "${UV_PACKAGES[@]}";                  do echo "$pkg"; done
    for pkg in "${NPM_PACKAGES[@]}";                 do echo "$pkg"; done
    for pkg in "${SCRIPT_INSTALL_PACKAGES[@]}";      do echo "$pkg"; done
    for pkg in "${SCRIPT_DOWNLOAD_PACKAGES[@]}";     do echo "$pkg"; done
    for pkg in "${GIT_PACKAGES[@]}";                 do echo "$pkg"; done
  ) | sort -u
}

# Check if sudo is available
has_sudo() {
  sudo -n true 2>/dev/null
}

# Ask user to enable sudo
ask_sudo() {
  echo ""
  echo -e "${YELLOW}This operation requires sudo for package installation.${NC}"
  echo -e "Please provide your password: ${NC}"
  if sudo -v; then
    echo -e "${GREEN}Sudo credentials cached.${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}Failed to obtain sudo credentials.${NC}"
    echo ""
    echo -e "${YELLOW}To install missing tools manually, run:${NC}"
    echo -e "  ${BLUE}\$HOME/.local/share/zsh/install-dependencies.sh${NC}"
    echo ""
    return 1
  fi
}

# Prompt user for installation
prompt_install() {
  local pref
  pref=$(get_preference)
  local missing=$1

  case "$pref" in
    always)
      return 0
      ;;
    never)
      return 1
      ;;
    ask)
      echo -e "${BLUE}Missing packages detected: ${NC}$missing"
      echo -e "Install tools? (${BLUE}y${NC}es|${BLUE}n${NC}o|${BLUE}A${NC}lways|${BLUE}N${NC}ever): \c"

      local choice
      choice=$(bash -c 'read -rsn1 key; echo "$key"')

      case "$choice" in
        y)
          echo "y"
          return 0
          ;;
        n)
          echo "n"
          return 1
          ;;
        A)
          echo "A"
          update_preference "always"
          return 0
          ;;
        N)
          echo "N"
          update_preference "never"
          return 1
          ;;
        *)
          echo ""
          echo "Invalid choice. Skipping installation."
          return 1
          ;;
      esac
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Install methods
# ---------------------------------------------------------------------------

# Priority package install (custom logic, runs before everything else)
install_priority() {
  local pkg=$1

  case "$pkg" in
    rustup)
      echo -e "${YELLOW}↓${NC} Installing rustup..."
      if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1; then
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
        echo -e "${GREEN}✓${NC} rustup installed"
        return 0
      fi
      echo -e "${RED}✗${NC} Failed to install rustup"
      return 1
      ;;
    uv)
      echo -e "${YELLOW}↓${NC} Installing uv..."
      if curl -fsSL https://astral.sh/uv/install.sh | sh >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} uv installed"
        return 0
      fi
      echo -e "${RED}✗${NC} Failed to install uv"
      return 1
      ;;
    ohmyzsh)
      echo -e "${YELLOW}↓${NC} Installing oh-my-zsh..."
      if curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} oh-my-zsh installed"
        return 0
      fi
      echo -e "${RED}✗${NC} Failed to install oh-my-zsh"
      return 1
      ;;
  esac
  return 1
}

# Try installing via cargo
install_via_cargo() {
  local pkg=$1

  if ! command -v cargo &> /dev/null; then
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $pkg (cargo)..."
  if cargo install "$pkg" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg installed via cargo"
    return 0
  fi
  return 1
}

# Try installing via system package manager
install_via_system_pm() {
  local pm=$1
  local pkg=$2
  local package
  package=$(get_system_package_name "$pm" "$pkg")

  echo -e "${YELLOW}↓${NC} Installing $pkg ($pm: $package)..."
  case "$pm" in
    apt)
      if sudo apt-get update >> "$LOG_FILE" 2>&1 && sudo apt-get install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    dnf)
      if sudo dnf install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    brew)
      if brew install "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    zypper)
      if sudo zypper install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    apk)
      if sudo apk add "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
  esac
  echo -e "${RED}✗${NC} Failed to install $pkg via $pm"
  return 1
}

# Try installing via secondary package manager (yay/paru/brew)
install_via_secondary_pm() {
  local pm=$1
  local pkg=$2
  local package
  package=$(get_system_package_name "$pm" "$pkg")

  echo -e "${YELLOW}↓${NC} Installing $pkg ($pm: $package)..."
  case "$pm" in
    yay)
      if yay -S --noconfirm "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    paru)
      if paru -S --noconfirm "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
    brew)
      if brew install "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $pkg installed"
        return 0
      fi
      ;;
  esac
  echo -e "${RED}✗${NC} Failed to install $pkg via $pm"
  return 1
}

# Try installing via uv
install_via_uv() {
  local pkg=$1

  if ! command -v uv &> /dev/null; then
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $pkg (uv)..."
  if uv tool install "$pkg" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg installed via uv"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to install $pkg via uv"
    return 1
  fi
}

# Try installing via npm
install_via_npm() {
  local pkg=$1

  if ! command -v npm &> /dev/null; then
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $pkg (npm)..."
  if npm install -g "$pkg" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg installed via npm"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to install $pkg via npm"
    return 1
  fi
}

# Try installing via script pipe (curl | sh)
install_via_script_install() {
  local pkg=$1
  local url=${SCRIPT_INSTALL_URLS[$pkg]}

  [ -z "$url" ] && return 1

  # Resolve {version} placeholder from the parent tool (strip suffixes)
  local ver=""
  if [[ "$url" == *"{version}"* ]]; then
    local parent="${pkg%-*}"
    [ "$parent" = "$pkg" ] && return 1
    ver=$("$parent" --version 2>/dev/null | awk '{print $1}')
    [ -z "$ver" ] && return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $pkg..."

  local script
  if ! script=$(curl -fsSL "${url//\{version\}/v$ver}" 2>/dev/null); then
    [ -n "$ver" ] && script=$(curl -fsSL "${url//\{version\}/$ver}" 2>/dev/null) || { echo -e "${RED}✗${NC} Failed to install $pkg"; return 1; }
  fi

  if echo "$script" | sh >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg installed"
    return 0
  fi

  echo -e "${RED}✗${NC} Failed to install $pkg"
  return 1
}

# Try installing via script download (curl → ~/.local/bin)
install_via_script_download() {
  local pkg=$1
  local spec=${SCRIPT_DOWNLOAD_URLS[$pkg]}

  [ -z "$spec" ] && return 1

  local url="$spec"

  # Resolve {version} placeholder from the parent tool (strip suffixes)
  local ver=""
  if [[ "$url" == *"{version}"* ]]; then
    local parent="${pkg%-*}"
    [ "$parent" = "$pkg" ] && return 1
    ver=$("$parent" --version 2>/dev/null | awk '{print $1}')
    [ -z "$ver" ] && return 1
  fi

  local target="$HOME/.local/bin/$pkg"
  mkdir -p "$HOME/.local/bin"

  echo -e "${YELLOW}↓${NC} Installing $pkg (script download)..."
  if curl -fsSLo "$target" "${url//\{version\}/v$ver}" 2>/dev/null; then
    chmod +x "$target"
    echo -e "${GREEN}✓${NC} $pkg installed to $target"
    return 0
  fi

  # Retry with bare version (no v prefix)
  if [ -n "$ver" ] && curl -fsSLo "$target" "${url//\{version\}/$ver}" 2>/dev/null; then
    chmod +x "$target"
    echo -e "${GREEN}✓${NC} $pkg installed to $target"
    return 0
  fi

  echo -e "${RED}✗${NC} Failed to install $pkg"
  return 1
}

# Try installing via git clone
install_via_git() {
  local pkg=$1
  local spec=${GIT_SOURCES[$pkg]}

  [ -z "$spec" ] && return 1

  local url="${spec%%|*}"
  local dir="${spec#*|}"

  if [ -d "$dir" ]; then
    echo -e "${YELLOW}⊘${NC} $pkg already cloned at $dir"
    return 0
  fi

  mkdir -p "$(dirname "$dir")"

  echo -e "${YELLOW}↓${NC} Installing $pkg (git clone)..."
  if git clone --depth 1 "$url" "$dir" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg cloned to $dir"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to clone $pkg"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local pm
  pm=$(detect_primary_pm)

  if [ "$pm" = "unknown" ]; then
    echo -e "${RED}Error: Could not detect package manager${NC}"
    return 1
  fi

  local secondary_pm
  secondary_pm=$(detect_secondary_pm "$pm")

  # Ensure state and log directories exist
  mkdir -p "$STATE_DIR"
  mkdir -p "$LOG_DIR"
  init_state

  # Collect all packages and check which are missing
  local all_packages=()

  # Priority packages first
  for pkg in "${PRIORITY_PACKAGES[@]}"; do
    all_packages+=("$pkg")
  done

  # Then all other packages
  local remaining
  remaining=$(collect_packages)
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    all_packages+=("$pkg")
  done <<< "$remaining"

  # Check which are missing
  local missing=()
  for pkg in "${all_packages[@]}"; do
    if ! is_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  # If no missing tools, exit quietly
  if [ ${#missing[@]} -eq 0 ]; then
    return 0
  fi

  # Check if all missing tools were already attempted
  local attempted
  attempted=$(get_attempted)
  local all_attempted=true
  for pkg in "${missing[@]}"; do
    if ! echo "$attempted" | grep -q "^$pkg$"; then
      all_attempted=false
      break
    fi
  done

  local pref
  pref=$(get_preference)
  if [ "$all_attempted" = true ] && [ "$pref" = "ask" ]; then
    return 0
  fi

  # Prompt user for installation
  local missing_str
  missing_str=$(printf '%s, ' "${missing[@]}" | sed 's/, $//')
  if ! prompt_install "$missing_str"; then
    for pkg in "${missing[@]}"; do
      add_attempted "$pkg"
    done
    if [ "$(get_preference)" != "never" ]; then
      echo ""
      echo -e "${YELLOW}To install missing tools manually in the future, run:${NC}"
      echo -e "  ${BLUE}\$HOME/.local/share/zsh/install-dependencies.sh${NC}"
    fi
    return 0
  fi

  echo -e "${GREEN}Detected package manager:${NC} $pm"
  [ -n "$secondary_pm" ] && echo -e "${GREEN}Secondary package manager:${NC} $secondary_pm"
  echo "---"

  local failed=()
  local installed=()

  # --- Install priority packages first ---
  for pkg in "${PRIORITY_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
      if install_priority "$pkg"; then
        installed+=("$pkg")
      else
        failed+=("$pkg")
        add_attempted "$pkg"
      fi
    fi
  done

  # --- Install remaining packages via fallback chain ---
  for pkg in "${missing[@]}"; do
    # Skip priority packages (already handled above)
    local is_priority=false
    for pp in "${PRIORITY_PACKAGES[@]}"; do
      [ "$pkg" = "$pp" ] && { is_priority=true; break; }
    done
    $is_priority && continue

    # Skip if already installed
    is_installed "$pkg" && continue

    local success=false

    # 1. Cargo
    if ! $success; then
      for cp in "${CARGO_PACKAGES[@]}"; do
        [ "$pkg" = "$cp" ] && { install_via_cargo "$pkg" && { success=true; break; }; break; }
      done
    fi

    # 2. System PM (need sudo for non-brew)
    if ! $success; then
      for sp in "${SYSTEM_PACKAGES[@]}"; do
        if [ "$pkg" = "$sp" ]; then
          if [ "$pm" != "brew" ] && ! has_sudo; then
            ask_sudo || break
          fi
          install_via_system_pm "$pm" "$pkg" && success=true
          break
        fi
      done
    fi

    # 3. Secondary PM
    if ! $success && [ -n "$secondary_pm" ]; then
      for sp in "${SECONDARY_PACKAGES[@]}"; do
        [ "$pkg" = "$sp" ] && { install_via_secondary_pm "$secondary_pm" "$pkg" && success=true; break; }
      done
    fi

    # 4. UV
    if ! $success; then
      for up in "${UV_PACKAGES[@]}"; do
        [ "$pkg" = "$up" ] && { install_via_uv "$pkg" && success=true; break; }
      done
    fi

    # 5. NPM
    if ! $success; then
      for np in "${NPM_PACKAGES[@]}"; do
        [ "$pkg" = "$np" ] && { install_via_npm "$pkg" && success=true; break; }
      done
    fi

    # 6. Script install (curl | sh)
    if ! $success; then
      for sip in "${SCRIPT_INSTALL_PACKAGES[@]}"; do
        [ "$pkg" = "$sip" ] && { install_via_script_install "$pkg" && success=true; break; }
      done
    fi

    # 7. Script download (curl → ~/.local/bin)
    if ! $success; then
      for sdp in "${SCRIPT_DOWNLOAD_PACKAGES[@]}"; do
        [ "$pkg" = "$sdp" ] && { install_via_script_download "$pkg" && success=true; break; }
      done
    fi

    # 8. Git clone
    if ! $success; then
      for gp in "${GIT_PACKAGES[@]}"; do
        [ "$pkg" = "$gp" ] && { install_via_git "$pkg" && success=true; break; }
      done
    fi

    if $success; then
      installed+=("$pkg")
    else
      failed+=("$pkg")
      add_attempted "$pkg"
    fi
  done

  echo "---"
  echo -e "${GREEN}Installed: ${#installed[@]}${NC}"
  echo -e "${YELLOW}Logs: ${LOG_FILE}${NC}"

  if [ ${#failed[@]} -gt 0 ]; then
    echo -e "${YELLOW}Failed: ${#failed[@]}${NC}"
    echo -e "${RED}Failed to install: ${failed[*]}${NC}"
    echo ""
    echo -e "${YELLOW}To manually install missing tools, run:${NC}"
    echo -e "  ${BLUE}\$HOME/.local/share/zsh/install-dependencies.sh${NC}"
    sudo -k 2>/dev/null || true
    return 1
  fi

  echo -e "${GREEN}All missing tools installed!${NC}"
  sudo -k 2>/dev/null || true
  return 0
}

# Only run main when executed directly, not when sourced (e.g. by tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
