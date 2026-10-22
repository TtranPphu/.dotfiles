-- Rainbow column highlighting for CSV/TSV files.
vim.pack.add { 'https://github.com/mechatroner/rainbow_csv' }

-- The root init.lua starts treesitter on FileType csv/tsv, and
-- `vim.treesitter.start` clears 'syntax', which suppresses rainbow_csv's
-- column highlighting. This FileType autocmd is registered after the root one,
-- so it runs last: stop treesitter, select the legacy syntax file, then source
-- the plugin's own copy explicitly because Neovim's builtin syntax/csv.vim is
-- sourced after it and would shadow its column groups.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'csv', 'tsv' },
  callback = function(args)
    vim.treesitter.stop(args.buf)
    vim.bo[args.buf].syntax = args.match
    local rainbow = vim.pack.get({ 'rainbow_csv' }, { info = false })[1].path
    vim.cmd.source(vim.fs.joinpath(rainbow, 'syntax', args.match .. '.vim'))
  end,
})
