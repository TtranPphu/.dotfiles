-- Ruff: Python linter, formatter and language server (https://github.com/astral-sh/ruff).
--
-- The `ruff` binary must be installed separately (it is a compiled binary, so
-- mason is not used here):
--   cargo install ruff
--
-- nvim-lspconfig ships the `ruff` server config (`lsp/ruff.lua`, auto-discovered
-- from the runtimepath): it starts `ruff server` for python buffers. Enable it
-- here the same way the servers declared in init.lua are enabled.

vim.lsp.enable 'ruff'

-- Format python with ruff. conform is configured in init.lua; the second
-- setup() call here only merges this formatter mapping into it.
-- Format-on-save is enabled for python here, overriding init.lua's opt-in gate.
require('conform').setup {
  format_on_save = function(bufnr)
    local enabled_filetypes = {
      python = true,
    }
    if enabled_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 500 }
    else
      return nil
    end
  end,
  formatters_by_ft = {
    python = { 'ruff_format' },
  },
}
