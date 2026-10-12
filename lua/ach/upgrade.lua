-- Runs the fast check once after Homebrew moves Neovim, so a release that
-- breaks the configuration is found the day it arrives rather than the day a
-- broken key is pressed. The running program's real path names the release,
-- and a one-line record in the state folder holds the last one that passed.
local M = {}

M.stamp = vim.fn.stdpath("state") .. "/ach/checked-nvim"

-- The running Neovim: its version as x.y.z, and its program's real path,
-- which lies in Homebrew's folder for that release, so it changes with every
-- release and every rebuild of one.
function M.current()
  local v = vim.version()
  return {
    version = ("%d.%d.%d"):format(v.major, v.minor, v.patch),
    program = vim.uv.fs_realpath(vim.v.progpath) or vim.v.progpath,
  }
end

-- The program the check last passed on, or nil when it has never passed.
function M.recorded(stamp)
  local file = io.open(stamp, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  return line
end

-- Only a Neovim on a screen, outside the test suite. The suite has no screen
-- and sets ACH_TEST, and either alone keeps the check, which runs the suite,
-- from starting itself again.
function M.wanted() return vim.env.ACH_TEST ~= "1" and #vim.api.nvim_list_uis() > 0 end

-- Runs root/scripts/check in the background with program's folder first on
-- the path and NVIM removed, and calls done(code, summary) on the main loop.
-- summary is the last line the check printed, or of its error output when it
-- printed nothing else. A check ended by a signal, or one that cannot start,
-- reports code 1.
function M.check(root, program, done)
  local env = vim.fn.environ()
  env.PATH = vim.fs.dirname(program) .. ":" .. (env.PATH or "")
  env.NVIM = nil
  local cmd = { root .. "/scripts/check" }
  local ok, proc = pcall(vim.system, cmd, { text = true, env = env, clear_env = true }, function(res)
    local text = vim.trim(res.stdout or "")
    if text == "" then
      text = vim.trim(res.stderr or "")
    end
    local lines = vim.split(text, "\n", { trimempty = true })
    local summary = lines[#lines] or "it printed nothing"
    local code = res.signal ~= 0 and 1 or res.code
    vim.schedule(function() done(code, summary) end)
  end)
  if not ok then
    vim.schedule(function() done(1, tostring(proc)) end)
    return nil
  end
  return proc
end

-- Runs the check when the running Neovim is not the one it last passed on,
-- and says what came of it. Returns true when a check started. opts may
-- replace current, stamp, root, check and notify; the tests use that.
function M.start(opts)
  opts = opts or {}
  local now = opts.current or M.current()
  local stamp = opts.stamp or M.stamp
  local root = opts.root or vim.g.ach_root
  local check = opts.check or M.check
  local notify = opts.notify or vim.notify
  if M.recorded(stamp) == now.program then
    return false
  end
  local levels = vim.log.levels
  notify(
    ("Neovim %s has not been checked yet, so the fast check is running in the background."):format(now.version),
    levels.INFO
  )
  check(root, now.program, function(code, summary)
    if code == 0 then
      vim.fn.mkdir(vim.fs.dirname(stamp), "p")
      vim.fn.writefile({ now.program }, stamp)
      notify(("The fast check passed on Neovim %s: %s."):format(now.version, summary), levels.INFO)
    elseif code == 2 then
      local msg = "The fast check on Neovim %s needs a person: %s. Run scripts/check in %s to see what."
      notify(msg:format(now.version, summary, root), levels.WARN)
    else
      local msg = "The fast check failed on Neovim %s: %s. Run scripts/check in %s to see which test."
      notify(msg:format(now.version, summary, root), levels.ERROR)
    end
  end)
  return true
end

-- Waits for VeryLazy, after the first screen has drawn, so the check never
-- slows a start.
function M.setup()
  local group = vim.api.nvim_create_augroup("ach_upgrade", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      if M.wanted() then
        M.start()
      end
    end,
  })
end

return M
