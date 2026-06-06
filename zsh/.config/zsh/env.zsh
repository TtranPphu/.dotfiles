# PATH modifications

if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"
