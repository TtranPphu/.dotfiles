#!/bin/bash
# Set up or remove llm-functions for aichat filesystem tool support

set -e

AICHAT_FUNCTIONS="$HOME/.local/share/aichat/llm-functions"

if [ "${1:-}" = "--remove" ]; then
  echo "This will remove llm-functions and disable filesystem tools in aichat."
  echo -n "Continue? [y/N] "
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
  rm -rf "$AICHAT_FUNCTIONS"
  echo "Removed. Filesystem tools are disabled."
  echo ""
  echo "  To apply, restart your shell:"
  echo "    exec zsh"
  exit 0
fi

if [ -f "$AICHAT_FUNCTIONS/functions.json" ]; then
  echo "llm-functions is already set up."
  echo ""
  echo "  Run \`aichat-setup --remove\` to undo."
  exit 0
fi

echo "This will download and build llm-functions, enabling aichat to"
echo "run filesystem operations (list files, read/write files, etc.)"
echo "directly from natural language prompts."
echo ""
echo -n "Continue? [y/N] "
read -r reply
case "$reply" in
  y|Y|yes|YES) ;;
  *) echo "Aborted."; exit 1 ;;
esac

if [ -d "$AICHAT_FUNCTIONS" ]; then
  echo "Updating llm-functions..."
  cd "$AICHAT_FUNCTIONS"
  git pull --ff-only
else
  echo "Cloning llm-functions..."
  mkdir -p "$HOME/.local/share/aichat"
  git clone https://github.com/sigoden/llm-functions "$AICHAT_FUNCTIONS"
  cd "$AICHAT_FUNCTIONS"
fi

# Write tools.txt with filesystem and utility tools
cat > tools.txt <<'EOF'
fs_ls.sh
fs_cat.sh
fs_write.sh
fs_mkdir.sh
fs_rm.sh
execute_command.sh
get_current_time.sh
web_search_aichat.sh
EOF

echo "Building function definitions..."
argc build
echo ""
echo "Done. Filesystem tools are now available in aichat."
echo ""
echo "  To activate, restart your shell:"
echo "    exec zsh"
echo ""
echo "  To undo:"
echo "    aichat-setup --remove"
