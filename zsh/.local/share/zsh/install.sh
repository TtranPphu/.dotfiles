#!/bin/bash

# Installation script for dotfiles dependencies
# Detects package manager and attempts to install missing tools
# Tracks user preferences and skips installation based on previous choices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State file to track user preferences
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/install-state.json"
STATE_DIR="$(dirname "$STATE_FILE")"

# Tools mapping: tool_name -> package_name
declare -A TOOLS=(
  [hyprland]="hyprland"
  [tmux]="tmux"
  [nvim]="neovim"
  [zsh]="zsh"
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
)

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
  command -v "$1" &> /dev/null
}

# Check if sudo is available
has_sudo() {
  sudo -n true 2>/dev/null
}

# Ask user to enable sudo
ask_sudo() {
  echo -e "${YELLOW}This operation requires sudo for package installation.${NC}"
  echo "Please run: ${BLUE}sudo -v${NC}"
  echo "This will cache your sudo credentials for the next 15 minutes."
  exit 1
}

# Prompt user for installation
prompt_install() {
  local pref
  pref=$(get_preference)

  case "$pref" in
    always)
      return 0
      ;;
    never)
      return 1
      ;;
    ask)
      echo -e "${BLUE}Missing packages detected for this dotfiles repository.${NC}"
      echo "Install missing tools?"
      echo -e "  ${GREEN}yes${NC}   - Install now"
      echo -e "  ${GREEN}no${NC}    - Skip installation"
      echo -e "  ${GREEN}always${NC} - Install now and don't ask again"
      echo -e "  ${GREEN}never${NC}  - Skip and don't ask again"
      echo -n "Choice (yes/no/always/never): "
      read -r choice

      case "$choice" in
        y|yes)
          return 0
          ;;
        n|no)
          return 1
          ;;
        always)
          update_preference "always"
          return 0
          ;;
        never)
          update_preference "never"
          return 1
          ;;
        *)
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
      if sudo apt-get update && sudo apt-get install -y "$package"; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    dnf)
      if sudo dnf install -y "$package"; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm "$package"; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    brew)
      if brew install "$package"; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    zypper)
      if sudo zypper install -y "$package"; then
        echo -e "${GREEN}✓${NC} $tool installed"
        return 0
      else
        echo -e "${RED}✗${NC} Failed to install $tool"
        return 1
      fi
      ;;
    apk)
      if sudo apk add "$package"; then
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

main() {
  local pm
  pm=$(detect_package_manager)

  if [ "$pm" = "unknown" ]; then
    echo -e "${RED}Error: Could not detect package manager${NC}"
    return 1
  fi

  # Check for missing tools
  local missing=()
  for tool in "${!TOOLS[@]}"; do
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
  if ! prompt_install; then
    # Mark all missing tools as attempted
    for tool in "${missing[@]}"; do
      add_attempted "$tool"
    done
    return 0
  fi

  # Check sudo availability for non-brew package managers
  if [ "$pm" != "brew" ] && ! has_sudo; then
    ask_sudo
  fi

  echo -e "${GREEN}Detected package manager:${NC} $pm"
  echo "---"

  local failed=()
  local installed=()

  # Check and install each missing tool
  for tool in "${missing[@]}"; do
    local package
    package=$(get_package_name "$tool" "$pm")

    if try_install "$package" "$pm" "$tool"; then
      installed+=("$tool")
    else
      failed+=("$tool")
      add_attempted "$tool"
    fi
  done

  echo "---"
  echo -e "${GREEN}Installed: ${#installed[@]}${NC}"

  if [ ${#failed[@]} -gt 0 ]; then
    echo -e "${YELLOW}Failed: ${#failed[@]}${NC}"
    echo -e "${RED}Failed to install: ${failed[*]}${NC}"
    echo ""
    echo -e "${YELLOW}To manually install missing tools, run:${NC}"
    echo "  ${BLUE}./.scripts/install${NC}"
    return 1
  fi

  echo -e "${GREEN}All missing tools installed!${NC}"
  return 0
}

main "$@"
