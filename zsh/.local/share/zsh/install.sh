#!/bin/bash

# Installation script for dotfiles dependencies
# Detects package manager and attempts to install missing tools
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

# Tools mapping: tool_name -> package_name (system package manager)
declare -A TOOLS=(
  [hyprland]="hyprland"
  [tmux]="tmux"
  [nvim]="neovim"
  [zsh]="zsh"
  [nu]="nushell"
  [starship]="starship"
  [waybar]="waybar"
  [walker]="walker"
  [yazi]="yazi"
  [ghostty]="ghostty"
  [gdu]="gdu"
  [bat]="bat"
  [eza]="eza"
  [niri]="niri"
  [fzf]="fzf"
  [zoxide]="zoxide"
  [lazygit]="lazygit"
  [lazydocker]="lazydocker"
  [stow]="gnu-stow"
  [jq]="jq"
  [zellij]="zellij"
  [ripgrep]="ripgrep"
  [argc]="argc"
  [opencode]="opencode"
)

# Tools available via cargo (fallback for when system PM doesn't have them)
declare -A CARGO_TOOLS=(
  [argc]="argc"
  [nu]="nu"
  [bat]="bat"
  [eza]="eza"
  [starship]="starship"
  [zoxide]="zoxide"
  [fd]="fd-find"
  [ripgrep]="ripgrep"
  [aichat]="aichat"
  [zellij]="zellij"
)

# Tools available via npm (fallback)
declare -A NPM_TOOLS=(
  [neovim]="neovim"
  [opencode]="opencode-ai"
)

# Script-based tools (detected as commands, installed by downloading a script)
# Value is the download URL. Use {version} as a placeholder — it's resolved
# from the version of the matching parent tool (e.g. fzf-tmux → fzf).
# Prefix with "pipe:" to pipe the script through sh instead of downloading.
declare -A SCRIPTS_TOOLS=(
  [fzf-tmux]="https://raw.githubusercontent.com/junegunn/fzf/v{version}/bin/fzf-tmux"
  [ohmyzsh]="pipe:https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
)

# Alternative command names for tools on different systems
declare -A TOOL_ALIASES=(
  [bat]="batcat"
  [ripgrep]="rg"
)

# Priority tools that must install first (e.g. language runtimes, frameworks).
# These have custom install logic in try_install_priority.
PRIORITY_TOOLS=(rustup)

# Custom detection commands for tools not found via command -v.
# Value is a command/eval string that returns 0 if installed.
declare -A TOOL_DETECT=(
  [ohmyzsh]="test -d \"\$HOME/.oh-my-zsh\""
)

# Get command name(s) for a tool
get_command_names() {
  local tool=$1
  local alias=${TOOL_ALIASES[$tool]}
  if [ -n "$alias" ]; then
    echo "$tool $alias"
  else
    echo "$tool"
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
    # Simple fallback without jq
    local attempted
    attempted=$(grep -oP '"attempted":\s*\[\K[^\]]*' "$STATE_FILE" || echo "")
    if [ -z "$attempted" ]; then
      sed -i "s/\"attempted\": \[\]/\"attempted\": [\"$package\"]/" "$STATE_FILE"
    else
      sed -i "s/\"attempted\": \[/\"attempted\": [\"$package\", /" "$STATE_FILE"
    fi
  fi
}

# Detect package manager
detect_package_manager() {
  if command -v apt-get &> /dev/null; then
    echo "apt"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  elif command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v brew &> /dev/null; then
    echo "brew"
  elif command -v zypper &> /dev/null; then
    echo "zypper"
  elif command -v apk &> /dev/null; then
    echo "apk"
  else
    echo "unknown"
  fi
}

# Get package name for a tool based on package manager
get_package_name() {
  local tool=$1
  local pm=$2
  local base_name=${TOOLS[$tool]:-$tool}

  case "$pm" in
    apt|dnf|pacman|zypper|apk)
      case "$tool" in
        hyprland|starship|bat|eza|ghostty|walker|lazygit|lazydocker|stow) echo "$base_name" ;;
        *) echo "$base_name" ;;
      esac
      ;;
    brew)
      case "$tool" in
        walker) echo "" ;; # Not in brew
        opencode) echo "anomalyco/tap/opencode" ;;
        *) echo "$base_name" ;;
      esac
      ;;
    *)
      echo "$base_name"
      ;;
  esac
}

# Check if tool is installed
is_installed() {
  local tool=$1

  # Custom detection for non-command tools (e.g. framework directories)
  local detect=${TOOL_DETECT[$tool]}
  if [ -n "$detect" ]; then
    eval "$detect" && return 0 || return 1
  fi

  local commands
  commands=$(get_command_names "$tool")

  for cmd in $commands; do
    if command -v "$cmd" &> /dev/null; then
      return 0
    fi
  done
  return 1
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
    echo -e "  ${BLUE}\$HOME/.local/share/zsh/install.sh${NC}"
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

      # Read single key without waiting for Enter
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

# Try to install package
try_install() {
  local package=$1
  local pm=$2
  local tool=$3

  if [ -z "$package" ]; then
    echo -e "${YELLOW}⊘${NC} $tool: No package mapping for $pm"
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $tool ($package)..."

  case "$pm" in
    apt)
      if sudo apt-get update >> "$LOG_FILE" 2>&1 && sudo apt-get install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    dnf)
      if sudo dnf install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    brew)
      if brew install "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    zypper)
      if sudo zypper install -y "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    apk)
      if sudo apk add "$package" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    *)
      echo -e "${YELLOW}⊘${NC} Unknown package manager"
      return 1
      ;;
  esac
}

# Try installing via cargo
try_install_cargo() {
  local tool=$1
  local package=${CARGO_TOOLS[$tool]}

  if [ -z "$package" ]; then
    return 1
  fi

  if ! command -v cargo &> /dev/null; then
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $tool (cargo: $package)..."
  if cargo install "$package" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $tool installed via cargo"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to install $tool via cargo"
    return 1
  fi
}

# Try installing via npm
try_install_npm() {
  local tool=$1
  local package=${NPM_TOOLS[$tool]}

  if [ -z "$package" ]; then
    return 1
  fi

  if ! command -v npm &> /dev/null; then
    return 1
  fi

  echo -e "${YELLOW}↓${NC} Installing $tool (npm: $package)..."
  if npm install -g "$package" >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}✓${NC} $tool installed via npm"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to install $tool via npm"
    return 1
  fi
}

# Try installing a priority tool (custom install logic, runs first)
try_install_priority() {
  local tool=$1

  case "$tool" in
    rustup)
      echo -e "${YELLOW}↓${NC} Installing rustup..."
      if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1; then
        # Source cargo env so subsequent steps can use it
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
        echo -e "${GREEN}✓${NC} rustup installed"
        return 0
      fi
      echo -e "${RED}✗${NC} Failed to install rustup"
      return 1
      ;;
  esac
  return 1
}

# Try installing a script-based tool (download to ~/.local/bin or pipe through sh)
try_install_script() {
  local tool=$1
  local spec=${SCRIPTS_TOOLS[$tool]}

  [ -z "$spec" ] && return 1

  # Check for pipe: prefix (pipe the script through sh instead of saving)
  local pipe=false
  local url="$spec"
  if [[ "$url" == "pipe:"* ]]; then
    pipe=true
    url="${url#pipe:}"
  fi

  # Resolve {version} placeholder from the parent tool (strip suffixes)
  local ver=""
  if [[ "$url" == *"{version}"* ]]; then
    local parent="${tool%-*}"
    [ "$parent" = "$tool" ] && return 1
    ver=$("$parent" --version 2>/dev/null | awk '{print $1}')
    [ -z "$ver" ] && return 1
  fi

  if $pipe; then
    echo -e "${YELLOW}↓${NC} Installing $tool..."
    local script
    if ! script=$(curl -fsSL "${url//\{version\}/v$ver}" 2>/dev/null); then
      [ -n "$ver" ] && script=$(curl -fsSL "${url//\{version\}/$ver}" 2>/dev/null) || { echo -e "${RED}✗${NC} Failed to install $tool"; return 1; }
    fi
    if echo "$script" | sh >> "$LOG_FILE" 2>&1; then
      echo -e "${GREEN}✓${NC} $tool installed"
      return 0
    fi
    echo -e "${RED}✗${NC} Failed to install $tool"
    return 1
  fi

  local target="$HOME/.local/bin/$tool"
  mkdir -p "$HOME/.local/bin"

  echo -e "${YELLOW}↓${NC} Installing $tool (script)..."
  if curl -fsSLo "$target" "${url//\{version\}/v$ver}" 2>/dev/null; then
    chmod +x "$target"
    echo -e "${GREEN}✓${NC} $tool installed to $target"
    return 0
  fi

  # Retry with bare version (no v prefix)
  if [ -n "$ver" ] && curl -fsSLo "$target" "${url//\{version\}/$ver}" 2>/dev/null; then
    chmod +x "$target"
    echo -e "${GREEN}✓${NC} $tool installed to $target"
    return 0
  fi

  echo -e "${RED}✗${NC} Failed to install $tool"
  return 1
}

main() {
  local pm
  pm=$(detect_package_manager)

  if [ "$pm" = "unknown" ]; then
    echo -e "${RED}Error: Could not detect package manager${NC}"
    return 1
  fi

  # Ensure state and log directories exist
  mkdir -p "$STATE_DIR"
  mkdir -p "$LOG_DIR"
  init_state

  # Check for missing tools (system packages + scripts + priority)
  local missing=()
  for tool in "${PRIORITY_TOOLS[@]}" "${!TOOLS[@]}" "${!SCRIPTS_TOOLS[@]}"; do
    if ! is_installed "$tool"; then
      missing+=("$tool")
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
  for tool in "${missing[@]}"; do
    if ! echo "$attempted" | grep -q "^$tool$"; then
      all_attempted=false
      break
    fi
  done

  # Skip if all missing tools were attempted and user chose "no"
  local pref
  pref=$(get_preference)
  if [ "$all_attempted" = true ] && [ "$pref" = "ask" ]; then
    return 0
  fi

  # Prompt user for installation
  local missing_str
  missing_str=$(printf '%s, ' "${missing[@]}" | sed 's/, $//')
  if ! prompt_install "$missing_str"; then
    # Mark all missing tools as attempted
    for tool in "${missing[@]}"; do
      add_attempted "$tool"
    done
    if [ "$(get_preference)" != "never" ]; then
      echo ""
      echo -e "${YELLOW}To install missing tools manually in the future, run:${NC}"
      echo -e "  ${BLUE}\$HOME/.local/share/zsh/install.sh${NC}"
    fi
    return 0
  fi

  echo -e "${GREEN}Detected package manager:${NC} $pm"
  echo "---"

  local failed=()
  local installed=()

  # Install priority tools first (enable other install methods)
  for tool in "${PRIORITY_TOOLS[@]}";  do
    if ! is_installed "$tool"; then
      if try_install_priority "$tool"; then
        installed+=("$tool")
      else
        failed+=("$tool")
        add_attempted "$tool"
      fi
    fi
  done

  # Check and install each missing tool
  for tool in "${missing[@]}"; do
    local success=false

    # Try cargo first (user preference)
    if try_install_cargo "$tool"; then
      installed+=("$tool")
      success=true
    fi

    # Fall back to system package manager if cargo failed
    if ! $success; then
      # Check sudo availability for non-brew package managers
      if [ "$pm" != "brew" ] && ! has_sudo; then
        if ! ask_sudo; then
          failed+=("$tool")
          add_attempted "$tool"
          continue
        fi
      fi

      local package
      package=$(get_package_name "$tool" "$pm")
      if try_install "$package" "$pm" "$tool"; then
        installed+=("$tool")
        success=true
      fi
    fi

    # Fall back to npm as a last resort
    if ! $success && try_install_npm "$tool"; then
      installed+=("$tool")
      success=true
    fi

    # Fall back to script download (for tools not in system package repos)
    if ! $success && try_install_script "$tool"; then
      installed+=("$tool")
      success=true
    fi

    if ! $success; then
      failed+=("$tool")
      add_attempted "$tool"
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
    echo -e "  ${BLUE}\$HOME/.local/share/zsh/install.sh${NC}"
    sudo -k 2>/dev/null || true
    return 1
  fi

  echo -e "${GREEN}All missing tools installed!${NC}"
  sudo -k 2>/dev/null || true
  return 0
}

main "$@"
