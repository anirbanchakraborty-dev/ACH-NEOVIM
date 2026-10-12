-- Mason. The lock file reads, writes, pins and updates without touching the
-- repository's own copy; Homebrew's Java and Ruby and the toolchain folders
-- go on the path; a dry run records a file type's packages and servers, and
-- the Homebrew question it would have asked; and the Review Focus cases hold:
-- a missing compiler is asked about once and a no installs nothing, a yes
-- installs it in the background, one install at a time, and then the
-- language's tools, a failed Homebrew install names its command once, a
-- failed download is reported once per tool, two buffers of one language
-- share each install, and a buffer that is not a file is never asked about.
-- No test downloads or runs Homebrew: each one replaces Mason's registry, the
-- commands Homebrew would run, or the installer's calls into them.

-- The Docker entry's servers and their Mason packages, so no test needs the
-- registry to map one to the other.
local DOCKER = {
  dockerls = "dockerfile-language-server",
  docker_compose_language_service = "docker-compose-language-service",
}
local DOCKER_PACKAGES = { "docker-compose-language-service", "dockerfile-language-server", "hadolint" }

-- The Haskell entry's Mason packages, Harper's among them, and the question a
-- Haskell file asks on a Mac with no GHC.
local HASKELL_PACKAGES = { "fourmolu", "harper-ls", "haskell-language-server", "hlint" }
local GHC_QUESTION = "Install GHC for haskell files with Homebrew (ghcup, about 3 GB)?"

-- Replaces fields for the length of body, then puts every one back and
-- clears the session state, even when body fails. Each stub is
-- { table, key, value }.
local function with(stubs, body)
  local undo = {}
  for _, s in ipairs(stubs) do
    undo[#undo + 1] = { s[1], s[2], s[1][s[2]] }
    s[1][s[2]] = s[3]
  end
  local function clear()
    require("ach.install").reset()
    require("ach.runtimes").reset()
  end
  local ok, err = pcall(function()
    clear()
    body()
  end)
  for i = #undo, 1, -1 do
    local u = undo[i]
    u[1][u[2]] = u[3]
  end
  pcall(clear)
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.notify, and the messages it was given at one level.
local function collector()
  local seen = {}
  return seen, function(msg, level) seen[#seen + 1] = { msg = msg, level = level } end
end

local function messages(seen, level)
  local out = {}
  for _, m in ipairs(seen) do
    if m.level == level then
      out[#out + 1] = m.msg
    end
  end
  table.sort(out)
  return out
end

-- A Mason package that installs at once, and a registry holding only it.
-- With an error, every install fails with that error.
local function fake_package(installed_version, err)
  local pkg = { name = "fake", asked = {} }
  function pkg:is_installing() return false end
  function pkg:install(opts, cb)
    self.asked[#self.asked + 1] = opts.version or "latest"
    cb(err == nil, err)
  end
  function pkg:get_installed_version() return installed_version end
  return pkg, {
    get_package = function() return pkg end,
  }
end

-- The stubs that stand the installer up live, with no registry behind it.
local function live(install, extra)
  local stubs = {
    { install, "dry", false },
    { install, "with_registry", function(cb) cb() end },
    { install, "server_packages", function() return DOCKER end },
    { install, "has_package", function() return true end },
    { install, "package_installed", function() return false end },
  }
  return vim.list_extend(stubs, extra)
end

-- A loaded buffer for a file that exists on disk, the only kind of buffer
-- ensure_tools acts on. Its file type is set with noautocmd, so the
-- installer's own FileType hook does not run for it and reach nvim-treesitter.
local function file_buf(t, name, ft)
  local path = t.tmpdir() .. "/" .. name
  vim.fn.writefile({ "" }, path)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, path)
  vim.api.nvim_buf_call(buf, function() vim.cmd("noautocmd setlocal filetype=" .. ft) end)
  return buf
end

return {
  ["the lock file reads as empty when it is missing or broken"] = function(t)
    local lock = require("ach.masonlock")
    local dir = t.tmpdir()
    vim.fn.writefile({ "not json" }, dir .. "/broken.json")
    t.eq(lock.read(dir .. "/missing.json"), {}, "a missing file")
    t.eq(lock.read(dir .. "/broken.json"), {}, "a broken file")
  end,

  ["the lock file is written sorted, one package to a line"] = function(t)
    local lock = require("ach.masonlock")
    local path = t.tmpdir() .. "/mason-lock.json"
    t.eq(lock.encode({}), "{}\n", "an empty lock")
    lock.write({ stylua = "v2.3.0", basedpyright = "1.31.0" }, path)
    t.eq(vim.fn.readfile(path), { "{", '  "basedpyright": "1.31.0",', '  "stylua": "v2.3.0"', "}" }, "the file")
    t.eq(lock.read(path), { basedpyright = "1.31.0", stylua = "v2.3.0" }, "read back")
  end,

  ["a first install pins the version Mason chose, and later installs use the pin"] = function(t)
    local lock = require("ach.masonlock")
    local path = t.tmpdir() .. "/mason-lock.json"
    local pkg, registry = fake_package("1.4.2")
    local results = {}
    with({ { lock, "path", path }, { package.loaded, "mason-registry", registry } }, function()
      lock.install("fake", function(ok) results[#results + 1] = ok end)
      t.ok(vim.wait(1000, function() return #results == 1 end), "the first install finished")
      lock.install("fake", function(ok) results[#results + 1] = ok end)
      t.ok(vim.wait(1000, function() return #results == 2 end), "the second install finished")
      t.eq(pkg.asked, { "latest", "1.4.2" }, "versions asked for")
      t.eq(results, { true, true }, "results")
      t.eq(lock.read(path), { fake = "1.4.2" }, "the lock")
    end)
  end,

  ["a failed install pins nothing and says why"] = function(t)
    local lock = require("ach.masonlock")
    local path = t.tmpdir() .. "/mason-lock.json"
    local _, registry = fake_package(nil, "network is unreachable")
    with({ { lock, "path", path }, { package.loaded, "mason-registry", registry } }, function()
      local got
      lock.install("fake", function(ok, err) got = { ok, err } end)
      t.ok(vim.wait(1000, function() return got ~= nil end), "the install finished")
      t.eq(got, { false, "network is unreachable" }, "result")
      t.eq(lock.read(path), {}, "the lock")
    end)
  end,

  ["pinning adds lines for new packages and changes no existing line"] = function(t)
    local lock = require("ach.masonlock")
    local path = t.tmpdir() .. "/mason-lock.json"
    local function installed(name, version)
      return {
        name = name,
        get_installed_version = function() return version end,
      }
    end
    local registry = {
      get_installed_packages = function() return { installed("current", "2.0"), installed("new", "3.0") } end,
    }
    lock.write({ current = "1.9", other_mac = "0.1" }, path)
    with({ { lock, "path", path }, { package.loaded, "mason-registry", registry } }, function()
      t.eq(lock.adopt(), { "new" }, "lines added")
      t.eq(lock.read(path), { current = "1.9", new = "3.0", other_mac = "0.1" }, "the lock")
    end)
  end,

  ["an update moves each package to its latest version and rewrites its line"] = function(t)
    local lock = require("ach.masonlock")
    local path = t.tmpdir() .. "/mason-lock.json"
    local function package_at(name, installed, latest)
      local p = { name = name, installed = installed }
      function p:get_installed_version() return self.installed end
      function p:get_latest_version() return latest end
      function p:is_installing() return false end
      function p:install(opts, cb)
        self.installed = opts.version
        cb(true, {})
      end
      return p
    end
    local old, current = package_at("old", "1.0", "1.1"), package_at("current", "2.0", "2.0")
    local registry = {
      refresh = function(cb) cb(true, {}) end,
      get_installed_packages = function() return { old, current } end,
    }
    lock.write({ current = "2.0", old = "1.0", other_mac = "0.1" }, path)
    with({ { lock, "path", path }, { package.loaded, "mason-registry", registry } }, function()
      local changed, failed
      lock.update(function(c, f)
        changed, failed = c, f
      end)
      t.ok(vim.wait(1000, function() return changed ~= nil end), "the update finished")
      t.eq({ changed, failed }, { { "old" }, {} }, "packages moved and packages that failed")
      t.eq(lock.read(path), { current = "2.0", old = "1.1", other_mac = "0.1" }, "the lock")
    end)
  end,

  ["Homebrew's Java goes on the path when JAVA_HOME is unset"] = function(t)
    local runtimes = require("ach.runtimes")
    local dir = t.tmpdir()
    local home = dir .. "/openjdk@21/libexec/openjdk.jdk/Contents/Home"
    vim.fn.mkdir(home .. "/bin", "p")
    vim.fn.writefile({}, home .. "/bin/java")
    local saved_home, saved_path = vim.env.JAVA_HOME, vim.env.PATH
    local ok, err = pcall(function()
      vim.env.JAVA_HOME = nil
      local kegs = { dir .. "/openjdk@17", dir .. "/openjdk@21" }
      t.eq(runtimes.setup({ java = kegs, first = {}, last = {} }), home, "the JDK chosen")
      t.eq(vim.env.JAVA_HOME, home, "JAVA_HOME")
      t.eq(vim.split(vim.env.PATH, ":")[1], home .. "/bin", "the first folder on PATH")
      vim.env.PATH = saved_path
      vim.env.JAVA_HOME = "/elsewhere"
      t.eq(runtimes.setup({ java = kegs, first = {}, last = {} }), nil, "the JDK chosen when JAVA_HOME is set")
      t.eq(vim.env.PATH, saved_path, "PATH when JAVA_HOME is set")
    end)
    vim.env.JAVA_HOME, vim.env.PATH = saved_home, saved_path
    if not ok then
      error(err, 0)
    end
  end,

  ["Ruby goes first on the path and the toolchain folders last, once"] = function(t)
    local runtimes = require("ach.runtimes")
    local dir = t.tmpdir()
    vim.fn.mkdir(dir .. "/ruby/bin", "p")
    vim.fn.mkdir(dir .. "/ghcup/bin", "p")
    local opts = {
      java = {},
      first = { dir .. "/ruby/bin" },
      last = { dir .. "/ghcup/bin", dir .. "/missing/bin" },
    }
    local saved = vim.env.PATH
    local ok, err = pcall(function()
      runtimes.setup(opts)
      local after = vim.env.PATH
      local parts = vim.split(after, ":", { plain = true })
      t.eq(parts[1], dir .. "/ruby/bin", "the first folder on PATH")
      t.eq(parts[#parts], dir .. "/ghcup/bin", "the last folder on PATH")
      t.ok(not after:find(dir .. "/missing/bin", 1, true), "a folder that does not exist is left off")
      runtimes.setup(opts)
      t.eq(vim.env.PATH, after, "PATH after a second call")
    end)
    vim.env.PATH = saved
    if not ok then
      error(err, 0)
    end
  end,

  ["a runtime probe fails for a missing program and for a failing command"] = function(t)
    local runtimes = require("ach.runtimes")
    local function probe(argv)
      local result
      runtimes.probe(argv, function(ok) result = ok end)
      vim.wait(5000, function() return result ~= nil end)
      return result
    end
    t.eq({ probe({ "true" }), probe({ "false" }), probe({ "ach-no-such-program" }) }, { true, false, false })
  end,

  ["a dry run records a file type's packages and servers"] = function(t)
    local install = require("ach.install")
    local samples = dofile(t.root .. "/tests/fixtures/samples.lua")
    with({
      { install, "dry", true },
      { install, "server_packages", function() return DOCKER end },
    }, function()
      vim.cmd.edit(vim.fn.fnameescape(samples.write(t.tmpdir(), "docker")))
      vim.cmd("bwipeout!")
      t.eq(install.requests.packages, DOCKER_PACKAGES, "packages")
      t.eq(install.requests.servers, { "docker_compose_language_service", "dockerls" }, "servers")
    end)
  end,

  ["a dry run records what it would ask, and neither asks nor runs anything"] = function(t)
    local install, runtimes = require("ach.install"), require("ach.runtimes")
    local calls = 0
    local function count() calls = calls + 1 end
    with({
      { install, "dry", true },
      { install, "server_packages", function() return {} end },
      { install, "ask", count },
      { install, "run", count },
      { runtimes, "probe", function(_, cb) cb(false) end },
    }, function()
      local buf = file_buf(t, "Main.hs", "haskell")
      install.ensure_tools(buf, "haskell")
      install.ensure_tools(buf, "haskell")
      vim.api.nvim_buf_delete(buf, { force = true })
      t.eq(install.requests.asks, {
        {
          question = GHC_QUESTION,
          run = { { "brew", "install", "ghcup" }, { "ghcup", "install", "ghc", "--set", "recommended" } },
        },
      }, "what it would ask, and run on a yes")
      t.eq(calls, 0, "questions asked and commands run")
      t.eq(install.requests.packages, HASKELL_PACKAGES, "packages")
    end)
  end,

  ["a language whose compiler is missing asks once, and a no installs nothing"] = function(t)
    local install, lock, runtimes = require("ach.install"), require("ach.masonlock"), require("ach.runtimes")
    local probes, installs, ready, asked = 0, 0, 0, {}
    local seen, notify = collector()
    with(
      live(install, {
        { install, "ready", function() ready = ready + 1 end },
        {
          install,
          "ask",
          function(question, cb)
            asked[#asked + 1] = question
            cb(false)
          end,
        },
        { lock, "install", function() installs = installs + 1 end },
        {
          runtimes,
          "probe",
          function(_, cb)
            probes = probes + 1
            cb(false)
          end,
        },
        { vim, "notify", notify },
      }),
      function()
        local one, two = file_buf(t, "Main.hs", "haskell"), file_buf(t, "Notes.lhs", "lhaskell")
        install.ensure_tools(one, "haskell")
        install.ensure_tools(two, "lhaskell")
        install.ensure_tools(one, "haskell")
        vim.api.nvim_buf_delete(one, { force = true })
        vim.api.nvim_buf_delete(two, { force = true })
        t.eq(probes, 1, "times GHC was looked for")
        t.eq(asked, { GHC_QUESTION }, "questions asked")
        t.eq(seen, {}, "messages shown")
        t.eq({ installs, ready }, { 0, 0 }, "installs started and buffers handed on")
      end
    )
  end,

  ["a yes installs the compiler in the background, one at a time, and then the language's tools"] = function(t)
    local install, lock, runtimes = require("ach.install"), require("ach.masonlock"), require("ach.runtimes")
    local asked, ran, finish, installed, ready = {}, {}, {}, {}, {}
    local found = {} -- the programs Homebrew has installed so far
    with(
      live(install, {
        { install, "ready", function(buf) ready[#ready + 1] = buf end },
        {
          install,
          "ask",
          function(question, cb)
            asked[#asked + 1] = question
            cb(true)
          end,
        },
        {
          install,
          "run",
          function(argv, cb)
            ran[#ran + 1] = table.concat(argv, " ")
            finish[#finish + 1] = cb
          end,
        },
        {
          lock,
          "install",
          function(name, done)
            installed[#installed + 1] = name
            done(true)
          end,
        },
        { runtimes, "setup", function() end },
        { runtimes, "probe", function(argv, cb) cb(found[argv[1]] == true) end },
        { vim, "notify", function() end },
      }),
      function()
        local hs, go = file_buf(t, "Main.hs", "haskell"), file_buf(t, "main.go", "go")
        install.ensure_tools(hs, "haskell")
        install.ensure_tools(go, "go")
        t.eq(asked, { GHC_QUESTION, "Install Go for go files with Homebrew (go, about 250 MB)?" }, "questions asked")
        t.eq(ran, { "brew install ghcup" }, "commands started while the first runs")
        finish[1](true)
        t.eq(ran[2], "ghcup install ghc --set recommended", "GHC's own install, once ghcup is there")
        t.eq({ installed, ready }, { {}, {} }, "Haskell's tools before GHC is installed")
        found.ghc = true
        finish[2](true)
        table.sort(installed)
        t.eq(installed, HASKELL_PACKAGES, "Haskell's tools once GHC is installed")
        t.eq(ready, { hs }, "buffers handed on once GHC is installed")
        t.eq(ran[3], "brew install go", "Go's install, once GHC's has finished")
        found.go = true
        finish[3](true)
        t.eq(ready, { hs, go }, "buffers handed on once Go is installed")
        vim.api.nvim_buf_delete(hs, { force = true })
        vim.api.nvim_buf_delete(go, { force = true })
      end
    )
  end,

  ["a Homebrew install that fails names the command, and is not offered again"] = function(t)
    local install, lock, runtimes = require("ach.install"), require("ach.masonlock"), require("ach.runtimes")
    local asked, ran, installs = 0, {}, 0
    local seen, notify = collector()
    with(
      live(install, {
        { install, "ready", function() end },
        {
          install,
          "ask",
          function(_, cb)
            asked = asked + 1
            cb(true)
          end,
        },
        {
          install,
          "run",
          function(argv, cb)
            ran[#ran + 1] = table.concat(argv, " ")
            cb(false, "curl: (6) Could not resolve host: ghcr.io")
          end,
        },
        { lock, "install", function() installs = installs + 1 end },
        { runtimes, "setup", function() end },
        { runtimes, "probe", function(_, cb) cb(false) end },
        { vim, "notify", notify },
      }),
      function()
        local one, two = file_buf(t, "Main.hs", "haskell"), file_buf(t, "Other.hs", "haskell")
        install.ensure_tools(one, "haskell")
        install.ensure_tools(two, "haskell")
        install.ensure_tools(one, "haskell")
        vim.api.nvim_buf_delete(one, { force = true })
        vim.api.nvim_buf_delete(two, { force = true })
        t.eq(asked, 1, "questions asked")
        t.eq(ran, { "brew install ghcup" }, "commands run, GHC's own install waiting on a brew install that worked")
        t.eq(messages(seen, vim.log.levels.ERROR), {
          "Installing GHC failed: curl: (6) Could not resolve host: ghcr.io. "
            .. "Install it by hand with: brew install ghcup && ghcup install ghc --set recommended",
        }, "errors")
        t.eq(installs, 0, "Mason installs started")
      end
    )
  end,

  ["a program Homebrew cannot install has its command shown once, and is not asked about"] = function(t)
    local install, lock = require("ach.install"), require("ach.masonlock")
    local asked = 0
    local seen, notify = collector()
    local executable = vim.fn.executable
    with(
      live(install, {
        { install, "ready", function() end },
        { install, "ask", function() asked = asked + 1 end },
        { lock, "install", function(_, done) done(true) end },
        {
          vim.fn,
          "executable",
          function(program) return program == "sourcekit-lsp" and 0 or executable(program) end,
        },
        { vim, "notify", notify },
      }),
      function()
        local one, two = file_buf(t, "main.swift", "swift"), file_buf(t, "other.swift", "swift")
        install.ensure_tools(one, "swift")
        install.ensure_tools(two, "swift")
        vim.api.nvim_buf_delete(one, { force = true })
        vim.api.nvim_buf_delete(two, { force = true })
        t.eq(messages(seen, vim.log.levels.WARN), {
          "For swift files, install the Command Line Tools with: xcode-select --install",
        }, "warnings")
        t.eq(asked, 0, "questions asked")
      end
    )
  end,

  ["a buffer that is not a file is never probed, asked about or installed for"] = function(t)
    local install, lock, runtimes = require("ach.install"), require("ach.masonlock"), require("ach.runtimes")
    local calls = 0
    local function count() calls = calls + 1 end
    with(
      live(install, {
        { install, "ready", count },
        { install, "ask", count },
        { install, "run", count },
        { lock, "install", count },
        { runtimes, "probe", count },
      }),
      function()
        local real = t.tmpdir() .. "/Main.hs"
        vim.fn.writefile({ "main = pure ()" }, real)
        -- A scratch buffer, a picker's preview named after a real file, and a
        -- new file that has not been written yet.
        local scratch, preview = vim.api.nvim_create_buf(false, true), vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(preview, real)
        local unwritten = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(unwritten, t.tmpdir() .. "/New.hs")
        for _, buf in ipairs({ scratch, preview, unwritten }) do
          install.ensure_tools(buf, "haskell")
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        t.eq(calls, 0, "probes, questions, commands, installs and buffers handed on")
      end
    )
  end,

  ["a download that fails is reported once per tool and not tried again"] = function(t)
    local install, lock = require("ach.install"), require("ach.masonlock")
    local installs, ready = 0, 0
    local seen, notify = collector()
    with(
      live(install, {
        { install, "ready", function() ready = ready + 1 end },
        {
          lock,
          "install",
          function(_, done)
            installs = installs + 1
            done(false, "network is unreachable")
          end,
        },
        { vim, "notify", notify },
      }),
      function()
        local buf = file_buf(t, "Dockerfile", "dockerfile")
        install.ensure_tools(buf, "dockerfile")
        install.ensure_tools(buf, "dockerfile")
        vim.api.nvim_buf_delete(buf, { force = true })
        t.eq(installs, 3, "installs started")
        t.eq(messages(seen, vim.log.levels.ERROR), {
          "Mason could not install docker-compose-language-service: network is unreachable",
          "Mason could not install dockerfile-language-server: network is unreachable",
          "Mason could not install hadolint: network is unreachable",
        }, "errors")
        t.eq(ready, 2, "times the buffer was handed on, failures and all")
      end
    )
  end,

  ["two files of one language install each tool once, and both hear back"] = function(t)
    local install, lock = require("ach.install"), require("ach.masonlock")
    local started, finish, ready = {}, {}, {}
    with(
      live(install, {
        { install, "ready", function(buf) ready[#ready + 1] = buf end },
        {
          lock,
          "install",
          function(name, done)
            started[#started + 1] = name
            finish[#finish + 1] = function() done(true) end
          end,
        },
      }),
      function()
        local one, two = file_buf(t, "Dockerfile", "dockerfile"), file_buf(t, "Dockerfile", "dockerfile")
        install.ensure_tools(one, "dockerfile")
        install.ensure_tools(two, "dockerfile")
        table.sort(started)
        t.eq(started, DOCKER_PACKAGES, "installs started")
        t.eq(ready, {}, "buffers handed on before the installs finish")
        for _, f in ipairs(finish) do
          f()
        end
        t.eq(ready, { one, two }, "buffers handed on after the installs finish")
        vim.api.nvim_buf_delete(one, { force = true })
        vim.api.nvim_buf_delete(two, { force = true })
      end
    )
  end,

  ["the Mason key and commands exist, and the key has an icon"] = function(t)
    t.eq(vim.fn.maparg("<leader>cm", "n", false, true).desc, "Mason", "<leader>cm")
    t.eq({ vim.fn.exists(":AchMasonLock"), vim.fn.exists(":AchMasonUpdate") }, { 2, 2 }, "the commands")
    local found = require("ach.icons").key("Mason")
    t.ok(found and found.icon, "Mason has an icon")
  end,
}
