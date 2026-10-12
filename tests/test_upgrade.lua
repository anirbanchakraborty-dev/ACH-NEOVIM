-- lua/ach/upgrade.lua. The fast check runs once for each Neovim program
-- Homebrew installs, only in a Neovim on a screen outside the suite, and the
-- program is recorded only when the check passes. The check is a stand-in, or
-- a small script in a throwaway folder, so nothing here runs the real suite.

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A Neovim the check has not seen.
local NEW = { version = "0.12.7", program = "/opt/homebrew/Cellar/neovim/0.12.7/bin/nvim" }

-- Calls start with a stand-in check that answers code and summary at once,
-- and returns what start returned, how many times the check ran, and every
-- notice, as { msg, level }.
local function run(stamp, code, summary)
  local runs, said = 0, {}
  local started = require("ach.upgrade").start({
    current = NEW,
    stamp = stamp,
    root = "/ach",
    check = function(_, _, done)
      runs = runs + 1
      done(code, summary)
    end,
    notify = function(msg, level) said[#said + 1] = { msg = msg, level = level } end,
  })
  return started, runs, said
end

-- Makes a throwaway folder laid out like the repository, whose scripts/check
-- is a shell script running body, and returns the folder.
local function repo(t, body)
  local root = t.tmpdir()
  vim.fn.mkdir(root .. "/scripts", "p")
  local path = root .. "/scripts/check"
  vim.fn.writefile({ "#!/bin/sh", body }, path)
  vim.fn.setfperm(path, "rwxr-xr-x")
  return root
end

-- Runs the real check on root and waits up to ten seconds for its answer.
local function check(root, program)
  local got
  require("ach.upgrade").check(
    root,
    program or vim.v.progpath,
    function(code, summary) got = { code = code, summary = summary } end
  )
  vim.wait(10000, function() return got ~= nil end, 20)
  assert(got, "the check answered within ten seconds")
  return got
end

return {
  ["the check is wanted only on a screen, outside the suite"] = function(t)
    local U = require("ach.upgrade")
    t.eq(U.wanted(), false, "not in the suite, which has no screen")
    local screen = function() return { {} } end
    with({ { vim.api, "nvim_list_uis", screen } }, function()
      t.eq(U.wanted(), false, "not in the suite, even with a screen")
      with(
        { { vim.env, "ACH_TEST", "0" } },
        function() t.eq(U.wanted(), true, "a Neovim on a screen, outside the suite") end
      )
    end)
    with(
      { { vim.env, "ACH_TEST", "0" } },
      function() t.eq(U.wanted(), false, "not without a screen, as under a script or Skim") end
    )
  end,

  ["a Neovim the check already passed on starts nothing"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    vim.fn.writefile({ NEW.program }, stamp)
    local started, runs, said = run(stamp, 0, "unused")
    t.eq(started, false, "no check started")
    t.eq(runs, 0, "the check did not run")
    t.eq(#said, 0, "nothing was said")
  end,

  ["a new Neovim runs the check once, and a pass records it"] = function(t)
    local stamp = t.tmpdir() .. "/ach/checked-nvim"
    local summary = "120 passed, 0 failed, 0 need a person, 0 skipped"
    local started, runs, said = run(stamp, 0, summary)
    t.eq(started, true, "a check started")
    t.eq(runs, 1, "the check ran once")
    t.eq(said, {
      {
        msg = "Neovim 0.12.7 has not been checked yet, so the fast check is running in the background.",
        level = vim.log.levels.INFO,
      },
      { msg = "The fast check passed on Neovim 0.12.7: " .. summary .. ".", level = vim.log.levels.INFO },
    })
    t.eq(vim.fn.readfile(stamp), { NEW.program }, "the program is recorded, in a folder made for it")
    local again, reruns = run(stamp, 0, summary)
    t.eq({ again, reruns }, { false, 0 }, "the next start runs nothing")
  end,

  ["a failed check is an error, records nothing, and runs again at the next start"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    local summary = "119 passed, 1 failed, 0 need a person, 0 skipped"
    local _, _, said = run(stamp, 1, summary)
    t.eq(said[2], {
      msg = "The fast check failed on Neovim 0.12.7: " .. summary .. ". Run scripts/check in /ach to see which test.",
      level = vim.log.levels.ERROR,
    })
    t.eq(vim.uv.fs_stat(stamp), nil, "nothing is recorded")
    local again, reruns = run(stamp, 0, "120 passed, 0 failed, 0 need a person, 0 skipped")
    t.eq({ again, reruns }, { true, 1 }, "the next start runs the check again")
  end,

  ["a check that needs a person is a warning and runs again at the next start"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    local summary = "119 passed, 0 failed, 1 need a person, 0 skipped"
    local _, _, said = run(stamp, 2, summary)
    t.eq(said[2], {
      msg = "The fast check on Neovim 0.12.7 needs a person: " .. summary .. ". Run scripts/check in /ach to see what.",
      level = vim.log.levels.WARN,
    })
    t.eq(vim.uv.fs_stat(stamp), nil, "nothing is recorded")
    local again, reruns = run(stamp, 2, summary)
    t.eq({ again, reruns }, { true, 1 }, "the next start runs the check again")
  end,

  ["the check reports the last line the suite printed, and its exit code"] = function(t)
    local got = check(repo(t, "printf 'one\\ntwo\\n12 passed, 1 failed, 0 need a person, 0 skipped\\n\\n'; exit 1"))
    t.eq(got, { code = 1, summary = "12 passed, 1 failed, 0 need a person, 0 skipped" }, "the last line with text")
    got = check(repo(t, "echo 'Neovim is not installed.' >&2; exit 2"))
    t.eq(got, { code = 2, summary = "Neovim is not installed." }, "the error output, when nothing else was printed")
    got = check(repo(t, "exit 0"))
    t.eq(got, { code = 0, summary = "it printed nothing" }, "a check that printed nothing")
  end,

  ["a check ended by a signal, or one that cannot start, is a failure"] = function(t)
    local got = check(repo(t, "echo started; kill -TERM $$"))
    t.eq(got, { code = 1, summary = "started" }, "ended by a signal")
    got = check(t.tmpdir())
    t.eq(got.code, 1, "a folder with no scripts/check")
    t.ok(got.summary:find("scripts/check", 1, true) ~= nil, "naming the script that could not start")
  end,

  ["the check runs the Neovim that asked for it, as from a shell outside the editor"] = function(t)
    local root = repo(t, [[printf '%s %s\n' "${PATH%%:*}" "${NVIM-unset}"]])
    local got = check(root, "/opt/homebrew/Cellar/neovim/0.12.7/bin/nvim")
    t.eq(got.summary, "/opt/homebrew/Cellar/neovim/0.12.7/bin unset", "its folder first on the path, and no NVIM")
  end,

  ["the running Neovim is named by its program's real path and its version"] = function(t)
    local now = require("ach.upgrade").current()
    t.eq(now.program, vim.uv.fs_realpath(vim.v.progpath), "the real path, with every link followed")
    local v = vim.version()
    t.eq(now.version, ("%d.%d.%d"):format(v.major, v.minor, v.patch), "the version")
    t.ok(now.version:match("^%d+%.%d+%.%d+$") ~= nil, "written as x.y.z")
  end,

  ["the check is set up at startup, to run after the first screen when it is wanted"] = function(t)
    local U = require("ach.upgrade")
    t.ok(pcall(vim.api.nvim_get_autocmds, { group = "ach_upgrade" }), "init.lua set it up")
    U.setup()
    local found = vim.api.nvim_get_autocmds({ group = "ach_upgrade", event = "User", pattern = "VeryLazy" })
    t.eq(#found, 1, "one handler, on VeryLazy")
    local starts = 0
    local function count() starts = starts + 1 end
    local function never() return false end
    local function always() return true end
    with({ { U, "start", count }, { U, "wanted", never } }, function() found[1].callback() end)
    t.eq(starts, 0, "not when it is not wanted")
    with({ { U, "start", count }, { U, "wanted", always } }, function() found[1].callback() end)
    t.eq(starts, 1, "once when it is wanted")
    vim.api.nvim_del_augroup_by_name("ach_upgrade")
  end,
}
