-- The keys this configuration sets, recorded in docs/site/keymaps.json for
-- scripts/docs, which writes the post's Keymaps section without starting the
-- configuration. Keys exist only once the configuration runs, so they are read
-- in a child Neovim and kept as a file, and tests/test_docs.lua fails when the
-- file and the configuration disagree.
--   nvim -l tests/helpers/keymaps.lua ROOT OUT   writes OUT; scripts/check --keymaps runs this
local M = {}

M.FILE = "/docs/site/keymaps.json"

-- The modes a key can be set in, one letter each, in the order the file
-- writes them.
M.MODES = { "n", "x", "s", "o", "i", "c", "t" }

-- The letters each of Neovim's combined modes stands for.
local SHORT = { [""] = { "n", "x", "s", "o" }, v = { "x", "s" }, ["!"] = { "i", "c" }, l = { "i", "c" } }

-- A key in one canonical spelling: vim.keycode turns it into the bytes the
-- key sends, putting the leader key in for <leader>, and vim.fn.keytrans
-- writes those bytes back, so "<leader>ff" and "<Space>ff" come out the same.
local function norm(lhs) return vim.fn.keytrans(vim.keycode(lhs)) end

-- The mode letters a key set in mode works in: mode is a letter, a list of
-- letters, or nil for normal mode alone.
local function letters(mode)
  if mode == nil then
    return { "n" }
  end
  if type(mode) == "string" then
    mode = { mode }
  end
  local out = {}
  for _, m in ipairs(mode) do
    vim.list_extend(out, SHORT[m] or { m })
  end
  return out
end

-- Every key a plugin spec declares, one entry per mode.
local function plugin_keys()
  local Config = require("lazy.core.config")
  local Plugin = require("lazy.core.plugin")
  local Keys = require("lazy.core.handler.keys")
  local out = {}
  for _, plugin in pairs(Config.plugins) do
    for _, k in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
      out[#out + 1] = k
    end
  end
  return out
end

-- Every key set when this runs, each { lhs, modes, desc }, sorted by key and
-- then description. A key set twice with one description, in different modes
-- or from different places, is one entry with the modes merged. Runs inside a
-- Neovim with the configuration loaded.
function M.collect()
  local found = {}
  local function add(lhs, desc, mode)
    -- which-key sets keys of its own to open its menus, and <Plug> keys are
    -- names for other keys to call, never pressed.
    if type(lhs) ~= "string" or type(desc) ~= "string" or desc == "" then
      return
    end
    if desc:match("^which[-_]key") or lhs:match("^<Plug>") then
      return
    end
    local key = norm(lhs)
    local id = key .. "\n" .. desc
    found[id] = found[id] or { key, {}, desc }
    for _, letter in ipairs(letters(mode)) do
      found[id][2][letter] = true
    end
  end

  -- gitsigns sets its two toggles as it loads, and it loads on the first file
  -- read, which may not have happened yet.
  require("lazy").load({ plugins = { "gitsigns.nvim" } })
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, dir .. "/x.md")
  local ok, err = pcall(function()
    require("ach.git").on_attach(buf)
    require("ach.latex").attach(buf)
    require("ach.preview").attach(buf)
    for _, mode in ipairs(M.MODES) do
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
        add(map.lhs, map.desc, mode)
      end
    end
  end)
  vim.api.nvim_buf_delete(buf, { force = true })
  if not ok then
    error(err, 0)
  end

  -- Neovim's own table also holds the keys Neovim sets for itself, so only
  -- the keys under Space are taken from it. Every other key this
  -- configuration sets is in one of the three lists below.
  for _, mode in ipairs(M.MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if type(map.lhs) == "string" and norm(map.lhs):match("^<Space>") then
        add(map.lhs, map.desc, mode)
      end
    end
  end
  for _, k in ipairs(plugin_keys()) do
    add(k.lhs, k.desc, k.mode)
  end
  for _, k in ipairs(require("ach.testhook").keymaps) do
    add(k.lhs, k.desc, k.mode)
  end
  for _, k in ipairs(require("ach.lsp").keys) do
    add(k[1], k.desc, k.mode)
  end

  local out = {}
  for _, entry in pairs(found) do
    local modes = {}
    for _, letter in ipairs(M.MODES) do
      if entry[2][letter] then
        modes[#modes + 1] = letter
      end
    end
    if #modes > 0 then
      out[#out + 1] = { entry[1], table.concat(modes), entry[3] }
    end
  end
  table.sort(out, function(a, b)
    if a[1] ~= b[1] then
      return a[1] < b[1]
    end
    return a[3] < b[3]
  end)
  return out
end

-- Writes keys as a JSON list, one key to a line, so a change shows in git as
-- the lines of the keys that changed.
function M.write(path, keys)
  local lines = {}
  for i, k in ipairs(keys) do
    lines[i] = "  " .. vim.json.encode(k) .. (i < #keys and "," or "")
  end
  local f = assert(io.open(path, "wb"))
  f:write("[\n" .. table.concat(lines, "\n") .. (#lines > 0 and "\n" or "") .. "]\n")
  f:close()
end

-- The keys docs/site/keymaps.json holds.
function M.read(root)
  local f = assert(io.open(root .. M.FILE, "rb"))
  local text = f:read("*a")
  f:close()
  return vim.json.decode(text)
end

-- The keys set now, read in a child Neovim with the configuration loaded.
function M.snapshot(t)
  local child = dofile(t.root .. "/tests/helpers/child.lua")
  return child.run(t, ("report(dofile(%q).collect())"):format(t.root .. "/tests/helpers/keymaps.lua"))
end

if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "keymaps.lua" then
  local root, out = _G.arg[1], _G.arg[2]
  local t = {
    root = root,
    tmpdir = function()
      local dir = vim.fn.tempname()
      vim.fn.mkdir(dir, "p")
      return dir
    end,
  }
  local ok, err = pcall(function()
    local keys = M.snapshot(t)
    M.write(out, keys)
    io.stdout:write(("Wrote %s: %d keys.\n"):format(vim.fs.basename(out), #keys))
  end)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    os.exit(1)
  end
end

return M
