# PATH modifications

if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

# HuggingFace model cache
export HF_HUB_CACHE=/mnt/shared/huggingface

# Wayland clipboard for Python apps (pyperclip)
export PYPERCLIP_USE_WL_CLIPBOARD=1
