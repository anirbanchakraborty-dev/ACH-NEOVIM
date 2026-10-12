local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")

local function mapped(lhs, mode) return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil end

-- The function a plugin's spec binds to a normal-mode key. Calling lazy's stub
-- instead would replay the keys later, after the test has finished looking.
local function bound(plugin, lhs)
  local spec = Config.plugins[plugin]
  assert(spec, plugin .. " is not in the plugin list")
  for _, k in pairs(Keys.resolve(Plugin.values(spec, "keys", true))) do
    if k.lhs == lhs and k.mode == "n" then
      return k.rhs
    end
  end
  error(plugin .. " binds nothing to " .. lhs)
end

-- A three-line file with one quickfix entry per line, positioned on the first.
local function three_item_list(t)
  local file = t.tmpdir() .. "/three.txt"
  vim.fn.writefile({ "one", "two", "three" }, file)
  vim.fn.setqflist({}, " ", {
    items = {
      { filename = file, lnum = 1, text = "one" },
      { filename = file, lnum = 2, text = "two" },
      { filename = file, lnum = 3, text = "three" },
    },
  })
  vim.cmd("cfirst")
  return file
end

local function qf_index() return vim.fn.getqflist({ idx = 0 }).idx end

local function wipe(file)
  vim.fn.setqflist({}, "r")
  vim.cmd("silent! bwipeout! " .. vim.fn.fnameescape(file))
end

return {
  ["the keys the spec names exist"] = function(t)
    local want = {
      { "<leader>e" },
      { "<leader>fe" },
      { "<leader>fo" },
      { "<leader>sr" },
      { "<leader>xx" },
      { "<leader>xX" },
      { "<leader>cs" },
      { "<leader>xL" },
      { "<leader>xQ" },
      { "[q" },
      { "]q" },
      { "]t" },
      { "[t" },
      { "<leader>st" },
      { "<leader>xt" },
      { "<leader>qs" },
      { "<leader>ql" },
      { "<leader>qS" },
      { "<leader>qd" },
      { "<leader>mn" },
      { "<leader>mA" },
      { "<A-Down>" },
      { "<leader>ue" },
      { "s" },
      { "s", "x" },
      { "s", "o" },
      { "S" },
      { "<c-space>" },
      { "<c-s>", "c" },
    }
    local missing = {}
    for _, k in ipairs(want) do
      if not mapped(k[1], k[2]) then
        missing[#missing + 1] = (k[2] or "n") .. " " .. k[1]
      end
    end
    t.eq(missing, {}, "keys the spec names")
  end,

  ["]q and [q walk the quickfix list while trouble is closed"] = function(t)
    local next_item, prev_item = bound("trouble.nvim", "]q"), bound("trouble.nvim", "[q")
    local file = three_item_list(t)
    t.ok(not require("trouble").is_open(), "trouble starts closed")
    next_item()
    local index, line = qf_index(), vim.fn.line(".")
    prev_item()
    local back = qf_index()
    wipe(file)
    t.eq(index, 2, "quickfix entry after ]q")
    t.eq(line, 2, "cursor line after ]q")
    t.eq(back, 1, "quickfix entry after [q")
  end,

  ["]q on the last entry warns instead of raising"] = function(t)
    local next_item = bound("trouble.nvim", "]q")
    local file = three_item_list(t)
    vim.cmd("clast")
    local ok, err = pcall(next_item)
    local index = qf_index()
    wipe(file)
    t.ok(ok, "]q raised: " .. tostring(err))
    t.eq(index, 3, "quickfix entry after ]q on the last one")
  end,

  ["sessions are saved under the state folder, never in the repository"] = function(t)
    require("lazy").load({ plugins = { "persistence.nvim" } })
    local dir = require("persistence.config").options.dir
    t.ok(vim.startswith(dir, vim.fn.stdpath("state")), "sessions go to " .. tostring(dir))
    t.ok(not vim.startswith(dir, t.root), "sessions go into the repository: " .. tostring(dir))
  end,

  ["a hex colour gets a swatch"] = function(t)
    require("lazy").load({ plugins = { "mini.hipatterns" } })
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "border = #547998" })
    require("mini.hipatterns").enable(buf)
    -- mini.hipatterns names the group after the lower-case digits and the style.
    local group = "MiniHipatterns_547998_bg"
    local found = vim.wait(2000, function()
      for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
        if m[4].hl_group == group then
          return true
        end
      end
      return false
    end, 50)
    vim.api.nvim_buf_delete(buf, { force = true })
    t.ok(found, "no " .. group .. " highlight on the hex colour")
  end,

  ["the status column is drawn by snacks"] = function(t)
    t.ok(vim.o.statuscolumn:find("snacks.statuscolumn", 1, true), "statuscolumn is " .. vim.o.statuscolumn)
  end,

  ["oil opens a folder as an editable buffer"] = function(t)
    local dir = t.tmpdir()
    vim.fn.writefile({}, dir .. "/a.txt")
    vim.cmd("Oil " .. vim.fn.fnameescape(dir))
    local opened = vim.wait(3000, function() return vim.bo.filetype == "oil" end, 50)
    local ft, name = vim.bo.filetype, vim.api.nvim_buf_get_name(0)
    vim.cmd("silent! bwipeout!")
    t.ok(opened, "filetype is " .. ft .. " in " .. name)
    t.ok(vim.startswith(name, "oil://"), "buffer name is " .. name)
  end,

  ["trouble and todo-comments draw the icon database's icons"] = function(t)
    local I = require("ach.icons")
    local trouble = Config.plugins["trouble.nvim"]
    t.ok(trouble, "trouble.nvim is in the plugin list")
    local kinds = Plugin.values(trouble, "opts", false).icons.kinds
    t.eq(kinds.Function, I.kinds.Function .. " ", "trouble's Function icon")
    -- todo-comments finishes its setup on the first tick after startup, so wait for it.
    require("lazy").load({ plugins = { "todo-comments.nvim" } })
    local todo = require("todo-comments.config")
    t.ok(vim.wait(2000, function() return todo.loaded end, 20), "todo-comments finished its setup")
    t.eq(todo.options.keywords.TODO.icon, I.todo.TODO .. " ", "the TODO icon")
    t.eq(todo.options.keywords.FIX.color, "error", "FIX keeps todo-comments' own colour")
    t.ok(vim.tbl_contains(todo.options.keywords.FIX.alt, "FIXME"), "FIX keeps FIXME as an alternate name")
  end,
}
