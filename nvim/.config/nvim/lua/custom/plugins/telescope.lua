-- Match Telescope background to the normal editor background.
-- Some colorschemes (like Tokyonight) set Telescope-specific backgrounds
-- that differ from the main Normal background.
--
-- The fix runs immediately (since this file loads after the colorscheme)
-- and also hooks ColorScheme for future theme changes.
local api = vim.api

local function fix_telescope_bg()
  local normal_bg = api.nvim_get_hl(0, { name = 'Normal' }).bg
  if not normal_bg then
    return
  end

  local groups = {
    'TelescopeNormal',
    'TelescopePromptNormal',
    'TelescopeResultsNormal',
    'TelescopePreviewNormal',
    'TelescopeBorder',
    'TelescopePromptBorder',
    'TelescopeResultsBorder',
    'TelescopePreviewBorder',
    'TelescopePromptTitle',
    'TelescopeResultsTitle',
    'TelescopePreviewTitle',
  }

  for _, group in ipairs(groups) do
    local hl = api.nvim_get_hl(0, { name = group })
    hl.bg = normal_bg
    api.nvim_set_hl(0, group, hl)
  end
end

-- Run immediately (colorscheme already applied before this file loads)
fix_telescope_bg()

-- Also re-apply on future colorscheme changes
api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = fix_telescope_bg,
})

-- Local delta from init.lua: search hidden files while skipping VCS/build
-- noise. `set_pickers` is what `telescope.setup` calls internally; calling it
-- directly leaves the ui-select extension config from init.lua untouched.
local ignore_lua_patterns = {
  -- git / node
  '.git/', 'node_modules/',
  -- python cache
  '__pycache__/', '%.pyc', '%.pyo',
  '.pytest_cache/', '.mypy_cache/', '.ruff_cache/',
  -- rust build
  'target/debug/', 'target/release/', 'target/.fingerprint/',
  'target/.rustc_info.json', 'target/flycheck', 'target/CACHEDIR.TAG',
  -- mongodb / wiredtiger
  '%.wt', 'WiredTiger', 'journal/', 'diagnostic.data/',
}

local ignore_rg_globs = {
  -- git / node
  '!.git', '!node_modules',
  -- python cache
  '!__pycache__', '!*.pyc', '!*.pyo',
  '!.pytest_cache', '!.mypy_cache', '!.ruff_cache',
  -- rust build
  '!target/debug', '!target/release', '!target/.fingerprint',
  '!target/.rustc_info.json', '!**/target/flycheck*', '!target/CACHEDIR.TAG',
  -- mongodb / wiredtiger
  '!*.wt', '!WiredTiger*', '!journal', '!diagnostic.data',
}

require('telescope.config').set_pickers {
  find_files = {
    hidden = true,
    no_ignore = true,
    file_ignore_patterns = ignore_lua_patterns,
  },
  live_grep = {
    additional_args = function(_)
      local args = { '--hidden', '--no-ignore' }
      for _, p in ipairs(ignore_rg_globs) do
        vim.list_extend(args, { '-g', p })
      end
      return args
    end,
  },
}
