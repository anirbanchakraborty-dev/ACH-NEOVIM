-- Times Neovim starts with Neovim's own --startuptime log. Two callers:
-- tests/test_startup.lua loads it with dofile and gets the table back, and
-- scripts/check --baseline runs it as `nvim -l tests/helpers/startup.lua ROOT BENCH`,
-- which times stock LazyVim beside this configuration and writes tests/baseline.json.
local M = {}

-- Ten timed starts per configuration, after one untimed warm-up start.
M.STARTS = 10

-- LazyVim's starter, pinned to its newest commit as of 2026-10-11.
M.STARTER_URL = "https://github.com/LazyVim/starter"
M.STARTER = "803bc181d7c0d6d5eeba9274d9be49b287294d99"

-- How a timed start ends. vim.schedule holds the quit until Neovim has entered
-- its main loop, after the first screen update has closed the log. A bare +qa
-- would quit before VimEnter and still write NVIM STARTED.
local QUIT = "lua vim.schedule(function() vim.cmd('qa!') end)"

-- The fields of tests/baseline.json, in the order they are written.
local FIELDS = { "ach_ms", "lazyvim_ms", "starts", "nvim", "starter", "lazyvim", "date" }

-- The milliseconds a --startuptime log gives for the end of startup, or nil
-- and the reason. A start that quit early still writes NVIM STARTED, so the
-- line before it must be the first screen update.
function M.parse(lines)
  for i = #lines, 2, -1 do
    local ms = lines[i]:match("^(%d+%.%d+)%s+%d+%.%d+: %-%-%- NVIM STARTED %-%-%-")
    if ms then
      if not lines[i - 1]:match(": first screen update$") then
        return nil, "Neovim quit before its first screen update"
      end
      return tonumber(ms)
    end
  end
  return nil, "the log has no NVIM STARTED line"
end

-- The middle value once sorted, or the mean of the middle two for an even count.
function M.median(list)
  local sorted = vim.deepcopy(list)
  table.sort(sorted)
  local n = #sorted
  if n % 2 == 1 then
    return sorted[(n + 1) / 2]
  end
  return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

-- One timed start in dir. Returns the milliseconds and what the start printed
-- on stderr; errors when it fails or its log is cut short.
function M.start(run, dir)
  local log = dir .. "/startuptime.log"
  os.remove(log)
  local argv = { run.argv[1], "--startuptime", log }
  vim.list_extend(argv, run.argv, 2)
  vim.list_extend(argv, { "-c", QUIT })
  local result = vim.system(argv, { cwd = dir, env = run.env, text = true, timeout = 60000 }):wait()
  local read, lines = pcall(vim.fn.readfile, log)
  os.remove(log)
  local stderr = vim.trim(result.stderr or "")
  if result.code ~= 0 then
    error(("%s exited with code %d: %s"):format(run.name, result.code, stderr), 0)
  end
  local ms, why = M.parse(read and lines or {})
  if not ms then
    error(("%s: %s"):format(run.name, why), 0)
  end
  return ms, stderr
end

-- Times each run n times after one warm-up start of each, taking turns so a
-- moment of load falls on every run alike. Returns the medians in the order
-- of runs, and what each run's last start printed.
function M.medians(runs, n, dir)
  local times, printed = {}, {}
  for i, run in ipairs(runs) do
    M.start(run, dir)
    times[i] = {}
  end
  for _ = 1, n do
    for i, run in ipairs(runs) do
      local ms, stderr = M.start(run, dir)
      table.insert(times[i], ms)
      printed[i] = stderr
    end
  end
  local medians = {}
  for i in ipairs(runs) do
    medians[i] = M.median(times[i])
  end
  return medians, printed
end

-- This configuration with the suite's instrumentation off and nothing installed.
function M.ach(root)
  return {
    name = "ACH-NEOVIM",
    argv = { vim.v.progpath, "--headless", "-u", root .. "/init.lua" },
    env = { ACH_TEST = "0", ACH_DRY_INSTALL = "1" },
  }
end

-- Stock LazyVim from the starter in bench/config/nvim, with all four of
-- Neovim's folders inside bench.
function M.lazyvim(bench)
  return {
    name = "stock LazyVim",
    argv = { vim.v.progpath, "--headless" },
    env = {
      XDG_CONFIG_HOME = bench .. "/config",
      XDG_DATA_HOME = bench .. "/data",
      XDG_STATE_HOME = bench .. "/state",
      XDG_CACHE_HOME = bench .. "/cache",
    },
  }
end

local OVER = "the median start took %.1f ms, more than one and a half times the baseline of %.1f ms"
local SLOWER = "the median start took %.1f ms, slower than stock LazyVim's %.1f ms"

-- nil when a median start passes against the recorded baseline, otherwise why not.
function M.verdict(baseline, median)
  if median > baseline.ach_ms * 1.5 then
    return OVER:format(median, baseline.ach_ms)
  end
  if median > baseline.lazyvim_ms then
    return SLOWER:format(median, baseline.lazyvim_ms)
  end
end

-- A baseline file as a table, or nil and the reason.
function M.read(path)
  local read, lines = pcall(vim.fn.readfile, path)
  if not read or #lines == 0 then
    return nil, path .. " is missing or empty"
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(data) ~= "table" then
    return nil, path .. " is not JSON"
  end
  return data
end

-- One field per line in a fixed order, so a re-recording diffs line by line.
local function encode(data)
  local lines = {}
  for i, field in ipairs(FIELDS) do
    lines[i] = ("  %s: %s"):format(vim.json.encode(field), vim.json.encode(data[field]))
  end
  return "{\n" .. table.concat(lines, ",\n") .. "\n}\n"
end

-- Runs a command that must succeed, with a long timeout for downloads.
local function must(argv, env)
  local result = vim.system(argv, { env = env, text = true, timeout = 600000 }):wait()
  if result.code ~= 0 then
    error(("%s failed with code %d: %s"):format(argv[1], result.code, vim.trim(result.stderr or "")), 0)
  end
end

-- The starter at its pinned commit in bench/config/nvim, its plugins installed
-- into bench/data. Returns the LazyVim commit the install locked.
local function prepare(bench)
  local config = bench .. "/config/nvim"
  vim.fn.mkdir(bench .. "/config", "p")
  must({ "git", "clone", "--quiet", M.STARTER_URL, config })
  must({ "git", "-C", config, "checkout", "--quiet", "--detach", M.STARTER })
  must({ vim.v.progpath, "--headless", "+Lazy! sync", "+qa" }, M.lazyvim(bench).env)
  local lock = M.read(config .. "/lazy-lock.json") or {}
  local commit = type(lock.LazyVim) == "table" and lock.LazyVim.commit or ""
  if type(commit) ~= "string" or #commit ~= 40 or not commit:match("^%x+$") then
    error("stock LazyVim did not install: its lazy-lock.json names no LazyVim commit", 0)
  end
  return commit
end

local REFUSED = "ACH-NEOVIM's median start, %.1f ms, is slower than stock LazyVim's, %.1f ms. No baseline was written."

-- scripts/check --baseline. Times this configuration and stock LazyVim, taking
-- turns, and writes the result, refusing and writing nothing when this
-- configuration is the slower. opts.out, opts.prepare and opts.medians let the
-- tests stand in for the file, the download and the timing.
function M.record(root, bench, opts)
  opts = opts or {}
  local out = opts.out or (root .. "/tests/baseline.json")
  local lazyvim = (opts.prepare or prepare)(bench)
  local dir = bench .. "/run"
  vim.fn.mkdir(dir, "p")
  local medians, printed = (opts.medians or M.medians)({ M.ach(root), M.lazyvim(bench) }, M.STARTS, dir)
  local ach_ms, lazyvim_ms = medians[1], medians[2]
  if ach_ms > lazyvim_ms then
    local why = REFUSED:format(ach_ms, lazyvim_ms)
    local said = printed and printed[2] or ""
    if said ~= "" then
      why = why .. " Stock LazyVim's last start printed: " .. said
    end
    error(why, 0)
  end
  local function tenth(ms) return math.floor(ms * 10 + 0.5) / 10 end
  local data = {
    ach_ms = tenth(ach_ms),
    lazyvim_ms = tenth(lazyvim_ms),
    starts = M.STARTS,
    nvim = tostring(vim.version()),
    starter = M.STARTER,
    lazyvim = lazyvim,
    date = os.date("%Y-%m-%d"),
  }
  local file = assert(io.open(out, "w"))
  file:write(encode(data))
  file:close()
  return data
end

-- Run as a script: nvim -l tests/helpers/startup.lua ROOT BENCH
if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "startup.lua" then
  local ok, result = pcall(M.record, _G.arg[1], _G.arg[2])
  if not ok then
    io.stderr:write(tostring(result) .. "\n")
    os.exit(1)
  end
  local wrote = "Wrote tests/baseline.json: ACH-NEOVIM %.1f ms, stock LazyVim %.1f ms, median of %d starts each.\n"
  io.stdout:write(wrote:format(result.ach_ms, result.lazyvim_ms, result.starts))
end

return M
