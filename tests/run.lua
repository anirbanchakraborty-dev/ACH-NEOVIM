-- Headless test runner. scripts/check starts Neovim with the real configuration
-- and then this file. Each tests/test_*.lua returns a table of named tests, and
-- each test receives the helper table t defined below.
local root = vim.g.ach_root
local full = vim.env.ACH_FULL == "1"
local only = vim.env.ACH_ONLY or ""
local out = io.stdout

-- lazy.nvim fires VeryLazy after UIEnter, which a headless Neovim never sees,
-- so the runner fires it by hand and waits for lazy.nvim to finish.
vim.api.nvim_exec_autocmds("UIEnter", { modeline = false })
if not vim.wait(10000, function() return vim.g.did_very_lazy == true end, 20) then
  out:write("FAIL startup: VeryLazy never fired\n")
  vim.cmd("cquit 1")
end
vim.wait(300) -- lets notifications scheduled during startup arrive

local hook = require("ach.testhook")
local t = {
  root = root,
  full = full,
  startup = { errmsg = vim.v.errmsg, warnings = hook.warnings() },
}

function t.eq(got, want, what)
  if not vim.deep_equal(got, want) then
    error(("%s: expected %s, got %s"):format(what or "value", vim.inspect(want), vim.inspect(got)), 2)
  end
end

function t.ok(value, what)
  if not value then
    error(what or "expected a true value", 2)
  end
end

function t.human(why) error({ human = why }, 0) end

function t.skip(why) error({ skip = why }, 0) end

function t.tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir)
end

local counts = { pass = 0, fail = 0, human = 0, skip = 0 }

local function report(kind, label, detail)
  counts[kind] = counts[kind] + 1
  local word = ({ pass = "PASS", fail = "FAIL", human = "HUMAN", skip = "SKIP" })[kind]
  out:write(word .. " " .. label .. (detail and (": " .. detail) or "") .. "\n")
end

-- A plugin can open a pane beside a file, as lean.nvim's infoview does beside a
-- Lean file, and the pane outlives the file. Each test starts in one window that
-- is not pinned to its buffer, so no test edits inside a pane an earlier one left.
local function one_window()
  if #vim.api.nvim_tabpage_list_wins(0) == 1 and not vim.wo.winfixbuf then
    return
  end
  vim.cmd("silent! botright new")
  vim.cmd("silent! only!")
end

local function run_test(label, fn)
  if only ~= "" and not label:find(only, 1, true) then
    return
  end
  one_window()
  local ok, err = xpcall(fn, function(e) return type(e) == "table" and e or debug.traceback(tostring(e), 2) end, t)
  if ok then
    report("pass", label)
  elseif type(err) == "table" and err.skip then
    report("skip", label, err.skip)
  elseif type(err) == "table" and err.human then
    report("human", label, err.human)
  else
    report("fail", label, tostring(err))
  end
end

local function run_file(file)
  local base = vim.fs.basename(file):gsub("%.lua$", "")
  if base:find("^test_full") and not full then
    return
  end
  local ok, suite = pcall(dofile, file)
  if not ok then
    report("fail", base, suite)
    return
  end
  local names = vim.tbl_keys(suite)
  table.sort(names)
  for _, name in ipairs(names) do
    run_test(base .. " :: " .. name, suite[name])
  end
end

local files = vim.fn.glob(root .. "/tests/test_*.lua", false, true)
table.sort(files)
for _, file in ipairs(files) do
  run_file(file)
end

-- A filter that matches nothing would otherwise pass with nothing run.
if only ~= "" and counts.pass + counts.fail + counts.human + counts.skip == 0 then
  report("fail", "--only " .. only, "no test matches")
end

out:write(
  ("\n%d passed, %d failed, %d need a person, %d skipped\n"):format(counts.pass, counts.fail, counts.human, counts.skip)
)
out:flush()
if counts.fail > 0 then
  vim.cmd("cquit 1")
elseif counts.human > 0 then
  vim.cmd("cquit 2")
else
  vim.cmd("qall!")
end
