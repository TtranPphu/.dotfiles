-- Language-specific indentation settings
-- Override the global 2-space indent for specific languages

local group = vim.api.nvim_create_augroup('LanguageIndent', { clear = true })

-- Define language-specific indent settings
local indent_map = {
  python = 4,     -- PEP 8: 4 spaces
  go = 4,         -- Go convention: 4 spaces or tabs
  java = 4,       -- Java convention: 4 spaces
  c = 4,          -- C convention: 4 spaces
  cpp = 4,        -- C++ convention: 4 spaces
  rust = 4,       -- Rust convention: 4 spaces
  typescript = 2, -- TypeScript/JavaScript: 2 spaces (explicit)
  javascript = 2, -- JavaScript: 2 spaces (explicit)
  html = 2,       -- HTML: 2 spaces
  css = 2,        -- CSS: 2 spaces
  json = 2,       -- JSON: 2 spaces
  yaml = 2,       -- YAML: 2 spaces
  toml = 2,       -- TOML: 2 spaces
}

-- Apply indent settings based on filetype
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(ev)
    local indent = indent_map[ev.match]
    if indent then
      vim.bo.shiftwidth = indent
      vim.bo.softtabstop = indent
      vim.bo.tabstop = indent
    end
  end,
})
