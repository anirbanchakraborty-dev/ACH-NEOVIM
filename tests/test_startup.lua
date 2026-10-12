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
  t.ok(data.ach_ms > 0 and data.ach_ms <= data.lazyvim_ms, "recorded no slower than stock LazyVim")
  t.eq(data.starts, S.STARTS, "the median of ten starts each")
  t.eq(data.starter, S.STARTER, "the pinned starter commit")
  local commit = type(data.lazyvim) == "string" and data.lazyvim or ""
  t.ok(#commit == 40 and commit:match("^%x+$") ~= nil, "LazyVim's commit, 40 hexadecimal digits")
  t.ok(type(data.nvim) == "string" and data.nvim:match("^%d+%.%d+%.%d+") ~= nil, "the Neovim version")
  t.ok(type(data.date) == "string" and data.date:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil, "the date, year first")
end

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

  ["the median of ten starts is the mean of the middle two"] = function(t)
    local S = startup(t)
    t.eq(S.STARTS, 10, "ten timed starts")
    t.eq(S.median({ 9, 1, 8, 2, 7, 3, 6, 4, 5, 100 }), 5.5, "one slow start does not move it")
    t.eq(S.median({ 3, 1, 2 }), 2, "an odd count takes the middle one")
  end,

  ["a start fails above one and a half times the baseline or above stock LazyVim"] = function(t)
    local S = startup(t)
    local roomy = { ach_ms = 20, lazyvim_ms = 40 }
    t.eq(S.verdict(roomy, 30), nil, "exactly one and a half times passes")
    local over = S.verdict(roomy, 30.1) or ""
    t.ok(over:find("one and a half times the baseline of 20.0 ms", 1, true), "just over fails: " .. over)

    local close = { ach_ms = 20, lazyvim_ms = 25 }
    t.eq(S.verdict(close, 25), nil, "as fast as stock LazyVim passes")
    local slower = S.verdict(close, 25.5) or ""
    t.ok(slower:find("slower than stock LazyVim's 25.0 ms", 1, true), "slower than LazyVim fails: " .. slower)
  end,

  ["the recorded baseline holds both medians and how they were taken"] = function(t)
    local S = startup(t)
    local data, why = S.read(t.root .. "/tests/baseline.json")
    if not data then
      missing(t, why)
    end
    valid(t, S, data)
  end,

  ["--baseline times both apart and writes only when this configuration is faster"] = function(t)
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

    local ok, err = pcall(S.record, t.root, bench, { out = out, prepare = prepare, medians = timed({ 31.24, 30 }) })
    t.eq(ok, false, "a slower configuration is refused")
    local said = tostring(err)
    t.ok(said:find("31.2 ms, is slower than stock LazyVim's, 30.0 ms", 1, true), "naming both times: " .. said)
    t.eq(vim.uv.fs_stat(out), nil, "and nothing is written")

    local data = S.record(t.root, bench, { out = out, prepare = prepare, medians = timed({ 24.06, 38.75 }) })
    t.eq(seen.n, S.STARTS, "ten starts each")
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

  ["this configuration starts within its baseline and no slower than stock LazyVim"] = function(t)
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
}
