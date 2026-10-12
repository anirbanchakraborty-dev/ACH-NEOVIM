-- :checkhealth ach. Every outside answer is a stand-in: which programs are
-- on the path and what each prints, which parsers and Mason packages are
-- installed, and what the lock pins. So no test depends on this Mac's tools,
-- and only the test of run itself starts a program.

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

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name) return found[name] and 1 or 0 end
end

local function set(list)
  local out = {}
  for _, name in ipairs(list or {}) do
    out[name] = true
  end
  return out
end

-- Runs the check with every outside answer replaced, and returns what it
-- reported: one { kind, msg, advice } per call, kind being the vim.health
-- function called. o names the answers, each empty when left out:
--   old       true for a Neovim older than 0.12
--   run       program -> the first line it prints; a program not named fails
--   found     the programs on the path, as a set
--   parsers   the installed parsers; packages, the installed Mason packages
--   servers   Mason's server -> package map, empty before the registry exists
--   lock      what mason-lock.json pins; installed, package -> version
--   registry  a whole stand-in for mason-registry, in place of installed
--   injected  parser -> the parsers its injection query names
---@param o table
local function report(o)
  local H, install = require("ach.health"), require("ach.install")
  local out, run, real_has = {}, o.run or {}, vim.fn.has
  local function record(kind)
    return function(msg, advice) out[#out + 1] = { kind = kind, msg = msg, advice = advice } end
  end
  local registry = o.registry
    or {
      get_installed_packages = function()
        local list = {}
        for name, version in pairs(o.installed or {}) do
          list[#list + 1] = {
            name = name,
            get_installed_version = function(_) return version end,
          }
        end
        return list
      end,
    }
  with({
    { vim.health, "start", record("start") },
    { vim.health, "ok", record("ok") },
    { vim.health, "info", record("info") },
    { vim.health, "warn", record("warn") },
    { vim.health, "error", record("error") },
    {
      vim.fn,
      "has",
      function(feature)
        if feature == "nvim-0.12" then
          return o.old and 0 or 1
        end
        return real_has(feature)
      end,
    },
    { vim.fn, "executable", only(o.found or {}) },
    {
      H,
      "run",
      function(argv)
        local line = run[argv[1]]
        if line == nil then
          return false
        end
        return true, line ~= "" and line or nil
      end,
    },
    {
      install,
      "installed_parsers",
      function() return set(o.parsers) end,
    },
    {
      install,
      "injected_parsers",
      function(langs) return (o.injected or {})[langs[1]] or {} end,
    },
    {
      install,
      "package_installed",
      function(name) return vim.list_contains(o.packages or {}, name) end,
    },
    {
      install,
      "has_package",
      function() return true end,
    },
    {
      install,
      "server_packages",
      function() return o.servers or {} end,
    },
    {
      require("ach.masonlock"),
      "read",
      function() return o.lock or {} end,
    },
    { package.loaded, "mason-registry", registry },
  }, H.check)
  return out
end

-- The reports under the section called title, without its heading.
local function section(out, title)
  local found, inside = {}, false
  for _, r in ipairs(out) do
    if r.kind == "start" then
      inside = r.msg == title
    elseif inside then
      found[#found + 1] = r
    end
  end
  return found
end

local function has(reports, kind, text)
  for _, r in ipairs(reports) do
    if r.kind == kind and r.msg:find(text, 1, true) then
      return true
    end
  end
  return false
end

-- The first report of this kind whose message contains text.
local function find(reports, kind, text)
  for _, r in ipairs(reports) do
    if r.kind == kind and r.msg:find(text, 1, true) then
      return r
    end
  end
  error(("no %s report containing %q"):format(kind, text), 2)
end

return {
  ["run returns the first line, from standard error when standard output is empty"] = function(t)
    local H = require("ach.health")
    t.eq({ H.run({ "sh", "-c", "printf 'one\\ntwo\\n'" }) }, { true, "one" }, "standard output")
    t.eq(
      { H.run({ "sh", "-c", "printf 'openjdk 21\\n' >&2" }) },
      { true, "openjdk 21" },
      "standard error, where java -version prints"
    )
    t.eq({ H.run({ "sh", "-c", "exit 3" }) }, { false }, "a program that fails and prints nothing")
    t.eq({ H.run({ "ach-no-such-program" }) }, { false }, "a program not on the path")
  end,

  ["a Neovim older than 0.12 is an error that says how to upgrade"] = function(t)
    local old = section(report({ old = true }), "Neovim")
    t.eq(#old, 1, "one report")
    t.eq(old[1].kind, "error", "an old Neovim")
    t.eq(old[1].advice, "brew upgrade neovim", "how to upgrade")
    local now = section(report({}), "Neovim")
    t.eq(now[1].kind, "ok", "a current Neovim")
    t.ok(now[1].msg:find(tostring(vim.version()), 1, true) ~= nil, "names the version")
  end,

  ["a missing build tool is an error with the command that installs it"] = function(t)
    local r = section(report({ run = { brew = "Homebrew 5.0.4" } }), "Build tools")
    t.eq(find(r, "ok", "Homebrew").msg, "Homebrew 5.0.4", "Homebrew's line names itself")
    t.eq(find(r, "error", "Command Line Tools").advice, "xcode-select --install", "the Command Line Tools")
    t.eq(find(r, "error", "tree-sitter").advice, "brew install tree-sitter-cli", "the tree-sitter program")
    local all = section(
      report({
        run = {
          brew = "Homebrew 5.0.4",
          ["xcode-select"] = "/Library/Developer/CommandLineTools",
          ["tree-sitter"] = "tree-sitter 0.25.10",
        },
      }),
      "Build tools"
    )
    t.eq(
      find(all, "ok", "Command Line Tools").msg,
      "Command Line Tools: /Library/Developer/CommandLineTools",
      "where the tools are"
    )
    t.ok(not has(all, "error", ""), "no errors")
    t.ok(has(all, "info", ":checkhealth mason"), "points at the plugins' own reports")
  end,

  ["a runtime shows its version, and a missing one warns only for a language in use"] = function(t)
    local L = require("ach.lang")
    local ghc, julia = L.get("haskell").runtime, L.get("julia").runtime
    local r =
      section(report({ run = { cargo = "cargo 1.90.0 (840b83a10 2025-07-30)" }, parsers = { "haskell" } }), "Runtimes")
    t.eq(find(r, "ok", "Rust").msg, "Rust: cargo 1.90.0 (840b83a10 2025-07-30)", "Rust's version")
    local g = find(r, "warn", ghc.name .. " is not installed")
    t.eq(g.advice, "brew install ghcup && ghcup install ghc --set recommended", "GHC, with Haskell in use")
    t.ok(g.msg:find("haskell", 1, true) ~= nil, "names the language that needs it")
    local j = find(r, "info", julia.name .. " is not installed")
    t.ok(j.msg:find("brew install julia", 1, true) ~= nil, "Julia, with no Julia file opened, carries its command")
    t.ok(not has(r, "warn", julia.name), "and does not warn")
  end,

  ["a program Mason does not carry warns only for a language in use, and Harper is not one"] = function(t)
    local r = section(report({ found = { dart = true }, parsers = { "gleam" } }), "Programs Mason does not carry")
    t.eq(find(r, "warn", "gleam").advice, "brew install gleam", "gleam, with Gleam in use")
    t.ok(
      find(r, "info", "nu is not installed").msg:find("brew install nushell", 1, true) ~= nil,
      "nushell, with no Nushell file opened"
    )
    t.eq(find(r, "ok", "dart").msg, "Installed: dart", "what is there, on one line")
    local xcode = find(r, "info", "sourcekit-lsp is not installed").msg
    t.ok(xcode:find("xcode-select --install", 1, true) ~= nil, "a program Homebrew cannot install has its own command")
    local harper = has(r, "warn", "harper") or has(r, "info", "harper")
    t.ok(not harper, "Harper is a Mason package, reported under Languages")
  end,

  ["a language is in use once something only it lists is installed"] = function(t)
    local H, install = require("ach.health"), require("ach.install")
    local used, judged
    with({
      {
        install,
        "installed_parsers",
        function() return set({ "yaml", "dockerfile", "rust" }) end,
      },
      {
        install,
        "injected_parsers",
        function() return {} end,
      },
      {
        install,
        "package_installed",
        function(name) return name == "prettier" end,
      },
    }, function()
      used, judged = H.in_use({})
    end)
    t.eq(used, { docker = true, rust = true }, "yaml and prettier are shared")
    t.eq(judged.go, true, "Go lists parsers of its own")
    t.eq(judged.vim, true, "Vim script lists the vim and vimdoc parsers")
    t.eq(judged.lean, nil, "Lean lists nothing from Tree-sitter or Mason")
  end,

  ["a parser another file brought in through an injection says nothing about its language"] = function(t)
    local H, install = require("ach.health"), require("ach.install")
    local used
    with({
      {
        install,
        "installed_parsers",
        function() return set({ "lua", "luadoc", "luap", "c", "query", "vim" }) end,
      },
      {
        install,
        "injected_parsers",
        function(langs)
          -- What Lua's injection query names: c for ffi.cdef, vim for
          -- vim.cmd and query for vim.treesitter.query.parse.
          return langs[1] == "lua" and { "c", "query", "vim" } or {}
        end,
      },
      {
        install,
        "package_installed",
        function() return false end,
      },
    }, function() used = H.in_use({}) end)
    t.eq(used, { lua = true }, "a Lua file was opened, and no C or Vim script file")
  end,

  ["a language in use lists what it has, and what it lacks with how to get it"] = function(t)
    local r = section(
      report({
        run = { cargo = "cargo 1.90.0", ghc = "9.14.1" },
        parsers = { "rust", "ron", "haskell" },
        packages = { "rust-analyzer", "fourmolu", "harper-ls", "haskell-language-server", "hlint" },
      }),
      "Languages"
    )
    t.eq(
      find(r, "ok", "haskell").msg,
      "haskell: haskell (Tree-sitter); fourmolu, harper-ls, haskell-language-server, hlint (Mason)",
      "Haskell has everything"
    )
    local rust = find(r, "warn", "rust")
    t.eq(rust.msg, "rust is missing codelldb (Mason)", "Rust lacks its debugger")
    t.eq(
      rust.advice,
      "Restart Neovim and open a rust file, since an install that failed is not tried again in the same session.",
      "how to get it"
    )
    t.ok(has(r, "info", "registry"), "says servers are left out until the registry is downloaded")
    local waiting = find(r, "info", "Not opened yet").msg
    t.ok(waiting:find("%f[%w]go%f[%W]") ~= nil, "Go is not opened yet")
    t.ok(waiting:find("%f[%w]rust%f[%W]") == nil, "Rust is")
  end,

  ["a missing runtime comes first in a language's advice"] = function(t)
    local hs = find(section(report({ parsers = { "haskell" } }), "Languages"), "warn", "haskell")
    t.eq(hs.msg, "haskell is missing fourmolu, harper-ls, haskell-language-server, hlint (Mason)", "nothing from Mason")
    t.eq(
      hs.advice,
      "Install GHC first, with: brew install ghcup && ghcup install ghc --set recommended. "
        .. "Then restart Neovim and open a haskell file.",
      "the runtime first"
    )
  end,

  ["with Mason's registry, a language server counts toward its language"] = function(t)
    local r = section(report({ servers = { gopls = "gopls" }, packages = { "gopls" } }), "Languages")
    t.ok(find(r, "warn", "go is missing").msg:find("gofumpt", 1, true) ~= nil, "Go is in use through gopls alone")
    t.ok(not has(r, "info", "registry"), "no note about the registry")
  end,

  ["Metals is reported with how to update it, or as coming with the first Scala file"] = function(t)
    local program = require("ach.managed").metals_program
    local r = section(report({ found = { [program] = true } }), "Metals")
    t.eq(r[1], { kind = "ok", msg = "Metals: " .. program }, "installed")
    t.eq(
      r[2].msg,
      ("Update Metals with: coursier update --install-dir %s metals"):format(vim.fs.dirname(program)),
      "how to update it"
    )
    local none = section(report({}), "Metals")
    t.eq(#none, 1, "one line")
    t.eq(none[1].kind, "info", "not installed yet is not a problem")
  end,

  ["lldb-dap is found through xcrun, or named missing with the file types it debugs"] = function(t)
    local path = "/Library/Developer/CommandLineTools/usr/bin/lldb-dap"
    local r = section(report({ run = { xcrun = path } }), "Debugging")
    t.eq(find(r, "ok", "lldb-dap").msg, "lldb-dap: " .. path, "found")
    local none = find(section(report({}), "Debugging"), "warn", "lldb-dap")
    t.ok(none.msg:find("c, cpp, objc, objcpp, swift, zig", 1, true) ~= nil, "names what cannot be debugged")
    t.eq(none.advice, "xcode-select --install", "how to get it")
  end,

  ["hdb needs GHC 9.14 or later, and its absence warns only with Haskell in use"] = function(t)
    local D = require("ach.dap")
    local old = find(section(report({ found = { hdb = true }, run = { ghc = "9.12.2" } }), "Debugging"), "warn", "hdb")
    t.ok(old.msg:find("9.12.2", 1, true) ~= nil, "names the GHC on the path")
    t.eq(old.advice, "ghcup install ghc --set latest", "how to get a newer one")
    local new = section(report({ found = { hdb = true }, run = { ghc = "9.14.1" } }), "Debugging")
    t.eq(find(new, "ok", "hdb").msg, "hdb, with GHC 9.14.1", "a new enough GHC")
    t.ok(has(section(report({}), "Debugging"), "info", D.hdb_missing), "no hdb, and no Haskell file opened")
    t.ok(
      has(section(report({ parsers = { "haskell" } }), "Debugging"), "warn", D.hdb_missing),
      "no hdb, with Haskell in use"
    )
  end,

  ["Mason names each package off its pin, with the command that settles it"] = function(t)
    local r = section(
      report({
        installed = { stylua = "v2.1.0", shfmt = "v3.12.0", ruff = "0.13.0" },
        lock = { stylua = "v2.1.0", shfmt = "v3.11.0" },
      }),
      "Mason"
    )
    local unpinned = find(r, "warn", "not pinned")
    t.eq(unpinned.msg, "Installed but not pinned in mason-lock.json: ruff", "ruff has no line in the lock")
    t.eq(unpinned.advice, ":AchMasonLock pins each at the version installed now", "how to pin it")
    local drift = find(r, "warn", "shfmt")
    t.eq(drift.msg, "shfmt is at v3.12.0, and mason-lock.json pins v3.11.0", "shfmt has moved")
    t.eq(drift.advice[1], ":MasonInstall shfmt@v3.11.0 returns it to the pin", "back to the pin")
    t.ok(not has(r, "ok", ""), "nothing is called fine")
    local fine = section(
      report({ installed = { stylua = "v2.1.0", shfmt = "v3.11.0" }, lock = { stylua = "v2.1.0", shfmt = "v3.11.0" } }),
      "Mason"
    )
    t.eq(
      fine,
      { { kind = "ok", msg = "2 packages installed, each at the version mason-lock.json pins" } },
      "all pinned"
    )
  end,

  ["Mason with nothing installed says so"] = function(t)
    local r = section(report({}), "Mason")
    t.eq(#r, 1, "one line")
    t.eq(r[1].kind, "info", "not a problem")
  end,

  ["the sections come in order, and one that fails is reported without stopping the rest"] = function(t)
    local H = require("ach.health")
    local out
    with({
      {
        H.sections[1],
        2,
        function() error("boom") end,
      },
    }, function() out = report({}) end)
    local titles = {}
    for _, r in ipairs(out) do
      if r.kind == "start" then
        titles[#titles + 1] = r.msg
      end
    end
    t.eq(titles, {
      "Neovim",
      "Build tools",
      "Runtimes",
      "Programs Mason does not carry",
      "Languages",
      "Metals",
      "Debugging",
      "Mason",
      "Integrations",
    }, "every section, in order")
    local neovim = section(out, "Neovim")
    t.eq(#neovim, 1, "one report")
    t.eq(neovim[1].kind, "error", "reported as an error")
    t.ok(neovim[1].msg:find("boom", 1, true) ~= nil, "with what went wrong")
  end,
}
