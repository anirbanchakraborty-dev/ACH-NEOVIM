-- docs/key-card.md, the one-page key card, checked against the keys the
-- running configuration has. A key renamed, moved or removed fails here until
-- the card says the same.

local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")

local CARD = "/docs/key-card.md"

-- The sections whose tables have a Description column, in the card's order.
local SECTIONS = {
  "Files and buffers",
  "Search and moving",
  "Code",
  "Git",
  "Claude Code",
  "Debugging",
  "Windows and toggles",
  "Outside the menus",
}

-- The six Ghostty keys the spec names, each with the action Ghostty's own
-- defaults give it, as +list-keybinds prints the action after an =.
local GHOSTTY = {
  { "Command-T", "=new_tab" },
  { "Command-D", "=new_split:right" },
  { "Command-Shift-D", "=new_split:down" },
  { "Command-=", "=increase_font_size" },
  { "Command-minus", "=decrease_font_size" },
  { "Command-0", "=reset_font_size" },
}

-- The modes a key can be set in, one letter each.
local MODES = { "n", "x", "s", "o", "i", "c", "t" }

-- The card's names for keys that are not one character.
local NAMED = {
  Space = "<Space>",
  Tab = "<Tab>",
  Esc = "<Esc>",
  Enter = "<CR>",
  Up = "<Up>",
  Down = "<Down>",
  Left = "<Left>",
  Right = "<Right>",
  Backslash = "\\",
}

-- The card's names for the keys held down with another.
local MODIFIER = { Ctrl = "C", Alt = "A", Shift = "S" }

-- The cask installs the app and puts no ghostty command on the PATH, so the
-- command inside the app is used when the PATH has none.
local APP = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

local function ghostty()
  local bin = vim.fn.exepath("ghostty")
  if bin == "" and vim.fn.executable(APP) == 1 then
    bin = APP
  end
  return bin ~= "" and bin or nil
end

-- Every key a plugin spec declares, one entry per mode, in a stable order.
local function plugin_keys()
  local out = {}
  for name, plugin in pairs(Config.plugins) do
    for _, k in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
      k.plugin = name
      out[#out + 1] = k
    end
  end
  table.sort(out, function(a, b) return a.plugin .. a.id < b.plugin .. b.id end)
  return out
end

-- The which-key groups, found by walking the nested spec tables.
local function groups(spec, out)
  out = out or {}
  for _, item in ipairs(spec or {}) do
    if type(item) == "table" then
      if type(item[1]) == "string" and item.group then
        out[item[1]] = item.group
      end
      groups(item, out)
    end
  end
  return out
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- A key in one canonical spelling: vim.keycode turns it into the bytes the
-- key sends, putting the leader key in for <leader>, and vim.fn.keytrans
-- writes those bytes back, so "<leader>ff" and "<Space>ff" come out the same.
local function norm(lhs) return vim.fn.keytrans(vim.keycode(lhs)) end

-- A key as the card writes it, such as "Space f f", "Ctrl-/" or "Alt-Down",
-- in the same canonical spelling. Each word is one key, and a modifier is
-- joined to its key with a hyphen.
local function card_key(key)
  local out = {}
  for _, word in ipairs(vim.split(key, " ", { plain = true })) do
    local modifier, rest = word:match("^(%a+)%-(.+)$")
    if modifier and MODIFIER[modifier] then
      local inner = NAMED[rest] or rest
      out[#out + 1] = ("<%s-%s>"):format(MODIFIER[modifier], inner:match("^<(.+)>$") or inner)
    else
      out[#out + 1] = NAMED[word] or word
    end
  end
  return norm(table.concat(out))
end

-- Whether a key set in mode, a letter, a list of letters or nil for normal
-- mode alone, is set in normal mode. "" is normal, visual and operator mode.
local function normal(mode)
  if mode == nil then
    return true
  end
  if type(mode) == "string" then
    mode = { mode }
  end
  return vim.tbl_contains(mode, "n") or vim.tbl_contains(mode, "")
end

-- The cells of one table row, trimmed. A | inside a cell is written \|.
local function cells(line)
  local row = line:gsub("\\|", "\1"):match("^%s*|(.*)|%s*$") or ""
  local out = {}
  for cell in (row .. "|"):gmatch("([^|]*)|") do
    out[#out + 1] = vim.trim((cell:gsub("\1", "|")))
  end
  return out
end

-- The card's lines, and its tables, each { section, header, rows }: the
-- ## heading above the table, the cells of its first line, and the cells of
-- each line after the | --- | line.
local function read(t)
  local ok, lines = pcall(vim.fn.readfile, t.root .. CARD)
  t.ok(ok and #lines > 0, "docs/key-card.md exists")
  local tables, section, current = {}, "", nil
  for i, line in ipairs(lines) do
    if line:match("^## ") then
      section = line:sub(4)
    end
    if line:match("^|%s*%-%-%-") and i > 1 and lines[i - 1]:match("^|") then
      current = { section = section, header = cells(lines[i - 1]), rows = {} }
      tables[#tables + 1] = current
    elseif current and line:match("^|") then
      current.rows[#current.rows + 1] = cells(line)
    elseif not line:match("^|") then
      current = nil
    end
  end
  return tables, lines
end

-- The rows of the one table in section, after checking its header.
local function rows_of(t, tables, section, header)
  for _, tbl in ipairs(tables) do
    if tbl.section == section then
      t.eq(tbl.header, header, "the header of the table in " .. section)
      t.ok(#tbl.rows > 0, "the table in " .. section .. " has rows")
      return tbl.rows
    end
  end
  t.ok(false, "the card has a table in a section called " .. section)
  return {}
end

-- Every key set when this runs, each { lhs, desc } with lhs in the canonical
-- spelling: Neovim's keymaps, lazy.nvim's plugin keys, every vim.keymap.set
-- from lua/ach/, the language server's keys, and the keys git, LaTeX and
-- Markdown set on a buffer, read off a scratch buffer named x.md.
local function set_keys(t)
  local out = {}
  local function add(lhs, desc)
    if lhs and desc then
      out[#out + 1] = { lhs = norm(lhs), desc = desc }
    end
  end
  -- gitsigns sets its two toggles as it loads, and it loads on the first file
  -- read, which may not have happened yet.
  require("lazy").load({ plugins = { "gitsigns.nvim" } })
  tidy(function()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, t.tmpdir() .. "/x.md")
    require("ach.git").on_attach(buf)
    require("ach.latex").attach(buf)
    require("ach.preview").attach(buf)
    for _, mode in ipairs(MODES) do
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
        add(map.lhs, map.desc)
      end
    end
  end)
  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      add(map.lhs, map.desc)
    end
  end
  for _, k in ipairs(plugin_keys()) do
    add(k.lhs, k.desc)
  end
  for _, k in ipairs(require("ach.testhook").keymaps) do
    add(k.lhs, k.desc)
  end
  for _, k in ipairs(require("ach.lsp").keys) do
    add(k[1], k.desc)
  end
  return out
end

return {
  ["every key in a Description table is set, with that description"] = function(t)
    local tables = read(t)
    local sections, rows = {}, {}
    for _, tbl in ipairs(tables) do
      if tbl.header[2] == "Description" then
        t.eq(tbl.header, { "Key", "Description", "What it does" }, "the header of the table in " .. tbl.section)
        sections[#sections + 1] = tbl.section
        for _, row in ipairs(tbl.rows) do
          local key = row[1]:match("^`([^`]+)`$")
          t.ok(key ~= nil and #row == 3, "a row is one key in backticks, then two cells: " .. table.concat(row, " | "))
          rows[#rows + 1] = { key = key, desc = row[2] }
        end
      end
    end
    t.eq(sections, SECTIONS, "the sections with a Description table")
    local have = {}
    for _, k in ipairs(set_keys(t)) do
      have[k.lhs .. "\n" .. k.desc] = true
    end
    local missing = {}
    for _, row in ipairs(rows) do
      if not have[card_key(row.key) .. "\n" .. row.desc] then
        missing[#missing + 1] = row.key .. ": " .. row.desc
      end
    end
    t.eq(missing, {}, "keys on the card that no key matches, with that description")
  end,

  ["the menus table is which-key's Space menus, both ways"] = function(t)
    local card = {}
    for _, row in ipairs(rows_of(t, read(t), "The menus", { "Keys", "Menu", "For" })) do
      local key = row[1]:match("^`([^`]+)`$")
      t.ok(key ~= nil, "a menu row starts with one key in backticks: " .. row[1])
      card[card_key(key)] = row[2]
    end
    local spec = Plugin.values(Config.plugins["which-key.nvim"], "opts", false).spec
    local menus = {}
    for lhs, name in pairs(groups(spec)) do
      local rest = norm(lhs):match("^<Space>(.+)$")
      if rest and (vim.fn.strchars(rest) == 1 or rest:match("^<[^>]+>$")) then
        menus[norm(lhs)] = name
      end
    end
    t.ok(next(menus) ~= nil, "which-key has groups after Space")
    t.eq(card, menus, "the menus on the card, against which-key's groups after Space")
  end,

  ["the keys in Neovim's own table are still Neovim's own"] = function(t)
    local own = {}
    for _, row in ipairs(rows_of(t, read(t), "Neovim's own keys", { "Key", "What it does" })) do
      for key in row[1]:gmatch("`([^`]+)`") do
        own[card_key(key)] = key
      end
    end
    local set = {}
    for _, k in ipairs(plugin_keys()) do
      if normal(k.mode) then
        set[#set + 1] = { k.lhs, "the spec for " .. k.plugin }
      end
    end
    for _, k in ipairs(require("ach.testhook").keymaps) do
      if normal(k.mode) then
        set[#set + 1] = { k.lhs, k.where }
      end
    end
    for _, k in ipairs(require("ach.lsp").keys) do
      if normal(k.mode) then
        set[#set + 1] = { k[1], "ach.lsp.keys" }
      end
    end
    local taken = {}
    for _, s in ipairs(set) do
      local key = own[norm(s[1])]
      if key then
        taken[#taken + 1] = ("%s is set in normal mode by %s"):format(key, s[2])
      end
    end
    table.sort(taken)
    t.eq(taken, {}, "Neovim's own keys this configuration sets")
  end,

  ["the card names Ghostty's keys, and the settings give none a new job"] = function(t)
    local _, lines = read(t)
    local named, inside = {}, false
    for _, line in ipairs(lines) do
      if line:match("^## ") then
        inside = line == "## Ghostty's keys"
      end
      if inside then
        for key in line:gmatch("`([^`]+)`") do
          named[key] = true
        end
      end
    end
    local missing = {}
    for _, pair in ipairs(GHOSTTY) do
      if not named[pair[1]] then
        missing[#missing + 1] = pair[1]
      end
    end
    t.eq(missing, {}, "Ghostty keys the section Ghostty's keys leaves out")
    local ok, conf = pcall(vim.fn.readfile, t.root .. "/ghostty/config.ghostty")
    t.ok(ok and #conf > 0, "ghostty/config.ghostty exists and is not empty")
    local rebound = {}
    for _, line in ipairs(conf) do
      local value = line:match("^%s*keybind%s*=%s*(.-)%s*$")
      if value then
        local v = value:lower()
        if v:find("super+", 1, true) or v:find("cmd+", 1, true) or v:find("command+", 1, true) then
          rebound[#rebound + 1] = line
        end
      end
    end
    t.eq(rebound, {}, "keybind lines in ghostty/config.ghostty that change a Command key")
  end,

  ["Ghostty's defaults still give the Command keys the jobs the card names"] = function(t)
    read(t)
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+list-keybinds", "--default", "--plain" }, { text = true }):wait(30000)
    t.eq(r.code, 0, "ghostty +list-keybinds, which printed: " .. (r.stderr or ""))
    local missing = {}
    for _, pair in ipairs(GHOSTTY) do
      local found = false
      for line in (r.stdout or ""):gmatch("[^\n]+") do
        if line:find("super+", 1, true) and line:find(pair[2], 1, true) then
          found = true
          break
        end
      end
      if not found then
        missing[#missing + 1] = pair[1] .. " (" .. pair[2]:sub(2) .. ")"
      end
    end
    t.eq(missing, {}, "keys whose action no Command key has among Ghostty's defaults")
  end,
}
