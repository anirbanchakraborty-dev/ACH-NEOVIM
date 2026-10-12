-- Installs what a language needs the first time a real file of it opens: its
-- Tree-sitter parsers, then, once its runtime is found, its Mason packages,
-- and then hands the buffer to M.ready. What Mason cannot install, a runtime
-- or a program such as a language's own server, is offered once a session,
-- and Homebrew installs it on a yes. Under ACH_DRY_INSTALL=1, which
-- scripts/check sets outside --full, it installs and asks nothing, and records
-- what it would have installed and asked in M.requests, so the regular suite
-- never downloads and never runs Homebrew.
local M = {}

M.dry = vim.env.ACH_DRY_INSTALL == "1"

local available -- nvim-treesitter's parser names, read once
local failed, pending -- parsers that failed this session; parser -> callbacks waiting on it
local failed_packages, busy -- the same two for Mason packages
local warned -- warnings already shown this session
local registry_ready, registry_waiting -- Mason's registry refreshed; callbacks waiting on it
local server_to_package -- language server -> Mason package, read once
local offers -- requirement name -> { state, fts }: what was offered, and for which file types
local queue, running -- Homebrew installs waiting their turn; whether one is running

function M.reset()
  M.requests = { parsers = {}, packages = {}, servers = {}, asks = {} }
  available, failed, pending = nil, {}, {}
  failed_packages, busy, warned = {}, {}, {}
  registry_ready, registry_waiting, server_to_package = false, nil, nil
  offers, queue, running = {}, {}, false
end
M.reset()

local function record(kind, names)
  local list = M.requests[kind]
  for _, name in ipairs(names) do
    if not vim.list_contains(list, name) then
      list[#list + 1] = name
    end
  end
  table.sort(list)
end

local function warn_once(key, msg, level)
  if warned[key] then
    return
  end
  warned[key] = true
  vim.notify(msg, level or vim.log.levels.WARN)
end

-- Parsers ---------------------------------------------------------------------

function M.available_parsers()
  if not available then
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then
      return {} -- not installed yet, as on the very first start
    end
    available = {}
    for _, name in ipairs(ts.get_available()) do
      available[name] = true
    end
  end
  return available
end

function M.installed_parsers()
  local set = {}
  if M.dry then
    return set
  end
  local ok, ts = pcall(require, "nvim-treesitter")
  for _, name in ipairs(ok and ts.get_installed("parsers") or {}) do
    set[name] = true
  end
  return set
end

-- Installs the parsers in names that exist, are missing and have not failed,
-- then calls done once. Two calls for the same parser share one install.
function M.ensure_parsers(names, done)
  done = done or function() end
  local known, installed = M.available_parsers(), M.installed_parsers()
  local want = {}
  for _, name in ipairs(names) do
    if known[name] and not installed[name] and not failed[name] and not vim.list_contains(want, name) then
      want[#want + 1] = name
    end
  end
  if #want == 0 then
    return done()
  end
  if M.dry then
    record("parsers", want)
    return done()
  end

  local remaining = #want
  local function one_done()
    remaining = remaining - 1
    if remaining == 0 then
      done()
    end
  end
  local new = {}
  for _, name in ipairs(want) do
    if not pending[name] then
      pending[name] = {}
      new[#new + 1] = name
    end
    table.insert(pending[name], one_done)
  end
  if #new == 0 then
    return
  end
  -- Forced, since nvim-treesitter counts a language as installed while its
  -- queries folder is there, even after its library is gone. Only parsers
  -- with no library reach this point.
  require("nvim-treesitter").install(new, { summary = false, force = true }):await(function()
    vim.schedule(function()
      local now = M.installed_parsers()
      for _, name in ipairs(new) do
        if not now[name] then
          failed[name] = true -- nvim-treesitter has already said why
        end
        local waiting = pending[name]
        pending[name] = nil
        for _, cb in ipairs(waiting) do
          cb()
        end
      end
    end)
  end)
end

-- Only a real file shows that the owner works in a language: a buffer with no
-- special type, a name, and a readable file behind that name. A picker's
-- preview, a help page, a scratch buffer and a file not yet written are not.
function M.is_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.filereadable(name) == 1
end

-- The parsers that the injection queries of langs name by a literal
-- injection.language, kept when nvim-treesitter can install them and langs
-- does not already hold them. A language that only a capture decides, as a
-- Markdown code block's does, is left to a file of that language.
function M.injected_parsers(langs)
  local known, found = M.available_parsers(), {}
  for _, lang in ipairs(langs) do
    local ok, files = pcall(vim.treesitter.query.get_files, lang, "injections")
    for _, file in ipairs(ok and files or {}) do
      for _, line in ipairs(vim.fn.readfile(file)) do
        if not line:match("^%s*;") then
          for name in line:gmatch('injection%.language%s+"([^"]+)"') do
            if known[name] and not vim.list_contains(langs, name) then
              found[name] = true
            end
          end
        end
      end
    end
  end
  local out = vim.tbl_keys(found)
  table.sort(out)
  return out
end

-- Mason packages ----------------------------------------------------------------

-- Refreshes Mason's registry once a session, then calls cb. Callers that
-- arrive during the refresh wait for it. A refresh that fails, as with no
-- network, is reported once, and Mason then works from the registry it has.
function M.with_registry(cb)
  if registry_ready then
    return cb()
  end
  if registry_waiting then
    table.insert(registry_waiting, cb)
    return
  end
  registry_waiting = { cb }
  require("mason-registry").refresh(function(ok, result)
    vim.schedule(function()
      if not ok then
        warn_once(
          "registry",
          ("Mason could not update its registry: %s"):format(tostring(result)),
          vim.log.levels.ERROR
        )
      end
      registry_ready = true
      local waiting = registry_waiting
      registry_waiting = nil
      for _, f in ipairs(waiting) do
        f()
      end
    end)
  end)
end

function M.has_package(name) return require("mason-registry").has_package(name) end

function M.package_installed(name) return require("mason-registry").is_installed(name) end

-- Each Mason package that carries a language server, keyed by the server's
-- name. Empty until the registry has been downloaded, and not kept then.
function M.server_packages()
  if server_to_package then
    return server_to_package
  end
  local ok, registry = pcall(require, "mason-registry")
  local listed, specs = false, {}
  if ok then
    listed, specs = pcall(registry.get_all_package_specs)
  end
  local map = {}
  for _, spec in ipairs(listed and specs or {}) do
    local server = vim.tbl_get(spec, "neovim", "lspconfig")
    if server then
      map[server] = spec.name
    end
  end
  if next(map) then
    server_to_package = map
  end
  return map
end

-- Installs the packages in names that Mason has, that are missing and that
-- have not failed, then calls done once. Two calls for the same package share
-- one install, and a failure is reported once and not tried again this
-- session.
function M.ensure_packages(names, done)
  done = done or function() end
  M.with_registry(function()
    local want = {}
    for _, name in ipairs(names) do
      if
        not failed_packages[name]
        and not vim.list_contains(want, name)
        and M.has_package(name)
        and not M.package_installed(name)
      then
        want[#want + 1] = name
      end
    end
    if #want == 0 then
      return done()
    end
    local remaining = #want
    local function one_done()
      remaining = remaining - 1
      if remaining == 0 then
        done()
      end
    end
    for _, name in ipairs(want) do
      if busy[name] then
        table.insert(busy[name], one_done)
      else
        busy[name] = { one_done }
        require("ach.masonlock").install(name, function(ok, err)
          if not ok then
            failed_packages[name] = true
            vim.notify(("Mason could not install %s: %s"):format(name, err or "no reason given"), vim.log.levels.ERROR)
          end
          local waiting = busy[name]
          busy[name] = nil
          for _, cb in ipairs(waiting) do
            cb()
          end
        end)
      end
    end
  end)
end

-- Homebrew ----------------------------------------------------------------------

-- Asks a yes-or-no question and calls cb(true) on yes. vim.ui.select shows
-- the two answers in whatever picker is set up; closing it without picking
-- counts as no. Tests replace this.
function M.ask(question, cb)
  vim.ui.select({ "Yes", "No" }, { prompt = question }, function(choice) cb(choice == "Yes") end)
end

local function last_line(text)
  local lines = vim.split(vim.trim(text or ""), "\n", { plain = true })
  return lines[#lines]
end

-- Runs argv in the background and calls cb(ok, output) on the main loop, where
-- output is the last line the command printed, from its error output when it
-- printed any there. A program that is not on the path fails at once, since
-- vim.system raises for it. Tests replace this.
function M.run(argv, cb)
  local ok, err = pcall(vim.system, argv, { text = true }, function(result)
    local said = last_line(result.stderr)
    if said == "" then
      said = last_line(result.stdout)
    end
    vim.schedule(function() cb(result.code == 0, said) end)
  end)
  if not ok then
    cb(false, tostring(err))
  end
end

-- Runs the queued installs one at a time, since two Homebrew installs at once
-- wait on each other's lock. A job's steps run in order, and the first that
-- fails ends the job.
local function next_job()
  if running or #queue == 0 then
    return
  end
  running = true
  local job = table.remove(queue, 1)
  local function step(i)
    if i > #job.steps then
      running = false
      job.done(true)
      return next_job()
    end
    -- A folder the step before made, such as rustup's, which Homebrew does
    -- not link, goes on the path before this step looks for its program.
    require("ach.runtimes").setup()
    vim.notify(("Installing %s, step %d of %d: %s"):format(job.name, i, #job.steps, table.concat(job.steps[i], " ")))
    M.run(job.steps[i], function(ok, said)
      if ok then
        return step(i + 1)
      end
      running = false
      job.done(false, said)
      next_job()
    end)
  end
  step(1)
end

-- Offers to install what Mason cannot: a runtime, or a program such as a
-- language's own server. The first real file that needs it asks once a
-- session, naming its file type, the Homebrew formulae and a rough size. On
-- yes the install joins the queue, and once it finishes every open file of a
-- file type that was waiting goes through ensure_tools again. A no or a
-- failure is final for the session. What Homebrew cannot install has its
-- command shown once instead. A dry run records the question, with what a yes
-- would run, in M.requests.asks, and neither asks nor shows anything.
function M.offer(req, ft, entry)
  local lang = require("ach.lang")
  local o = offers[req.name]
  if o then
    if not vim.list_contains(o.fts, ft) then
      o.fts[#o.fts + 1] = ft
    end
    if o.state == "done" then
      local msg = "Homebrew installed %s, but Neovim cannot find it. Restart Neovim, or install it by hand with: %s"
      warn_once("lost " .. req.name, msg:format(req.name, lang.command(req)))
    end
    return
  end
  o = { state = "asking", fts = { ft } }
  offers[req.name] = o

  local text
  if req.brew then
    local formulae = table.concat(req.brew, " and ")
    text = ("Install %s for %s files with Homebrew (%s, %s)?"):format(req.name, entry.name, formulae, req.size)
  else
    text = ("For %s files, install %s with: %s"):format(entry.name, req.name, lang.command(req))
  end
  if M.dry then
    o.state = "declined"
    table.insert(M.requests.asks, { question = text, run = lang.steps(req) })
    return
  end
  if not req.brew then
    o.state = "shown"
    vim.notify(text, vim.log.levels.WARN)
    return
  end

  M.ask(text, function(yes)
    if not yes then
      o.state = "declined"
      return
    end
    o.state = "installing"
    table.insert(queue, {
      name = req.name,
      steps = lang.steps(req),
      done = function(ok, said)
        local runtimes = require("ach.runtimes")
        runtimes.setup()
        runtimes.reset(req.name)
        if not ok then
          o.state = "failed"
          local why = (said and said ~= "") and said or "it gave no reason"
          local msg = "Installing %s failed: %s. Install it by hand with: %s"
          vim.notify(msg:format(req.name, why, lang.command(req)), vim.log.levels.ERROR)
          return
        end
        o.state = "done"
        vim.notify(("Installed %s."):format(req.name))
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.list_contains(o.fts, vim.bo[buf].filetype) then
            M.ensure_tools(buf, vim.bo[buf].filetype)
          end
        end
      end,
    })
    next_job()
  end)
end

-- Installs a file type's tools, for a real file only. A program Mason cannot
-- install is offered when it is missing. The runtime must work before
-- anything else installs, and is offered when it does not. Then the Mason
-- packages install and the buffer goes to M.ready. A dry run records the
-- packages, the servers and the questions instead, and installs nothing.
function M.ensure_tools(buf, ft)
  local lang = require("ach.lang")
  local entry = lang.for_ft(ft)
  if not entry or not M.is_file(buf) then
    return
  end
  if M.dry then
    record("packages", lang.packages_for_ft(ft, M.server_packages()))
    record("servers", lang.servers_for_ft(ft))
  end
  for program, req in pairs(entry.system or {}) do
    if vim.fn.executable(program) ~= 1 then
      M.offer(req, ft, entry)
    end
  end

  local function install()
    if M.dry then
      return
    end
    M.with_registry(function()
      M.ensure_packages(lang.packages_for_ft(ft, M.server_packages()), function()
        if vim.api.nvim_buf_is_valid(buf) then
          M.ready(buf, ft, entry)
        end
      end)
    end)
  end

  local runtime = entry.runtime
  if not runtime then
    return install()
  end
  require("ach.runtimes").check(runtime, function(ok)
    if ok then
      return install()
    end
    M.offer(runtime, ft, entry)
  end)
end

-- Called once a buffer's packages are installed, or have failed: enables the
-- file type's servers whose programs are now on the path, then hands a
-- managed language to its own plugin. enable_for runs first even for those,
-- because its first call sets the shared capabilities that rustaceanvim,
-- haskell-tools and lean.nvim merge into their own configuration.
function M.ready(buf, ft, entry)
  require("ach.lsp").enable_for(ft)
  if entry.managed then
    require("ach.managed").start(buf, entry)
  end
end

-- The hook ------------------------------------------------------------------------

-- Installs the parsers a buffer's file type needs and starts Tree-sitter on
-- it, then installs the file type's tools. Anything that is not a real file
-- gets whatever parser is already there, and nothing more.
local function handle(buf, ft)
  local attach = function() require("ach.treesitter").attach(buf) end
  if not M.is_file(buf) then
    return attach()
  end
  vim.b[buf].ach_handled = true
  local entry = require("ach.lang").for_ft(ft)
  local parsers = vim.deepcopy(entry and entry.ts or {})
  -- A file type the table does not list still gets its parser when one exists.
  local own = vim.treesitter.language.get_lang(ft) or ft
  if M.available_parsers()[own] and not vim.list_contains(parsers, own) then
    parsers[#parsers + 1] = own
  end
  -- The file's own parsers first, so it is highlighted as soon as they are
  -- there, then the ones their injection queries name, which those parsers'
  -- own queries, now installed, say.
  M.ensure_parsers(parsers, function()
    attach()
    M.ensure_parsers(M.injected_parsers(parsers), attach)
  end)
  M.ensure_tools(buf, ft)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ach_install", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev) handle(ev.buf, ev.match) end,
  })
  -- A new file is not a real file until it is written, so its first write is
  -- when it installs.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      if ft ~= "" and not vim.b[ev.buf].ach_handled then
        handle(ev.buf, ft)
      end
    end,
  })
end

return M
