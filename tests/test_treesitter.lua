-- Tree-sitter. Every parser the table names is one nvim-treesitter can
-- install, every file type's parser is on its language's list, a fresh start
-- installs nothing, a file asks for its parsers and the ones its injections
-- name, a buffer that is not a file asks for nothing until it is written, an
-- installed parser gives highlighting and the moves, a diff keeps ]c and [c,
-- and a failed parser install is tried once per session.

local function available()
  local set = {}
  for _, name in ipairs(require("nvim-treesitter").get_available()) do
    set[name] = true
  end
  return set
end

local function samples(t) return dofile(t.root .. "/tests/fixtures/samples.lua") end

return {
  ["every parser the table names is one nvim-treesitter can install"] = function(t)
    local known = available()
    local missing = {}
    for _, name in ipairs(require("ach.lang").all_parsers()) do
      if not known[name] then
        missing[#missing + 1] = name
      end
    end
    t.eq(missing, {}, "parsers nvim-treesitter does not know")
  end,

  ["each file type's parser is on its language's list"] = function(t)
    local known = available()
    local wrong = {}
    for _, e in ipairs(require("ach.lang").entries()) do
      for _, ft in ipairs(e.ft) do
        local parser = vim.treesitter.language.get_lang(ft) or ft
        if known[parser] and not vim.list_contains(e.ts or {}, parser) then
          wrong[#wrong + 1] = ("%s: %s is parsed by %s"):format(e.name, ft, parser)
        end
      end
    end
    t.eq(wrong, {}, "file types whose parser the table never installs")
  end,

  ["a fresh start installs nothing"] = function(t)
    local child = dofile(t.root .. "/tests/helpers/child.lua")
    local got = child.run(t, [[report(require("ach.install").requests)]])
    t.eq(got.parsers, {}, "parsers asked for before any file was opened")
    t.eq(got.packages, {}, "tools asked for before any file was opened")
    t.eq(got.servers, {}, "servers asked for before any file was opened")
  end,

  ["a Lua file asks for its own parsers and the ones its injections name"] = function(t)
    local child = dofile(t.root .. "/tests/helpers/child.lua")
    local file = vim.fn.fnameescape(samples(t).write(t.tmpdir(), "lua"))
    local got = child.run(t, ("vim.cmd.edit(%q)\nreport(require('ach.install').requests.parsers)"):format(file))
    -- lua, luadoc and luap are the entry's own; Lua's injection query names
    -- c for ffi.cdef, vim for vim.cmd and query for vim.treesitter.query.parse.
    for _, name in ipairs({ "lua", "luadoc", "luap", "c", "query", "vim" }) do
      t.ok(vim.list_contains(got, name), name .. " is not among " .. table.concat(got, ", "))
    end
  end,

  ["a buffer that is not a file asks for nothing"] = function(t)
    local install = require("ach.install")
    local path = samples(t).write(t.tmpdir(), "python")
    local opened = {}
    local dry = install.dry
    install.dry = true -- under --full the installer is live and records nothing
    install.reset()
    local ok, err = pcall(function()
      -- A scratch buffer given a file type, as a picker's preview is.
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.bo[scratch].filetype = "python"
      -- A buffer named after a real file that is still not a file's buffer.
      local preview = vim.api.nvim_create_buf(false, false)
      opened[#opened + 1] = preview
      vim.bo[preview].buftype = "nofile"
      vim.api.nvim_buf_set_name(preview, path)
      vim.bo[preview].filetype = "python"
      -- A new buffer whose file type is set by hand.
      vim.cmd("enew")
      opened[#opened + 1] = vim.api.nvim_get_current_buf()
      vim.cmd("setfiletype python")
      -- Neovim's help, whose buftype is "help".
      vim.cmd("help")
      opened[#opened + 1] = vim.api.nvim_get_current_buf()
      vim.cmd("helpclose")
      t.eq(install.requests.parsers, {}, "parsers asked for")
    end)
    for _, buf in ipairs(opened) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    install.dry = dry
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["a new file asks for its parsers once it is first written"] = function(t)
    local install = require("ach.install")
    local path = t.tmpdir() .. "/new.py"
    local dry = install.dry
    install.dry = true
    install.reset()
    local ok, err = pcall(function()
      vim.cmd.edit(vim.fn.fnameescape(path))
      t.eq(vim.bo.filetype, "python", "the file type, from the name")
      t.eq(install.requests.parsers, {}, "parsers asked for before the file exists")
      vim.cmd.write()
      t.ok(vim.list_contains(install.requests.parsers, "python"), "the python parser, once the file is written")
    end)
    vim.cmd("bwipeout!")
    install.dry = dry
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["a file whose parser is installed gets highlighting and the moves"] = function(t)
    vim.cmd.edit(vim.fn.fnameescape(samples(t).write(t.tmpdir(), "lua")))
    local buf = vim.api.nvim_get_current_buf()
    local highlighted = vim.treesitter.highlighter.active[buf] ~= nil
    local map = vim.fn.maparg("]f", "n", false, true)
    vim.cmd("bwipeout!")
    t.ok(highlighted, "highlighting started")
    t.eq({ map.buffer, map.desc }, { 1, "Next Function Start" }, "]f in the buffer")
  end,

  ["in a diff, ]c and [c still move between changes"] = function(t)
    local dir = t.tmpdir()
    vim.fn.writefile({ "local a = 1", "local b = 2", "local c = 3", "return a" }, dir .. "/a.lua")
    vim.fn.writefile({ "local a = 1", "local b = 2", "local c = 4", "return a" }, dir .. "/b.lua")
    vim.cmd.edit(dir .. "/a.lua")
    local a = vim.api.nvim_get_current_buf()
    vim.cmd("diffthis")
    vim.cmd.vsplit(dir .. "/b.lua")
    local b = vim.api.nvim_get_current_buf()
    vim.cmd("diffthis")
    vim.cmd("wincmd p")
    local ok, err = pcall(function()
      t.eq(vim.fn.maparg("]c", "n", false, true).desc, "Next Class Start", "]c is the class move outside a diff")
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.api.nvim_feedkeys("]c", "x", false)
      t.eq(vim.api.nvim_win_get_cursor(0)[1], 3, "line after ]c")
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      vim.api.nvim_feedkeys("[c", "x", false)
      t.eq(vim.api.nvim_win_get_cursor(0)[1], 3, "line after [c")
    end)
    vim.cmd("diffoff!")
    vim.cmd("only")
    vim.api.nvim_buf_delete(b, { force = true })
    vim.api.nvim_buf_delete(a, { force = true })
    if not ok then
      error(err, 0)
    end
  end,

  ["a parser that fails to install is tried once, and every caller hears back"] = function(t)
    local install = require("ach.install")
    local ts = require("nvim-treesitter")
    local saved = { install.dry, install.available_parsers, install.installed_parsers, ts.install }
    local calls, finish, heard = 0, nil, {}
    install.reset()
    install.dry = false
    install.available_parsers = function() return { ach_fake = true } end
    install.installed_parsers = function() return {} end
    ts.install = function()
      calls = calls + 1
      return {
        await = function(_, cb) finish = cb end,
      }
    end
    local ok, err = pcall(function()
      install.ensure_parsers({ "ach_fake" }, function() heard[#heard + 1] = "first" end)
      install.ensure_parsers({ "ach_fake" }, function() heard[#heard + 1] = "second" end)
      t.eq(calls, 1, "installs started for two callers")
      finish(nil, false)
      t.ok(vim.wait(1000, function() return #heard == 2 end), "both callers heard back")
      install.ensure_parsers({ "ach_fake" }, function() heard[#heard + 1] = "third" end)
      t.eq(heard, { "first", "second", "third" }, "callers heard back")
      t.eq(calls, 1, "installs started after the failure")
    end)
    install.dry, install.available_parsers, install.installed_parsers, ts.install = unpack(saved)
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["every move has an icon"] = function(t)
    local icons = require("ach.icons")
    local missing = {}
    for _, move in ipairs(require("ach.treesitter").moves) do
      local found = icons.key(move[4])
      if not (found and found.icon) then
        missing[#missing + 1] = move[4]
      end
    end
    t.eq(missing, {}, "moves with no icon")
  end,
}
