local function hex(s) return tonumber(s:sub(2), 16) end

local function sample(t, name, lines)
  local dir = t.tmpdir()
  vim.fn.writefile(lines or { "" }, dir .. "/" .. name)
  vim.cmd("silent only")
  vim.cmd.cd(dir)
  vim.cmd.edit(dir .. "/" .. name)
  vim.b.gitsigns_status_dict = nil
  return dir
end

-- Draws the bar and returns its text and its runs of one background colour.
local function draw(columns)
  vim.o.columns = columns or 200
  require("lualine").refresh({ force = true, place = { "statusline" } })
  -- lualine writes the drawn bar into the window's own statusline value.
  local stl = vim.wo.statusline ~= "" and vim.wo.statusline or vim.go.statusline
  local res = vim.api.nvim_eval_statusline(stl, { highlights = true, maxwidth = vim.o.columns })
  local runs = {}
  for i, h in ipairs(res.highlights) do
    local stop = res.highlights[i + 1] and res.highlights[i + 1].start or #res.str
    local text = res.str:sub(h.start + 1, stop)
    -- Neovim 0.12 lists stacked groups in `groups`; the last one is drawn on top.
    local group = h.groups and h.groups[#h.groups] or h.group
    local bg = group and group ~= "" and vim.api.nvim_get_hl(0, { name = group, link = false }).bg or nil
    local last = runs[#runs]
    if last and last.bg == bg then
      last.text = last.text .. text
    elseif text ~= "" then
      table.insert(runs, { text = text, bg = bg })
    end
  end
  return res, runs
end

-- Runs fn with every optional tile given something to show, then removes the stubs.
local function with_stubs(fn)
  local saved = { claude = package.loaded["ach.claude"], lint = package.loaded["ach.lint"] }
  package.loaded["ach.claude"] = { status = function() return "connected" end }
  package.loaded["ach.lint"] = { linters_for = function() return { "selene" } end }
  vim.fn.reg_recording = function() return "q" end
  vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 3 }
  local ns = vim.api.nvim_create_namespace("ach_test_statusline")
  vim.diagnostic.set(ns, 0, {
    { lnum = 0, col = 0, message = "e", severity = vim.diagnostic.severity.ERROR },
    { lnum = 0, col = 0, message = "w", severity = vim.diagnostic.severity.WARN },
    { lnum = 0, col = 0, message = "i", severity = vim.diagnostic.severity.INFO },
    { lnum = 0, col = 0, message = "h", severity = vim.diagnostic.severity.HINT },
  })
  vim.fn.setreg("/", "a")
  vim.o.hlsearch = true
  vim.v.hlsearch = 1
  local ok, err = pcall(fn)
  package.loaded["ach.claude"], package.loaded["ach.lint"] = saved.claude, saved.lint
  vim.fn.reg_recording = nil
  vim.diagnostic.reset(ns, 0)
  vim.cmd("nohlsearch")
  if not ok then
    error(err, 0)
  end
end

return {
  ["lualine provides the components the bar uses"] = function(t)
    for _, name in ipairs({ "mode", "diagnostics", "lsp_status", "location", "progress" }) do
      t.ok(pcall(require, "lualine.components." .. name), "lualine component " .. name)
    end
  end,

  ["draws the mode tile in the mode's colour, then a one-cell gap, then the file tile"] = function(t)
    local p = require("ach.palette")
    sample(t, "alpha.lua", { "return 1" })
    local _, runs = draw()
    t.eq(runs[1].bg, hex(p.line.blue), "normal-mode tile")
    t.ok(runs[1].text:find("NORMAL", 1, true), "mode name in " .. runs[1].text)
    t.eq(runs[2], { text = " ", bg = hex(p.bg_dark) }, "gap")
    t.eq(runs[3].bg, hex(p.line.bg), "file tile")
    t.ok(runs[3].text:find("alpha.lua", 1, true), "file name in " .. runs[3].text)
  end,

  ["gives each mode its colour, with readable text"] = function(t)
    local p = require("ach.palette")
    local ratio = require("ach.contrast").ratio
    local theme = require("ach.statusline").theme()
    local want = {
      normal = "blue",
      insert = "green",
      terminal = "green",
      visual = "violet",
      command = "yellow",
      replace = "red",
    }
    for mode, colour in pairs(want) do
      t.eq(theme[mode].a.bg, p.line[colour], mode)
      t.ok(ratio(theme[mode].a.fg, theme[mode].a.bg) >= 4.5, mode .. " text contrast")
    end
    t.ok(ratio(p.line.fg, p.line.bg) >= 4.5, "tile text contrast")
  end,

  ["outside a git repository, drops the branch tile and names the working folder"] = function(t)
    local sl = require("ach.statusline")
    local p = require("ach.palette")
    local dir = sample(t, "notes.txt", { "one two" })
    local res, runs = draw()
    t.ok(not res.str:find(sl.icons.branch, 1, true), "no branch icon")
    t.eq(runs[2], { text = " ", bg = hex(p.bg_dark) }, "a single gap after the mode tile")
    t.ok(runs[3].text:find(vim.fs.basename(dir), 1, true), "working folder's name in " .. runs[3].text)
  end,

  ["inside a git repository, shows the branch and the changed-line counts"] = function(t)
    local sl = require("ach.statusline")
    local dir = sample(t, "alpha.lua", { "return 1" })
    vim.system({ "git", "init", "-q", dir }):wait()
    vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 0 }
    local res = draw()
    t.ok(res.str:find(sl.icons.branch .. " main", 1, true), "branch")
    t.ok(res.str:find(sl.icons.added .. " 2", 1, true), "added")
    t.ok(res.str:find(sl.icons.modified .. " 1", 1, true), "changed")
    t.ok(not res.str:find(sl.icons.removed, 1, true), "a zero count is hidden")
  end,

  ["shows the plain file icon for XML, whose own icon is an angle bracket"] = function(t)
    local glyphs = require("ach.glyphs")
    local own = require("mini.icons").get("file", "a.xml")
    t.ok(#glyphs.offending(own) > 0, "premise: mini.icons gives XML a forbidden icon")
    sample(t, "a.xml", { "<a/>" })
    local res = draw()
    t.ok(res.str:find(glyphs.fallback, 1, true), "plain file icon shown")
    t.ok(not res.str:find(own, 1, true), "XML's own icon not shown")
  end,

  ["names the function around the cursor"] = function(t)
    sample(t, "alpha.lua", { "local M = {}", "function M.alpha()", "  local x = 1", "  return x", "end", "return M" })
    vim.treesitter.start(0, "lua")
    vim.treesitter.get_parser(0, "lua"):parse()
    vim.api.nvim_win_set_cursor(0, { 3, 2 })
    t.eq(require("ach.statusline").context(), "M.alpha")
  end,

  ["shows a red dot and the register while recording"] = function(t)
    sample(t, "alpha.lua", { "return 1" })
    vim.fn.reg_recording = function() return "q" end
    local ok, res = pcall(draw)
    vim.fn.reg_recording = nil
    t.ok(ok, tostring(res))
    t.ok(res.str:find("\u{25CF} q", 1, true), "recording mark in " .. res.str)
  end,

  ["counts words in prose"] = function(t)
    sample(t, "note.md", { "one two three" })
    local res = draw()
    t.ok(res.str:find("3 words", 1, true), "word count in " .. res.str)
  end,

  ["draws no forbidden glyph with every tile showing"] = function(t)
    local glyphs = require("ach.glyphs")
    local found = {}
    local files = {
      { "alpha.lua", { "local M = {}", "function M.alpha()", "  return 1", "end" } },
      { "note.md", { "a b" } },
    }
    for _, file in ipairs(files) do
      sample(t, file[1], file[2])
      with_stubs(function()
        local res = draw()
        for _, cp in ipairs(glyphs.offending(res.str)) do
          table.insert(found, ("U+%04X in %s"):format(cp, file[1]))
        end
      end)
    end
    t.eq(found, {}, "forbidden glyphs in the status bar")
  end,

  ["uses no forbidden glyph among its own icons"] = function(t)
    local glyphs = require("ach.glyphs")
    local found = {}
    for name, icon in pairs(require("ach.statusline").icons) do
      if #glyphs.offending(icon) > 0 then
        table.insert(found, name)
      end
    end
    t.eq(found, {})
  end,

  ["fits an 80-column window without truncating"] = function(t)
    sample(t, "alpha.lua", { "return 1" })
    vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 3 }
    local res = draw(80)
    t.ok(res.width <= 80, "width " .. res.width)
    t.ok(not res.str:find("<", 1, true), "Neovim's truncation mark appeared: " .. res.str)
  end,

  ["mini.icons draws the icon database's file-type icons"] = function(t)
    local I, mini = require("ach.icons"), require("mini.icons")
    local wrong = {}
    for category, kind in pairs({ filetype = "filetypes", extension = "extensions", file = "filenames" }) do
      for name, e in pairs(I[kind]) do
        local glyph, hl = mini.get(category, name)
        local want = "MiniIcons" .. e[2]:sub(1, 1):upper() .. e[2]:sub(2)
        if glyph ~= I.get(e[1]) or hl ~= want then
          wrong[#wrong + 1] = ("%s %s draws %s in %s"):format(category, name, tostring(glyph), tostring(hl))
        end
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "file types mini.icons draws differently")
  end,
}
