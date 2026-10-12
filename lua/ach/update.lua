-- Updates: every plugin and Mason package moved to its newest version, and the
-- move kept only when scripts/check --full passes. Three callers. scripts/update
-- runs this file as `nvim -l lua/ach/update.lua ROOT`, which drives a whole
-- update from outside the editor; the headless Neovim that run starts calls
-- child() to update, restore or list; and tests/test_update.lua requires it
-- and passes stand-ins for everything that downloads.
local M = {}

-- The files an update may change: the two lock files, and the languages table
-- scripts/check --full rewrites. They are committed together or put back
-- together.
M.FILES = { "lazy-lock.json", "mason-lock.json", "docs/languages.md" }

-- How long one wait inside the headless Neovim may last: thirty minutes, time
-- for every parser and Mason package to download and build.
M.TIMEOUT = 30 * 60 * 1000

-- A git commit is shown by its first seven characters, as git shows it.
local function short(version) return (#version == 40 and version:match("^%x+$")) and version:sub(1, 7) or version end

function M.line(name, from, to) return ("- %s %s to %s"):format(name, short(from), short(to)) end

-- The GitHub page showing every change between two commits of a plugin, or
-- nil for a plugin that does not come from GitHub.
function M.compare(url, from, to)
  local path = type(url) == "string" and url:match("^https://github%.com/([%w._-]+/[%w._-]+)$")
  if not path then
    return nil
  end
  return ("https://github.com/%s/compare/%s...%s"):format(path:gsub("%.git$", ""), from, to)
end

-- One line per entry that differs between two lock tables, sorted by name.
-- value turns an entry into the version it names.
local function changes(before, after, value)
  local names, seen = {}, {}
  for _, side in ipairs({ before, after }) do
    for name in pairs(side) do
      if not seen[name] then
        seen[name] = true
        names[#names + 1] = name
      end
    end
  end
  table.sort(names)
  local lines = {}
  for _, name in ipairs(names) do
    local old = before[name] ~= nil and value(before[name]) or nil
    local new = after[name] ~= nil and value(after[name]) or nil
    if old == nil then
      lines[#lines + 1] = ("- %s added at %s"):format(name, short(new))
    elseif new == nil then
      lines[#lines + 1] = ("- %s removed, was at %s"):format(name, short(old))
    elseif old ~= new then
      lines[#lines + 1] = M.line(name, old, new)
    end
  end
  return lines
end

local function count(n, one, many) return ("%d %s"):format(n, n == 1 and one or many) end

-- The commit message for an update, from the lock tables before and after it,
-- each { lazy = <lazy-lock.json>, mason = <mason-lock.json> }. Returns the
-- subject and the body, or nil when nothing moved.
function M.message(before, after)
  local plugins = changes(before.lazy, after.lazy, function(entry) return entry.commit end)
  local mason = changes(before.mason, after.mason, tostring)
  if #plugins + #mason == 0 then
    return nil
  end
  local counted, body = {}, {}
  if #plugins > 0 then
    counted[#counted + 1] = count(#plugins, "plugin", "plugins")
    body[#body + 1] = "Plugins:\n" .. table.concat(plugins, "\n")
  end
  if #mason > 0 then
    counted[#counted + 1] = count(#mason, "Mason package", "Mason packages")
    body[#body + 1] = "Mason packages:\n" .. table.concat(mason, "\n")
  end
  body[#body + 1] = "scripts/check --full passed with these versions."
  return "chore(deps): update " .. table.concat(counted, " and "), table.concat(body, "\n\n")
end

-- What scripts/update --list prints: each plugin that would move, with its
-- GitHub page, and each Mason package behind its newest release.
function M.report(plugins, mason)
  if #plugins + #mason == 0 then
    return { "Every plugin and Mason package is at its latest version." }
  end
  local lines = {}
  if #plugins > 0 then
    lines[#lines + 1] = "Plugins that would move:"
    for _, p in ipairs(plugins) do
      local link = M.compare(p.url, p.from, p.to)
      lines[#lines + 1] = M.line(p.name, p.from, p.to) .. (link and ", " .. link or "")
    end
  end
  if #mason > 0 then
    lines[#lines + 1] = "Mason packages that would move:"
    for _, m in ipairs(mason) do
      lines[#lines + 1] = M.line(m.name, m.from, m.to)
    end
  end
  return lines
end

local function decode(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  local parsed, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return parsed and type(data) == "table" and data or {}
end

-- Both lock files of the repository at root, as tables.
function M.locks(root) return { lazy = decode(root .. "/lazy-lock.json"), mason = decode(root .. "/mason-lock.json") } end

-- Everything the update, the restore and the list reach, in one table so the
-- tests can pass stand-ins. Only called inside a configured Neovim.
function M.deps()
  return {
    lazy = require("lazy"),
    plugins = function() return require("lazy.core.config").plugins end,
    parsers = function() return require("nvim-treesitter").update(nil, { summary = true }) end,
    masonlock = require("ach.masonlock"),
    registry = function() return require("mason-registry") end,
    note = function(text) io.stdout:write(text .. "\n") end,
  }
end

local function by_name(a, b) return a.name < b.name end

-- Each plugin whose last run left a task with an error, as "name: error",
-- sorted.
local function plugin_errors(plugins)
  local out = {}
  for name, plugin in pairs(plugins) do
    for _, task in ipairs(plugin._ and plugin._.tasks or {}) do
      if task:has_errors() then
        out[#out + 1] = ("%s: %s"):format(name, vim.trim(task:output(vim.log.levels.ERROR)))
        break
      end
    end
  end
  table.sort(out)
  return out
end

-- Starts work that reports through a callback, and waits for it. Returns the
-- callback's arguments as a list, or nil when the wait ran out.
local function await(start)
  local result
  start(function(...) result = { ... } end)
  if vim.wait(M.TIMEOUT, function() return result ~= nil end, 100) then
    return result
  end
end

-- Rebuilds every installed parser whose revision differs from the one
-- nvim-treesitter names now. A rebuild already running is waited for, not
-- started twice. Returns a failure line, or nil.
local function parsers(deps)
  deps.note("Rebuilding each tree-sitter parser whose revision moved")
  local ok, built = deps.parsers():pwait(M.TIMEOUT)
  if not ok then
    return ("tree-sitter: the parsers did not finish (%s)"):format(tostring(built))
  elseif not built then
    return "tree-sitter: a parser did not build, and :checkhealth nvim-treesitter names it"
  end
end

-- The update: plugins, then the parsers their new revisions name, then Mason
-- packages and their pins. Returns one line per failure; empty means it worked.
function M.apply(deps)
  deps = deps or M.deps()
  deps.note("Updating every plugin")
  deps.lazy.update({ wait = true, show = false })
  local failures = plugin_errors(deps.plugins())
  failures[#failures + 1] = parsers(deps)
  deps.note("Updating every Mason package and its pin")
  local result = await(function(done) deps.masonlock.update(done) end)
  if not result then
    failures[#failures + 1] = "Mason: the update did not finish within thirty minutes"
    return failures
  end
  for _, name in ipairs(result[2]) do
    failures[#failures + 1] = ("Mason: %s did not update"):format(name)
  end
  return failures
end

-- The undo, once the lock files are back as committed: every plugin to the
-- commit lazy-lock.json pins, every parser to the revision that names, and
-- every pinned Mason package away from its pin back to it. Returns one line
-- per failure.
function M.restore(deps)
  deps = deps or M.deps()
  deps.note("Returning every plugin to the commit lazy-lock.json pins")
  deps.lazy.restore({ wait = true, show = false })
  local failures = plugin_errors(deps.plugins())
  failures[#failures + 1] = parsers(deps)
  deps.note("Returning every Mason package to the version mason-lock.json pins")
  local registry = deps.registry()
  await(function(done) registry.refresh(done) end)
  local lock, drifted = deps.masonlock.read(), {}
  for _, p in ipairs(registry.get_installed_packages()) do
    if lock[p.name] and p:get_installed_version() ~= lock[p.name] then
      drifted[#drifted + 1] = p.name
    end
  end
  table.sort(drifted)
  local left = #drifted
  for _, name in ipairs(drifted) do
    deps.masonlock.install(name, function(ok, err)
      if not ok then
        local line = "Mason: %s did not return to %s: %s"
        failures[#failures + 1] = line:format(name, lock[name], err or "no reason given")
      end
      left = left - 1
    end)
  end
  if not vim.wait(M.TIMEOUT, function() return left == 0 end, 100) then
    failures[#failures + 1] = "Mason: returning the packages did not finish within thirty minutes"
  end
  return failures
end

-- What an update would move, without moving it: lazy.nvim's check fetches
-- every plugin and prints the commits it would take, and Mason's registry is
-- refreshed for the newest releases. Returns the plugins and the Mason
-- packages that would move, and any plugin whose fetch failed.
function M.pending(deps)
  deps = deps or M.deps()
  deps.lazy.check({ wait = true, show = false })
  local all, plugins = deps.plugins(), {}
  for name, plugin in pairs(all) do
    local updates = plugin._ and plugin._.updates
    if updates then
      plugins[#plugins + 1] = { name = name, from = updates.from.commit, to = updates.to.commit, url = plugin.url }
    end
  end
  table.sort(plugins, by_name)
  local registry, mason = deps.registry(), {}
  await(function(done) registry.refresh(done) end)
  for _, p in ipairs(registry.get_installed_packages()) do
    local installed, latest = p:get_installed_version(), p:get_latest_version()
    if installed ~= latest then
      mason[#mason + 1] = { name = p.name, from = installed or "an unknown version", to = latest }
    end
  end
  table.sort(mason, by_name)
  return plugins, mason, plugin_errors(all)
end

local ACTIONS = {
  apply = function() return M.apply() end,
  restore = function() return M.restore() end,
  list = function()
    local plugins, mason, errors = M.pending()
    io.stdout:write(table.concat(M.report(plugins, mason), "\n") .. "\n")
    return errors
  end,
}

-- Runs one action inside the headless Neovim that scripts/update starts,
-- prints each failure and quits: exit 0 when nothing failed, 1 otherwise. A
-- headless Neovim keeps running after an error in a -c command, so every path
-- through here ends in a quit.
function M.child(action)
  local ok, result = xpcall(function()
    local work = ACTIONS[action]
    if not work then
      error("scripts/update has no action named " .. tostring(action), 0)
    end
    return work()
  end, debug.traceback)
  local failures = ok and result or { tostring(result) }
  for _, failure in ipairs(failures) do
    io.stderr:write(failure .. "\n")
  end
  vim.cmd(#failures == 0 and "qa!" or "cquit 1")
end

-- Runs argv and waits for it. With capture set, returns its exit code and
-- what it printed to each stream. Otherwise its output goes straight to the
-- terminal, since an update and the full check take minutes and report as
-- they go, and only the exit code returns.
function M.exec(argv, capture)
  if capture then
    local r = vim.system(argv, { text = true }):wait()
    return r.code, r.stdout or "", r.stderr or ""
  end
  local function through(stream)
    return function(_, data)
      if data then
        stream:write(data)
      end
    end
  end
  return vim.system(argv, { stdout = through(io.stdout), stderr = through(io.stderr) }):wait().code
end

-- The headless Neovim, started with this configuration, that runs action.
local function inside(root, action)
  local command = ("lua require('ach.update').child(%q)"):format(action)
  return { vim.v.progpath, "--headless", "-u", root .. "/init.lua", "-c", command }
end

local DIRTY = "These files have changes that are not committed, and undoing a failed update would lose them:\n"
  .. "%s\nCommit or restore them, then run scripts/update again."
local BACK = " The lock files are restored and every plugin and Mason package is back at its pinned version."
  .. " Nothing was committed."
local NOT_BACK = " The lock files are restored, but putting the installed versions back failed as well, as printed"
  .. " above. Once that is fixed, run scripts/update --restore. Nothing was committed."

-- A whole update of the repository at root: refuse over changes that are not
-- committed, update, run the full check, then commit or undo. Returns the
-- exit code. opts.apply, opts.check and opts.restore replace the three slow
-- steps, and opts.say replaces printing.
function M.run(root, opts)
  opts = opts or {}
  local apply = opts.apply or function() return M.exec(inside(root, "apply")) end
  local check = opts.check or function() return M.exec({ root .. "/scripts/check", "--full" }) end
  local restore = opts.restore or function() return M.exec(inside(root, "restore")) end
  local say = opts.say or function(text) io.stdout:write(text .. "\n") end
  local function git(...) return M.exec({ "git", "--no-optional-locks", "-C", root, ... }, true) end

  local code, dirty, err = git("status", "--porcelain", "--", unpack(M.FILES))
  if code ~= 0 then
    say("git could not read the repository's status: " .. vim.trim(err))
    return 1
  end
  if vim.trim(dirty) ~= "" then
    say(DIRTY:format((dirty:gsub("\n$", ""))))
    return 2
  end
  local before = M.locks(root)

  local function undo(why, status)
    git("checkout", "HEAD", "--", unpack(M.FILES))
    if restore() == 0 then
      say(why .. BACK)
      return status
    end
    say(why .. NOT_BACK)
    return 1
  end

  if apply() ~= 0 then
    return undo("The update failed before the full check ran.", 1)
  end
  if not M.message(before, M.locks(root)) then
    git("checkout", "HEAD", "--", unpack(M.FILES))
    say("Every plugin and Mason package was already at its latest version. Nothing was committed.")
    return 0
  end
  local status = check()
  if status == 2 then
    return undo("The full check needs a person to act, so it has not proven the update.", 2)
  elseif status ~= 0 then
    return undo("The full check failed after the update.", 1)
  end
  local subject, body = M.message(before, M.locks(root))
  local committed, _, why = git("commit", "--quiet", "--only", "-m", subject, "-m", body, "--", unpack(M.FILES))
  if committed ~= 0 then
    say("The full check passed, but git could not commit the lock files: " .. vim.trim(why))
    return 1
  end
  say("Committed: " .. subject)
  return 0
end

if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "update.lua" then
  local ok, status = xpcall(
    function() return M.run(assert(_G.arg[1], "usage: nvim -l lua/ach/update.lua ROOT")) end,
    debug.traceback
  )
  if not ok then
    io.stderr:write(tostring(status) .. "\n")
    os.exit(1)
  end
  os.exit(status)
end

return M
