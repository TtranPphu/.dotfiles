-- Completion framework
-- The intended local config: blink.cmp with 'super-tab' preset (Tab accepts
-- completions) and the rust fuzzy matcher.
--
-- NOTE: `blink.cmp.setup()` is first-call-wins and the root init.lua already
-- called it (upstream defaults: preset 'default', fuzzy 'lua'), so the options
-- below do not take effect. See this repo's update report.

vim.pack.add { { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.*' } }
vim.pack.add { 'https://github.com/L3MON4D3/LuaSnip' }

require('luasnip').setup {}

require('blink.cmp').setup {
  keymap = {
    preset = 'super-tab',
  },
  appearance = {
    nerd_font_variant = 'mono',
  },
  completion = {
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
}
