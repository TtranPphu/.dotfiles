-- Pyright: full Python language server (definitions, references, symbols, ...).
--
-- `ruff` (see ruff.lua) only lints/formats, so it doesn't implement the
-- navigation requests the telescope LSP pickers (grd/grr) call. Pyright
-- provides those.
--
-- Install via Mason: `:MasonToolsInstallSync`, or `:Mason` and install "pyright".
--
-- nvim-lspconfig ships the `pyright` server config (`lsp/pyright.lua`,
-- auto-discovered from the runtimepath): it starts `pyright-langserver` for
-- python buffers. Enable it here the same way the servers declared in init.lua
-- are enabled.

vim.lsp.enable 'pyright'
