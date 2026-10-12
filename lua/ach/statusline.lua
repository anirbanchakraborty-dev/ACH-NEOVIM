-- The status bar: square tiles on the bar's navy, one blank cell between
-- neighbours, and the outermost tile on each side in the mode's colour.
-- Colours come only from lua/ach/palette.lua, and file-type icons pass through
-- lua/ach/glyphs.lua, so nothing angled reaches the bar.
local glyphs = require("ach.glyphs")
local p = require("ach.palette")
local util = require("ach.util")

local M = {}
local line, base = p.line, p.bg_dark

-- The bar's glyphs: the status table of the icon database, where each is named
-- by its Nerd Fonts 3.5.1 name. tests/test_icons.lua keeps every one of them out
-- of the forbidden set, and the test below checks the same from the bar's side.
M.icons = require("ach.icons").status

-- Text colours inside a tile, each on the tile's own background.
M.colors = {
  text = line.fg,
  dim = line.semilightgray,
  blue = line.blue,
  green = line.green,
  violet = line.violet,
  yellow = line.yellow,
  red = line.red,
}

-- File types whose word count is shown.
M.prose = {
  markdown = true,
  ["markdown.mdx"] = true,
  mdx = true,
  tex = true,
  plaintex = true,
  text = true,
  gitcommit = true,
  typst = true,
}

local function hl(name) return "%#AchSl_" .. name .. "#" end

-- Text from a file or a plugin goes through this, so a % in it prints as %.
local function esc(s) return (tostring(s):gsub("%%", "%%%%")) end

local icon_groups = {}

function M.set_highlights()
  icon_groups = {}
  for name, fg in pairs(M.colors) do
    vim.api.nvim_set_hl(0, "AchSl_" .. name, { fg = fg, bg = line.bg })
  end
end

-- A copy of a file-type icon's highlight group, on the tile's background.
local function icon_hl(group)
  if not icon_groups[group] then
    local name = "AchSl_icon_" .. (group:gsub("[^%w_]", "_"))
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    vim.api.nvim_set_hl(0, name, { fg = fg or tonumber(line.fg:sub(2), 16), bg = line.bg })
    icon_groups[group] = "%#" .. name .. "#"
  end
  return icon_groups[group]
end

function M.theme()
  local function mode(colour)
    return {
      a = { bg = colour, fg = p.bg, gui = "bold" },
      b = { bg = line.bg, fg = line.fg },
      c = { bg = base, fg = line.fg },
    }
  end
  local inactive = { bg = line.inactive_bg, fg = line.semilightgray }
  return {
    normal = mode(line.blue),
    insert = mode(line.green),
    terminal = mode(line.green),
    visual = mode(line.violet),
    command = mode(line.yellow),
    replace = mode(line.red),
    inactive = { a = inactive, b = inactive, c = inactive },
  }
end

function M.git()
  local g = vim.b.gitsigns_status_dict
  if type(g) ~= "table" or not g.head or g.head == "" then
    return ""
  end
  local s = hl("violet") .. M.icons.branch .. " " .. hl("text") .. esc(g.head)
  local diffs = { { "added", "added", "green" }, { "changed", "modified", "yellow" }, { "removed", "removed", "red" } }
  for _, d in ipairs(diffs) do
    local count = g[d[1]] or 0
    if count > 0 then
      s = s .. " " .. hl(d[3]) .. M.icons[d[2]] .. " " .. hl("text") .. count
    end
  end
  return s
end

function M.filetype_icon(name)
  local ok, icons = pcall(require, "mini.icons")
  if not ok then
    return glyphs.fallback, "AchSl_text"
  end
  local icon, group = icons.get("file", name)
  return glyphs.safe_icon(icon), group
end

-- Tree-sitter node kinds that name a scope worth showing.
local SCOPES = { "function", "method", "class", "struct", "impl", "module", "interface", "trait", "enum", "namespace" }

local function is_scope(kind)
  if kind:find("call", 1, true) then
    return false
  end
  for _, word in ipairs(SCOPES) do
    if kind:find(word, 1, true) then
      return true
    end
  end
  return false
end

-- A scope's name: its name field, or the identifier at the end of a C-style
-- declarator chain, or for a Rust impl the type it implements.
local function name_of(node, kind, buf)
  local target = node:field("name")[1]
  if not target then
    local d = node:field("declarator")[1]
    while d and not d:type():find("identifier", 1, true) do
      d = d:field("declarator")[1] or d:named_child(0)
    end
    target = d
  end
  if not target and kind:find("impl", 1, true) then
    target = node:field("type")[1]
  end
  if not target then
    return nil
  end
  return (vim.treesitter.get_node_text(target, buf):gsub("%s+", " "))
end

-- Where the cursor sits in the code, outermost first, such as "Parser · parse".
function M.context()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.treesitter.highlighter.active[buf] then
    return ""
  end
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
  if not ok or not node then
    return ""
  end
  local names = {}
  while node do
    local kind = node:type()
    if is_scope(kind) then
      local name = name_of(node, kind, buf)
      if name then
        table.insert(names, 1, name)
      end
    end
    node = node:parent()
  end
  local s = table.concat(names, " · ")
  local n = vim.fn.strchars(s)
  if n > 40 then
    s = "…" .. vim.fn.strcharpart(s, n - 39)
  end
  return s
end

function M.file()
  local buf = vim.api.nvim_get_current_buf()
  local root = util.root(buf)
  local s = hl("blue") .. M.icons.project .. " " .. hl("text") .. esc(vim.fs.basename(root))
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return s
  end
  local icon, group = M.filetype_icon(name)
  local path = vim.fs.relpath(root, name) or vim.fn.fnamemodify(name, ":~")
  s = s .. "  " .. icon_hl(group) .. icon .. " " .. hl("text") .. esc(path)
  if vim.bo[buf].modified then
    s = s .. " " .. hl("yellow") .. M.icons.unsaved
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    s = s .. " " .. hl("red") .. M.icons.readonly
  end
  local where = vim.o.columns >= 120 and M.context() or ""
  if where ~= "" then
    s = s .. "  " .. hl("dim") .. esc(where)
  end
  return s
end

function M.has_diagnostics() return #vim.diagnostic.get(0) > 0 end

-- The selection's size: characters within a line, lines across several, and
-- lines by columns for a block.
function M.selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return ""
  end
  local l1, c1, l2, c2 = vim.fn.line("v"), vim.fn.col("v"), vim.fn.line("."), vim.fn.col(".")
  local lines = math.abs(l2 - l1) + 1
  if mode == "\22" then
    return ("%d×%d"):format(lines, math.abs(c2 - c1) + 1)
  elseif mode == "V" or lines > 1 then
    return lines .. (lines == 1 and " line" or " lines")
  end
  local chars = math.abs(c2 - c1) + 1
  return chars .. (chars == 1 and " char" or " chars")
end

function M.activity()
  local parts = {}
  local reg = vim.fn.reg_recording()
  if reg ~= "" then
    table.insert(parts, hl("red") .. M.icons.recording .. " " .. hl("text") .. reg)
  end
  if vim.v.hlsearch == 1 then
    local ok, count = pcall(vim.fn.searchcount, { maxcount = 9999, timeout = 50 })
    if ok and (count.total or 0) > 0 then
      table.insert(parts, hl("yellow") .. M.icons.search .. " " .. hl("text") .. count.current .. "/" .. count.total)
    end
  end
  local size = M.selection()
  if size ~= "" then
    table.insert(parts, hl("violet") .. M.icons.selection .. " " .. hl("text") .. size)
  end
  return table.concat(parts, " ")
end

function M.claude()
  local claude = package.loaded["ach.claude"]
  local state = claude and claude.status() or "off"
  if state == "connected" then
    return hl("violet") .. M.icons.claude .. " Claude"
  elseif state == "waiting" then
    return hl("dim") .. M.icons.claude .. " Claude"
  end
  return ""
end

-- The formatter that will run on save and the linters watching this buffer.
function M.tools()
  local buf = vim.api.nvim_get_current_buf()
  local parts = {}
  local conform = package.loaded["conform"]
  if conform and vim.g.autoformat ~= false and vim.b[buf].autoformat ~= false then
    local names = {}
    for _, f in ipairs(conform.list_formatters_to_run(buf)) do
      table.insert(names, f.name)
    end
    if #names > 0 then
      table.insert(parts, hl("violet") .. M.icons.formatter .. " " .. hl("text") .. esc(table.concat(names, " ")))
    end
  end
  local lint = package.loaded["ach.lint"]
  if lint then
    local names = lint.linters_for(buf)
    if #names > 0 then
      table.insert(parts, hl("yellow") .. M.icons.linter .. " " .. hl("text") .. esc(table.concat(names, " ")))
    end
  end
  return table.concat(parts, " ")
end

function M.has_code_tools() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 or M.tools() ~= "" end

function M.words()
  if not M.prose[vim.bo.filetype] then
    return ""
  end
  local count = vim.fn.wordcount()
  local n = count.visual_words or count.words
  return hl("blue") .. M.icons.words .. " " .. hl("text") .. n .. (n == 1 and " word" or " words")
end

function M.updates()
  local parts = {}
  local ok, status = pcall(require, "lazy.status")
  if ok and status.has_updates() then
    local n = #require("lazy.manage.checker").updated
    table.insert(parts, hl("yellow") .. M.icons.updates .. " " .. hl("text") .. n)
  end
  local dap = package.loaded["dap"]
  if dap then
    local state = dap.status()
    if state ~= "" then
      table.insert(parts, hl("red") .. M.icons.dap .. " " .. hl("text") .. esc(state))
    end
  end
  return table.concat(parts, " ")
end

function M.format()
  local width = vim.bo.shiftwidth
  if width == 0 then
    width = vim.bo.tabstop
  end
  local s = hl("blue") .. M.icons.indent .. " " .. hl("text") .. (vim.bo.expandtab and "SPC " or "TAB ") .. width
  local encoding = vim.bo.fileencoding
  if encoding ~= "" and encoding ~= "utf-8" then
    s = s .. " " .. encoding
  end
  if vim.bo.fileformat ~= "unix" then
    s = s .. " " .. vim.bo.fileformat
  end
  return s
end

-- One cell of the bar's own navy, shown only when the tile beside it is.
local function gap(cond)
  return {
    function() return " " end,
    padding = 0,
    color = { bg = base },
    cond = cond,
  }
end

local function shown(fn)
  return function() return fn() ~= "" end
end

function M.options()
  local tile = { fg = line.fg, bg = line.bg }
  return {
    options = {
      theme = M.theme(),
      globalstatus = true,
      component_separators = "",
      section_separators = "",
      disabled_filetypes = { statusline = { "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { { "mode", icon = M.icons.vim } },
      lualine_b = {},
      lualine_c = {
        gap(shown(M.git)),
        { M.git, color = tile },
        gap(),
        { M.file, color = tile },
        gap(M.has_diagnostics),
        {
          "diagnostics",
          color = tile,
          symbols = {
            error = M.icons.error .. " ",
            warn = M.icons.warn .. " ",
            info = M.icons.info .. " ",
            hint = M.icons.hint .. " ",
          },
          diagnostics_color = {
            error = { fg = line.red, bg = line.bg },
            warn = { fg = line.yellow, bg = line.bg },
            info = { fg = line.blue, bg = line.bg },
            hint = { fg = line.green, bg = line.bg },
          },
        },
      },
      lualine_x = {
        { M.updates, color = tile },
        gap(shown(M.updates)),
        { M.activity, color = tile },
        gap(shown(M.activity)),
        { M.claude, color = tile },
        gap(shown(M.claude)),
        -- lualine's own defaults already end a ready server with ✓, U+2713.
        { "lsp_status", icon = M.icons.lsp, color = tile },
        { M.tools, color = tile },
        gap(M.has_code_tools),
        { M.words, color = tile },
        gap(shown(M.words)),
      },
      lualine_y = { { M.format }, gap() },
      lualine_z = { { "location" }, { "progress" } },
    },
  }
end

function M.setup(opts)
  M.set_highlights()
  local group = vim.api.nvim_create_augroup("ach_statusline", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.set_highlights })
  -- Show or clear the recording mark at once, not at the next timed refresh.
  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = group,
    callback = function()
      vim.schedule(function() require("lualine").refresh({ place = { "statusline" } }) end)
    end,
  })
  require("lualine").setup(opts)
end

return M
