-- Theme loader, palette adapter, and persistence.
--
-- Data flow:
--   colorscheme.lua reads `M.current_palette` inside tokyonight's on_colors
--   hook and maps it onto tokyonight's color slots via `M.to_tokyonight()`.
--   To switch themes we mutate `M.current_palette` then re-fire
--   `:colorscheme tokyonight`, which re-invokes on_colors with the new
--   palette. All existing on_highlights overrides auto-adapt because they
--   reference `c.*` fields that on_colors just rewrote.
--
-- Persistence: state is stored as JSON at `stdpath('state')/ach-theme.json`
-- with a single field `{ manual = "<theme-name>" }`. Writes are atomic
-- (write to `.tmp` then rename).
--
-- This build is dark-themes-only. Light themes were removed from the
-- vendored palette set; the loader no longer has any light/dark detection,
-- auto-switch timer, or `vim.o.background` flipping.

local M = {}

-- ---------------------------------------------------------------
-- base46 / nvconfig shim registration
-- Must run BEFORE any vendored theme file is required. Installs
-- package.preload entries so `require("base46")` and
-- `require("nvconfig")` inside those files resolve to no-op stubs
-- instead of erroring. Two themes (eldritch, poimandres) reach into
-- `nvconfig.ui.*` and `nvconfig.base46.*` at load time for NvChad UI
-- conditionals; the stub returns empty strings / false so those
-- branches fall through without side effects, leaving the theme's
-- default palette and polish_hl block intact.
-- ---------------------------------------------------------------
if not package.loaded["base46"] then
  package.preload["base46"] = function()
    return require("themes.base46_shim")
  end
end
if not package.loaded["nvconfig"] then
  package.preload["nvconfig"] = function()
    return {
      ui = {
        telescope = { style = "" },
        cmp = { style = "" },
        statusline = { theme = "" },
      },
      base46 = {
        transparency = false,
      },
    }
  end
end

-- ---------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------
local DEFAULT_THEME = "deep-ocean"
local STATE_PATH = vim.fn.stdpath("state") .. "/ach-theme.json"
local THEMES_DIR_MODULE = "themes.nvchad"
local THEMES_DIR_FS = vim.fn.stdpath("config") .. "/lua/themes/nvchad"

-- Active palette, read by colorscheme.lua's on_colors closure.
-- Populated by M.setup() at startup and mutated by M.apply() on switch.
M.current_palette = nil
M.current_name = DEFAULT_THEME

-- ---------------------------------------------------------------
-- Theme discovery
-- ---------------------------------------------------------------
local _list_cache = nil

--- Return a sorted list of theme names. Cached after first call.
function M.list()
  if _list_cache then
    return _list_cache
  end
  local items = {}
  local handle = vim.uv.fs_scandir(THEMES_DIR_FS)
  if handle then
    while true do
      local name, t = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if t == "file" and name:match("%.lua$") then
        local theme_name = name:sub(1, -5)
        local ok, palette = pcall(M.load, theme_name)
        if ok and palette then
          table.insert(items, { name = theme_name })
        end
      end
    end
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  _list_cache = items
  return items
end

--- Require and return a theme's raw palette table. Does NOT apply it.
function M.load(name)
  local mod = THEMES_DIR_MODULE .. "." .. name
  package.loaded[mod] = nil -- force fresh load so on-disk edits are picked up
  local ok, palette = pcall(require, mod)
  if not ok then
    return nil
  end
  return palette
end

-- ---------------------------------------------------------------
-- Palette adapter: base46 -> tokyonight colors
-- ---------------------------------------------------------------

--- Given a base46 palette and tokyonight's colors table, rewrite the slots
--- colorscheme.lua depends on. Falls back to sensible defaults when a
--- palette is missing expected fields.
function M.to_tokyonight(colors, palette)
  if not palette then
    return
  end
  local b30 = palette.base_30 or {}
  local b16 = palette.base_16 or {}

  -- Utility: first non-nil value
  local function pick(...)
    for i = 1, select("#", ...) do
      local v = select(i, ...)
      if v and v ~= "" then
        return v
      end
    end
  end

  -- Structural backgrounds
  colors.bg = pick(b30.black, b16.base00)
  colors.bg_dark = pick(b30.darker_black, b30.statusline_bg, b16.base01)
  colors.bg_float = colors.bg_dark
  colors.bg_popup = colors.bg_dark
  colors.bg_sidebar = colors.bg_dark
  colors.bg_statusline = pick(b30.statusline_bg, b30.darker_black, b16.base01)
  colors.bg_highlight = pick(b30.one_bg2, b30.lightbg, b16.base02)
  colors.bg_search = pick(b16.base0A, b30.yellow)
  colors.bg_visual = pick(b30.one_bg2, b30.lightbg, b16.base02)

  -- Foreground text
  colors.fg = pick(b16.base05, b30.white)
  colors.fg_dark = pick(b16.base04, b30.light_grey)
  colors.fg_sidebar = colors.fg
  colors.fg_float = colors.fg
  colors.fg_gutter = pick(b30.grey_fg2, b30.grey_fg, b16.base03)
  colors.comment = pick(b16.base03, b30.grey_fg2)

  -- Borders / separators
  colors.border = pick(b30.grey, b30.light_grey, b16.base02)
  colors.border_highlight = pick(b16.base0D, b30.blue)

  -- Accent / syntax colors (standard base16 meanings)
  colors.red = pick(b16.base08, b30.red)
  colors.orange = pick(b30.orange, b16.base09)
  colors.yellow = pick(b16.base0A, b30.yellow)
  colors.green = pick(b16.base0B, b30.green)
  colors.green1 = pick(b30.vibrant_green, b30["vibrant_gree"], b30.green, b16.base0B)
  colors.teal = pick(b30.teal, b16.base0C)
  colors.cyan = pick(b16.base0C, b30.cyan)
  colors.blue = pick(b16.base0D, b30.blue)
  colors.blue1 = pick(b30.nord_blue, b30.blue, b16.base0D)
  colors.blue2 = colors.blue1
  colors.blue5 = pick(b30.nord_blue, b30.blue, b16.base0D)
  colors.blue6 = colors.blue
  colors.blue7 = pick(b30.nord_blue, b30.blue, b16.base0D)
  colors.magenta = pick(b16.base0E, b30.purple)
  colors.magenta2 = pick(b30.dark_purple, b16.base0E, b30.purple)
  colors.purple = pick(b30.purple, b16.base0E)

  -- Diagnostic / state colors
  colors.error = colors.red
  colors.warning = colors.yellow
  colors.info = colors.blue
  colors.hint = colors.teal or colors.cyan
  colors.todo = colors.blue

  colors.terminal_black = pick(b30.grey, b16.base03)

  -- Git colors (tokyonight exposes these as colors.git.*)
  colors.git = colors.git or {}
  colors.git.add = colors.green
  colors.git.change = colors.blue
  colors.git.delete = colors.red
  colors.git.ignore = colors.fg_gutter

  colors.gitSigns = colors.gitSigns or {}
  colors.gitSigns.add = colors.green
  colors.gitSigns.change = colors.blue
  colors.gitSigns.delete = colors.red
end

-- ---------------------------------------------------------------
-- State persistence (atomic JSON)
-- ---------------------------------------------------------------

local function default_state()
  return { manual = DEFAULT_THEME }
end

local _state = nil

local function read_state()
  if _state then
    return _state
  end
  _state = default_state()
  local fd = vim.uv.fs_open(STATE_PATH, "r", 438)
  if not fd then
    return _state
  end
  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return _state
  end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  if not data or data == "" then
    return _state
  end
  local ok, parsed = pcall(vim.json.decode, data)
  if ok and type(parsed) == "table" and parsed.manual then
    _state.manual = parsed.manual
  end
  return _state
end

local function write_state()
  if not _state then
    return
  end
  local ok, encoded = pcall(vim.json.encode, _state)
  if not ok then
    return
  end
  local tmp = STATE_PATH .. ".tmp"
  local fd = vim.uv.fs_open(tmp, "w", 420)
  if not fd then
    return
  end
  vim.uv.fs_write(fd, encoded, 0)
  vim.uv.fs_close(fd)
  vim.uv.fs_rename(tmp, STATE_PATH)
end

--- Return the current state table ({ manual = "<name>" }).
function M.state()
  return read_state()
end

-- ---------------------------------------------------------------
-- Apply / switch
-- ---------------------------------------------------------------

local function valid_theme(name)
  if not name then
    return false
  end
  return M.load(name) ~= nil
end

--- Load a theme's palette into M.current_palette and trigger a colorscheme
--- reload so tokyonight re-fires on_colors with the new values.
---
--- We deliberately do NOT call tokyonight.setup() here. Tokyonight's
--- config.setup() does `M.options = tbl_deep_extend("force", {}, defaults, opts)`
--- which REPLACES the stored opts -- so re-calling it with anything less
--- than the full original opts wipes the on_colors/on_highlights closures
--- that colorscheme.lua installed at first setup, and subsequent applies
--- revert to tokyonight's plain defaults.
function M.apply(name)
  local palette = M.load(name)
  if not palette then
    vim.notify("Theme not found: " .. tostring(name), vim.log.levels.WARN, { title = "Theme" })
    return false
  end
  M.current_palette = palette
  M.current_name = name
  pcall(vim.cmd.colorscheme, "tokyonight")
  return true
end

--- Preview-only apply: same as apply() but the caller is expected to
--- restore on cancel. Kept as a separate entry point so future per-preview
--- side effects (e.g. flashing a temporary badge) can be added here.
function M.preview(name)
  return M.apply(name)
end

--- Set a theme as the persistent choice. Persists and applies.
function M.set_manual(name)
  if not valid_theme(name) then
    return false
  end
  local s = read_state()
  s.manual = name
  write_state()
  return M.apply(name)
end

--- Cycle to the next/previous theme in the sorted list.
function M.cycle(direction)
  local items = M.list()
  if #items == 0 then
    return
  end
  local idx = 1
  for i, it in ipairs(items) do
    if it.name == M.current_name then
      idx = i
      break
    end
  end
  idx = ((idx - 1 + direction) % #items) + 1
  M.set_manual(items[idx].name)
end

-- ---------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------

--- Called from colorscheme.lua before tokyonight setup. Reads persistence,
--- loads the active palette into M.current_palette. Must run before
--- tokyonight's first setup so the on_colors closure has a populated
--- current_palette on first fire.
function M.setup()
  local s = read_state()
  local initial = s.manual
  if not valid_theme(initial) then
    initial = DEFAULT_THEME
  end
  local palette = M.load(initial)
  M.current_palette = palette
  M.current_name = initial
end

return M
