# PATH modifications

if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

# HuggingFace model cache
export HF_HUB_CACHE=/mnt/shared/huggingface

# Wayland clipboard for Python apps (pyperclip)
export PYPERCLIP_USE_WL_CLIPBOARD=1

# OpenCode: background (async) subagents — the parent keeps its turn and is
# notified when the child finishes. Experimental; pass background: true explicitly.
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true

# OpenCode: disable mouse input in the TUI — no mouse capture, clicks or scroll.
export OPENCODE_DISABLE_MOUSE=true
