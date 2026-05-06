-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree open/focus', silent = true },
    { '<C-\\><C-\\>', ':Neotree close<CR>', desc = 'NeoTree close', silent = false },
  },
  opts = {
    -- window = {
    --   position = 'float',
    -- },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = function()
            vim.cmd ':wincmd l'
          end,
          ['<C-\\><C-\\>'] = function()
            vim.cmd ':q'
          end,
        },
      },
    },
  },
}
