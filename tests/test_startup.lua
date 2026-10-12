-- The startup benchmark: tests/helpers/startup.lua, tests/baseline.json and
-- scripts/check --baseline. One test times real starts, about a second's worth.
-- Nothing here downloads stock LazyVim; scripts/check --baseline alone does.

local function startup(t) return dofile(t.root .. "/tests/helpers/startup.lua") end

-- A --startuptime log as Neovim 0.12 writes it, with the stages between its
-- first and last few lines left out.
local LOG = {
  "--- Startup times for process: Primary (or UI client) ---",
  "",
  "times in msec",
  " clock   self+sourced   self:  sourced script",
  " clock   elapsed:              other lines",
  "",
  "000.003  000.003: --- NVIM STARTING ---",
  "000.120  000.117: event init",
  "021.480  000.310: VimEnter autocommands",
  "021.502  000.022: before starting main loop",
  "021.950  000.448: first screen update",
  "021.957  000.007: --- NVIM STARTED ---",
  "",
}

local HELP = "  scripts/check --baseline   time this configuration against stock LazyVim and write tests/baseline.json"

local function missing(t, why)
  t.human("No startup baseline is recorded (" .. why .. "). Record one with: scripts/check --baseline")
end

-- What every baseline file must hold, whoever wrote it.
local function valid(t, S, data)
  t.eq(type(data.ach_ms), "number", "ach_ms is a number")
  t.eq(type(data.lazyvim_ms), "number", "lazyvim_ms is a number")
  t.ok(data.ach_ms > 0 and data.ach_ms <= data.lazyvim_ms * 1.1, "recorded within 10% of stock LazyVim")
  t.eq(data.starts, S.STARTS, "the median of thirty starts each")
  t.eq(data.starter, S.STARTER, "the pinned starter commit")
  local commit = type(data.lazyvim) == "string" and data.lazyvim or ""
  t.ok(#commit == 40 and commit:match("^%x+$") ~= nil, "LazyVim's commit, 40 hexadecimal digits")
  t.ok(type(data.nvim) == "string" and data.nvim:match("^%d+%.%d+%.%d+") ~= nil, "the Neovim version")
  t.ok(type(data.date) == "string" and data.date:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil, "the date, year first")
end

-- Starts this configuration the way a timed start does, with args after it,
-- and once startup has finished evaluates expr, a Lua expression, inside it.
-- Returns the value, which comes back through JSON.
local function probe(t, args, expr)
  local run = startup(t).ach(t.root)
  local argv = vim.list_extend(vim.deepcopy(run.argv), args)
  local code = "lua vim.schedule(function() io.stdout:write(vim.json.encode(%s)) vim.cmd('qa!') end)"
  vim.list_extend(argv, { "-c", code:format(expr) })
  local result = vim.system(argv, { env = run.env, text = true, timeout = 30000 }):wait()
  local ok, value = pcall(vim.json.decode, result.stdout or "")
  t.ok(ok and type(value) == "table", "the probe printed no JSON: " .. vim.trim((result.stdout or "") .. " " .. (result.stderr or "")))
  return value
end

-- What a start with no file has no use for: Neovim's file type table, its
-- language-server and tree-sitter libraries, and what this configuration sets
-- up for a file. All of it arrives with the first file, or just after the first
-- screen when there is none.
local FILE_ONLY = {
  "vim.filetype",
  "vim.lsp",
  "vim.treesitter",
  "nvim-treesitter",
  "lspconfig",
  "ach.lang",
  "ach.filetypes",
  "ach.runtimes",
  "ach.grammar",
  "ach.managed",
  "ach.install",
}

return {
  ["a timing log gives the time of NVIM STARTED, after the first screen update"] = function(t)
    local S = startup(t)
    t.eq(S.parse(LOG), 21.957, "the clock on the last line")

    local early = vim.list_slice(LOG, 1, 9)
    table.insert(early, "021.490  000.010: --- NVIM STARTED ---")
    local ms, why = S.parse(early)
    t.eq(ms, nil, "a start that quit before its first screen gives no time")
    t.eq(why, "Neovim quit before its first screen update", "and says why")

    t.eq(select(2, S.parse({})), "the log has no NVIM STARTED line", "an empty log")
    local slow = { "1234.500  000.700: first screen update", "1234.567  000.067: --- NVIM STARTED ---" }
    t.eq(S.parse(slow), 1234.567, "a start past a second")
  end,

  ["a median is the middle start, or the mean of the middle two"] = function(t)
    local S = startup(t)
    -- Ten moved the median about 4% between back-to-back runs; thirty, about 1.5%.
    t.eq(S.STARTS, 30, "thirty timed starts")
    t.eq(S.median({ 9, 1, 8, 2, 7, 3, 6, 4, 5, 100 }), 5.5, "one slow start does not move it")
    t.eq(S.median({ 3, 1, 2 }), 2, "an odd count takes the middle one")
  end,

  ["a start fails above one and a half times the baseline"] = function(t)
    local S = startup(t)
    local roomy = { ach_ms = 20, lazyvim_ms = 40 }
    t.eq(S.verdict(roomy, 30), nil, "exactly one and a half times passes")
    local over = S.verdict(roomy, 30.1) or ""
    t.ok(over:find("one and a half times the baseline of 20.0 ms", 1, true), "just over fails: " .. over)

    -- Stock LazyVim is compared only when the two are timed side by side.
    -- Its time recorded on another day says nothing about this Mac today,
    -- since the same start has moved by a tenth between days.
    local close = { ach_ms = 20, lazyvim_ms = 18 }
    t.eq(S.verdict(close, 25), nil, "slower than stock LazyVim's recorded time passes")
  end,

  ["the recorded baseline holds both medians and how they were taken"] = function(t)
    local S = startup(t)
    local data, why = S.read(t.root .. "/tests/baseline.json")
    if not data then
      missing(t, why)
    end
    valid(t, S, data)
  end,

  ["--baseline times both apart and writes only when this configuration is within 10% of stock LazyVim"] = function(t)
    local S = startup(t)
    local bench = t.tmpdir()
    local out = bench .. "/baseline.json"
    local commit = string.rep("a", 40)
    local seen = {}
    local function prepare(dir)
      t.eq(dir, bench, "the starter goes into the throwaway folder")
      return commit
    end
    local function timed(medians)
      return function(runs, n)
        seen = { runs = runs, n = n }
        return medians, { "", "" }
      end
    end

    local ok, err = pcall(S.record, t.root, bench, { out = out, prepare = prepare, medians = timed({ 33.1, 30 }) })
    t.eq(ok, false, "more than 10% slower is refused")
    local said = tostring(err)
    t.ok(said:find("33.1 ms, is more than 10% slower than stock LazyVim's, 30.0 ms", 1, true), "naming both times: " .. said)
    t.eq(vim.uv.fs_stat(out), nil, "and nothing is written")

    -- 21.46 is within 10% of 19.51, but the file would say 21.5 against 19.5,
    -- which is not. The times are judged as they would be written.
    ok = pcall(S.record, t.root, bench, { out = out, prepare = prepare, medians = timed({ 21.46, 19.51 }) })
    t.eq(ok, false, "judged on the tenths it would write")
    t.eq(vim.uv.fs_stat(out), nil, "and still nothing is written")

    local within = S.record(t.root, bench, { out = out, prepare = prepare, medians = timed({ 31.24, 30 }) })
    t.eq({ within.ach_ms, within.lazyvim_ms }, { 31.2, 30 }, "slower, but within 10%, is written")

    local data = S.record(t.root, bench, { out = out, prepare = prepare, medians = timed({ 24.06, 38.75 }) })
    t.eq(seen.n, S.STARTS, "thirty starts each")
    local ach, lazyvim = seen.runs[1], seen.runs[2]
    t.eq({ ach.name, lazyvim.name }, { "ACH-NEOVIM", "stock LazyVim" }, "this configuration, then stock LazyVim")
    t.eq(ach.env.ACH_TEST, "0", "timed without the test instrumentation")
    t.eq(ach.env.ACH_DRY_INSTALL, "1", "and without installing anything")
    for _, name in ipairs({ "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME" }) do
      t.ok(vim.startswith(lazyvim.env[name] or "", bench .. "/"), name .. " is inside the throwaway folder")
    end

    t.eq(S.read(out), data, "the file holds what was recorded")
    t.eq({ data.ach_ms, data.lazyvim_ms }, { 24.1, 38.8 }, "rounded to a tenth of a millisecond")
    valid(t, S, data)
    t.eq(vim.fn.readfile(out)[2], '  "ach_ms": 24.1,', "one field per line, in a fixed order")
  end,

  ["this configuration starts within one and a half times its baseline"] = function(t)
    local S = startup(t)
    local baseline, why = S.read(t.root .. "/tests/baseline.json")
    if not baseline then
      missing(t, why)
    end
    local median = S.medians({ S.ach(t.root) }, S.STARTS, t.tmpdir())[1]
    local failure = S.verdict(baseline, median)
    t.ok(failure == nil, tostring(failure))
  end,

  ["scripts/check -h describes --baseline"] = function(t)
    local result = vim.system({ t.root .. "/scripts/check", "-h" }, { text = true }):wait()
    t.eq(result.code, 0, "the help exits 0")
    local lines = vim.split(vim.trim(result.stdout or ""), "\n")
    t.ok(vim.tbl_contains(lines, HELP), "names --baseline:\n" .. (result.stdout or ""))
    local last = "Exit 0 when everything passes, 1 on a failure, 2 when a person must act."
    t.eq(lines[#lines], last, "the help ends at the exit codes")
  end,

  ["init.lua turns Neovim's module cache on before it loads any of this configuration"] = function(t)
    local cache, first
    for i, line in ipairs(vim.fn.readfile(t.root .. "/init.lua")) do
      cache = cache or (line:match("^vim%.loader%.enable%(%)") and i)
      first = first or (line:match("require%(") and i)
    end
    t.ok(cache, "init.lua calls vim.loader.enable()")
    t.ok(first and cache < first, "before its first require, on line " .. tostring(first))
  end,

  ["a start with no file loads nothing that only a file needs"] = function(t)
    local list = "{'" .. table.concat(FILE_ONLY, "','") .. "'}"
    local seen = probe(t, {}, ([[{
      started = package.loaded['ach.lazy'] ~= nil,
      loaded = table.concat(vim.tbl_filter(function(m) return package.loaded[m] ~= nil end, %s), ' '),
    }]]):gsub("\n%s*", " "):format(list))
    t.ok(seen.started, "the probe ran inside this configuration")
    t.eq(seen.loaded, "", "loaded at start")
  end,

  ["a file type set before any file is read still gets tree-sitter"] = function(t)
    local seen = probe(t, { "-c", "set filetype=c" }, "{ on = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil }")
    t.ok(seen.on, "tree-sitter highlights the C buffer")
  end,

  ["a file whose parser was installed gets tree-sitter's highlighting and indentation"] = function(t)
    local site = vim.fn.stdpath("data") .. "/site/parser/python.so"
    if not vim.uv.fs_stat(site) then
      t.skip("the Python parser is not installed: open a .py file once to install it")
    end
    local file = t.tmpdir() .. "/f.py"
    vim.fn.writefile({ "def f():", "        return 1" }, file)
    local seen = probe(t, { file }, ([[(function()
      local buf = vim.api.nvim_get_current_buf()
      vim.wait(5000, function() return vim.treesitter.highlighter.active[buf] ~= nil end)
      local ok = pcall(vim.cmd, 'silent normal! gg=G')
      return { on = vim.treesitter.highlighter.active[buf] ~= nil, expr = vim.bo.indentexpr, ok = ok, line = vim.fn.getline(2) }
    end)()]]):gsub("\n%s*", " "))
    t.ok(seen.on, "tree-sitter highlights the Python file")
    t.ok(seen.expr:find("nvim-treesitter", 1, true), "nvim-treesitter indents it, not " .. seen.expr)
    t.ok(seen.ok, "re-indenting the file raised no error")
    t.eq(seen.line, "    return 1", "the body is indented one level under the def")
  end,

  ["a file named on the command line gets this configuration's file types"] = function(t)
    local file = t.tmpdir() .. "/top.xdc"
    vim.fn.writefile({ "set_property PACKAGE_PIN W5 [get_ports clk]" }, file)
    local seen = probe(t, { file }, "{ ft = vim.bo.filetype, handled = vim.b.ach_handled == true }")
    t.eq(seen.ft, require("ach.filetypes").extensions.xdc, "the table's file type")
    t.ok(seen.handled, "and the installer saw the file")
  end,

  ["the first server enabled has nvim-lspconfig's configurations"] = function(t)
    local seen = probe(t, {}, "(function() require('ach.lsp').enable_for('text') return { cmd = (vim.lsp.config.lua_ls or {}).cmd ~= nil } end)()")
    t.ok(seen.cmd, "lua_ls has the command nvim-lspconfig gives it")
  end,

  ["which-key's icon rules are built when which-key loads, not when its spec is read"] = function(t)
    local spec = dofile(t.root .. "/lua/ach/plugins/keys.lua")[1]
    t.eq(spec[1], "folke/which-key.nvim", "the first spec is which-key's")
    t.eq((spec.opts.icons or {}).rules, nil, "no rules in the spec")
    local rules = require("which-key.config").options.icons.rules
    t.eq(#rules, #require("ach.icons").which_key_rules(), "which-key has every rule once loaded")
  end,

  ["tree-sitter folds a file buffer that has a file type, and nothing else"] = function(t)
    local real, calls = vim.treesitter.foldexpr, 0
    vim.treesitter.foldexpr = function()
      calls = calls + 1
      return ">1"
    end
    local ignore, bufs = vim.o.eventignore, {}
    vim.o.eventignore = "FileType"
    local function fold(listed, scratch, ft)
      local buf = vim.api.nvim_create_buf(listed, scratch)
      bufs[#bufs + 1] = buf
      vim.bo[buf].filetype = ft
      return vim.api.nvim_buf_call(buf, function() return vim.fn.eval(vim.go.foldexpr) end)
    end
    local ok, got = pcall(function()
      return { file = fold(true, false, "c"), empty = fold(true, false, ""), scratch = fold(false, true, "c") }
    end)
    vim.treesitter.foldexpr, vim.o.eventignore = real, ignore
    for _, buf in ipairs(bufs) do
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    t.ok(ok, tostring(got))
    t.eq(got, { file = ">1", empty = 0, scratch = 0 }, "the fold levels")
    t.eq(calls, 1, "tree-sitter asked once, for the file")
  end,
}
