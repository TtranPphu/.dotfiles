-- GitHub Copilot support with Lua integration

vim.pack.add { 'https://github.com/zbirenbaum/copilot.lua' }

require('copilot').setup {
  cmp = {
    enabled = true,
    max_lines = 100,
    max_words = 200,
  },
  suggestion = {
    enabled = false, -- Disable default suggestions since we use cmp
  },
  panel = {
    enabled = true,
    auto_refresh = false,
    keymap = {
      jump_prev = '[[',
      jump_next = ']]',
      accept = '<CR>',
      refresh = 'gr',
      open = '<M-CR>',
    },
  },
  filetypes = {
    yaml = false,
    hcl = false,
    properties = false,
    markdown = false,
    gitcommit = false,
    gitrebase = false,
    ocaml = false,
    ocamlinterface = false,
    ocamllex = false,
    ocamlyacc = false,
    reason = false,
    dune = false,
    idris = false,
    elm = false,
    erlang = false,
    elixir = false,
    eex = false,
    purescript = false,
    clojure = false,
  },
}
