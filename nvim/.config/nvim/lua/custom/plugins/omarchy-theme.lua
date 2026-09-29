-- Follow the active Omarchy theme. Omarchy stages a lazy.nvim-shaped spec at
-- ~/.local/state/omarchy/current/theme/neovim.lua but never signals running
-- editors: it documents that nvim reads that file at startup. Apply it then and
-- watch the state directory so a live theme switch re-applies it too.

local M = {}

-- Only one watcher per editor, no matter how often this module loads.
local watched = false
local DEBOUNCE_MS = 200

-- The colorscheme plugin is the first non-LazyVim entry with a string repo;
-- the colorscheme name lives in the LazyVim entry's opts.colorscheme.
function M.extract(spec)
  local plugin, scheme
  for _, entry in ipairs(spec) do
    if type(entry) == 'table' and type(entry[1]) == 'string' then
      if entry[1] == 'LazyVim/LazyVim' then
        scheme = entry.opts and entry.opts.colorscheme
      elseif not plugin then
        plugin = entry
      end
    end
  end
  return plugin, scheme
end

-- Translate a lazy.nvim entry to a vim.pack spec.
local function pack_spec(plugin)
  local spec = { src = 'https://github.com/' .. plugin[1] }
  if plugin.name then spec.name = plugin.name end
  if plugin.branch then spec.version = plugin.branch end
  return spec
end

-- The module name is not reliably derivable from the repo, so try the
-- candidates in order and let the first that loads win.
local function module_names(plugin)
  local base = plugin[1]:match '([^/]+)$'
  local names = {}
  if plugin.name then table.insert(names, plugin.name) end
  table.insert(names, base)
  local stripped = base:gsub('%.nvim$', '')
  if stripped ~= base then table.insert(names, stripped) end
  return names
end

function M.apply(plugin, scheme)
  if plugin then
    local ok, spec = pcall(pack_spec, plugin)
    if ok then pcall(vim.pack.add, { spec }, { confirm = false }) end

    if plugin.opts then
      for _, name in ipairs(module_names(plugin)) do
        local loaded, mod = pcall(require, name)
        if loaded and type(mod) == 'table' and type(mod.setup) == 'function' then
          pcall(mod.setup, plugin.opts)
          break
        end
      end
    end
  end

  if scheme then pcall(vim.cmd.colorscheme, scheme) end
end

-- Never raises: any failure leaves init.lua's colorscheme in place.
function M.run(path)
  local ok, spec = pcall(dofile, path or vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua')
  if not ok or type(spec) ~= 'table' then return end
  local plugin, scheme = M.extract(spec)
  M.apply(plugin, scheme)
end

-- Re-run M.run when the theme changes. Omarchy rewrites/stages files under
-- current/ without signalling nvim, so the filesystem is the only trigger.
-- fs_event is non-recursive, so watch current/ (a directory swap of theme/ or
-- staged writes to current/theme.name) and current/theme/ (an in-place rewrite
-- of theme/neovim.lua). Omarchy writes many files in a burst, hence the
-- debounce. path is injectable so tests can point at a synthetic state dir.
function M.watch(path)
  if watched then return end

  local uv = vim.uv or vim.loop
  if not uv or type(uv.new_fs_event) ~= 'function' then return end

  local state = path or vim.fn.expand '~/.local/state/omarchy/current'
  local dirs = { state }
  local ok, stat = pcall(uv.fs_stat, state .. '/theme')
  if ok and stat then table.insert(dirs, state .. '/theme') end

  local timer = uv.new_timer()
  if not timer then return end

  -- Every handle shares one timer, so they feed the same debounced re-apply.
  local function on_event()
    pcall(timer.stop, timer)
    pcall(timer.start, timer, DEBOUNCE_MS, 0, function()
      pcall(timer.stop, timer)
      local spec = state .. '/theme/neovim.lua'
      if not uv.fs_stat(spec) then spec = state .. '/neovim.lua' end
      vim.schedule(function() pcall(M.run, spec) end)
    end)
  end

  -- The callbacks run on the libuv loop, where a raised error is
  -- unrecoverable: pcall every step. A failed handle is closed, never fatal.
  local handles = {}
  for _, dir in ipairs(dirs) do
    local handle = uv.new_fs_event()
    if handle then
      local started, code = pcall(handle.start, handle, dir, {}, on_event)
      if started and code == 0 then
        table.insert(handles, handle)
      else
        pcall(handle.close, handle)
      end
    end
  end

  if #handles == 0 then
    pcall(timer.close, timer)
    return
  end

  watched = true
end

M.run()
M.watch()

return M
