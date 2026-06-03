# Neovim — Review Findings

## 🟢 Remaining — Low severity

### Stale lock file entries from old nvim-cmp ecosystem

**File:** `nvim/.config/nvim/nvim-pack-lock.json`

14 entries for `nvim-cmp`, `cmp-buffer`, `cmp-cmdline`, `cmp-nvim-lsp`, `cmp-path`, `cmp_luasnip`, `copilot-cmp` — remnants of the migration to blink.cmp. Run `vim.pack.clean()` to purge.

---

### `<C-\><C-\>` mapping likely intercepted by terminal/tmux

**File:** `nvim/.config/nvim/lua/custom/plugins/neo-tree.lua:17`

`<C-\>` is the SIGQUIT signal in most terminals and is intercepted by tmux. This mapping may never reach Neovim.
