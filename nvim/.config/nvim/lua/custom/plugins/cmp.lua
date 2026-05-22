-- Completion framework with Copilot integration
-- Uses blink.cmp with 'super-tab' preset (Tab accepts completions)

vim.pack.add { { src = 'https://github.com/saghen/blink.cmp', version = '1.*' } }
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
    default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer' },
    copilot = {
      async = true,
    },
  },
}
