-- :checkhealth ach. Reports what is installed and what is missing, from
-- Neovim itself down to each language's parsers and Mason packages, with the
-- command that installs each missing piece. It installs nothing.
local install = require("ach.install")
local lang = require("ach.lang")

local M = {}

-- Runs argv and returns whether it exited 0, and the first line it printed:
-- from standard error when standard output is empty, which is where
-- `java -version` prints. A program not on the path is false at once.
function M.run(argv)
  if vim.fn.executable(argv[1]) ~= 1 then
    return false
  end
  local ok, result = pcall(function() return vim.system(argv, { text = true, timeout = 10000 }):wait() end)
  if not ok then
    return false
  end
  local out = vim.trim(result.stdout or "")
  if out == "" then
    out = vim.trim(result.stderr or "")
  end
  local line = vim.split(out, "\n", { plain = true })[1]
  return result.code == 0, line ~= "" and line or nil
end

local function list(names) return table.concat(names, ", ") end

-- "Rust: cargo 1.90.0", but "tree-sitter 0.25.10" rather than
-- "tree-sitter: tree-sitter 0.25.10", where the line names itself.
local function found(name, line)
  if not line then
    return name
  end
  if vim.startswith(line:lower(), name:lower()) then
    return line
  end
  return name .. ": " .. line
end

-- A missing tool is a warning when a language in use needs it, since that
-- language is not getting what it should, and information otherwise, since
-- a language never opened is missing nothing yet.
local function missing(needed, msg, how)
  if needed then
    vim.health.warn(msg, how)
  else
    vim.health.info(("%s Install it with: %s"):format(msg, how))
  end
end

-- How many languages list each parser and each Mason package.
local function listed(map)
  local parsers, packages = {}, {}
  for _, e in ipairs(lang.entries()) do
    for _, name in ipairs(e.ts or {}) do
      parsers[name] = (parsers[name] or 0) + 1
    end
    for _, name in ipairs(lang.packages_for_ft(e.ft[1], map)) do
      packages[name] = (packages[name] or 0) + 1
    end
  end
  return parsers, packages
end

-- The parsers an installed parser's injection query names, such as the vim,
-- c and query parsers a Lua file brings in with its own. Installed that way,
-- a parser says nothing about which language was opened.
local function brought_in(installed)
  local out = {}
  for name in pairs(installed) do
    for _, other in ipairs(install.injected_parsers({ name })) do
      out[other] = true
    end
  end
  return out
end

-- Which languages have been opened on this Mac. Nothing records that between
-- sessions, so it is judged from what is installed: a language counts once a
-- parser or package that only it lists is there. One that other languages
-- list too, such as the yaml parser, which Docker Compose files use, says
-- nothing about which language was opened, and nor does a parser that
-- another installed parser brought in. Returns the languages in use, and the
-- languages that list anything of their own, which are the only ones this
-- can judge.
function M.in_use(map)
  local parsers, packages = listed(map)
  local installed = install.installed_parsers()
  local injected = brought_in(installed)
  local used, judged = {}, {}
  for _, e in ipairs(lang.entries()) do
    for _, name in ipairs(e.ts or {}) do
      if parsers[name] == 1 then
        judged[e.name] = true
        if installed[name] and not injected[name] then
          used[e.name] = true
        end
      end
    end
    for _, name in ipairs(lang.packages_for_ft(e.ft[1], map)) do
      if packages[name] == 1 then
        judged[e.name] = true
        if install.package_installed(name) then
          used[e.name] = true
        end
      end
    end
  end
  return used, judged
end

-- Each runtime's command runs once per report, however many sections ask.
local function probe(s, runtime)
  local r = s.runtimes[runtime.name]
  if not r then
    local ok, line = M.run(runtime.check)
    r = { ok = ok, line = line }
    s.runtimes[runtime.name] = r
  end
  return r
end

local function neovim()
  local version = tostring(vim.version())
  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim " .. version)
  else
    vim.health.error(
      ("Neovim %s is older than 0.12, which this configuration needs"):format(version),
      "brew upgrade neovim"
    )
  end
end

-- Homebrew installs Neovim and every program Mason does not carry. The
-- Command Line Tools hold the C compiler every parser is built with, and
-- git. /usr/bin/cc and /usr/bin/git are there either way, as stand-ins that
-- only offer to install them, so xcode-select is asked where the tools are.
local build_tools = {
  {
    name = "Homebrew",
    argv = { "brew", "--version" },
    absent = "Homebrew is not installed. It installs Neovim and every program Mason does not carry.",
    how = "Install it from https://brew.sh",
  },
  {
    name = "Command Line Tools",
    argv = { "xcode-select", "-p" },
    absent = "The Command Line Tools are not installed. They hold the C compiler every parser is built with, and git.",
    how = "xcode-select --install",
  },
  {
    name = "tree-sitter",
    argv = { "tree-sitter", "--version" },
    absent = "tree-sitter is not installed. It builds each parser from its grammar.",
    how = "brew install tree-sitter-cli",
  },
}

local function build()
  for _, tool in ipairs(build_tools) do
    local ok, line = M.run(tool.argv)
    if ok then
      vim.health.ok(found(tool.name, line))
    else
      vim.health.error(tool.absent, tool.how)
    end
  end
  vim.health.info("For a closer look at parsers and Mason, run :checkhealth nvim-treesitter and :checkhealth mason.")
end

-- Each language runtime once, with the languages that need it.
local function runtimes(s)
  local needs, names = {}, {}
  for _, e in ipairs(lang.entries()) do
    local runtime = e.runtime
    if runtime then
      local n = needs[runtime.name]
      if not n then
        n = { runtime = runtime, languages = {}, used = false }
        needs[runtime.name] = n
        names[#names + 1] = runtime.name
      end
      n.languages[#n.languages + 1] = e.name
      n.used = n.used or s.used[e.name] == true
    end
  end
  table.sort(names, function(a, b) return a:lower() < b:lower() end)
  for _, name in ipairs(names) do
    local n = needs[name]
    local r = probe(s, n.runtime)
    if r.ok then
      vim.health.ok(found(name, r.line))
    else
      missing(
        n.used,
        ("%s is not installed, so %s files get no language server and no Mason tools."):format(name, list(n.languages)),
        lang.command(n.runtime)
      )
    end
  end
end

-- Each program the table installs from outside Mason, once, with the
-- languages that use it and the command that installs it: a Homebrew line,
-- or a command of its own, such as xcode-select --install for sourcekit-lsp.
local function programs(s)
  local needs, names, have = {}, {}, {}
  for _, e in ipairs(lang.entries()) do
    for program, req in pairs(e.system or {}) do
      local n = needs[program]
      if not n then
        n = { how = lang.command(req), languages = {}, used = false }
        needs[program] = n
        names[#names + 1] = program
      end
      n.languages[#n.languages + 1] = e.name
      n.used = n.used or s.used[e.name] == true
    end
  end
  table.sort(names)
  for _, program in ipairs(names) do
    local n = needs[program]
    if vim.fn.executable(program) == 1 then
      have[#have + 1] = program
    else
      missing(n.used, ("%s is not installed. %s files use it."):format(program, list(n.languages)), n.how)
    end
  end
  if #have > 0 then
    table.sort(have)
    vim.health.ok("Installed: " .. list(have))
  end
end

-- "rust, ron (Tree-sitter); codelldb (Mason)", leaving out an empty half.
local function describe(items)
  local parts = {}
  if #items.parsers > 0 then
    parts[#parts + 1] = list(items.parsers) .. " (Tree-sitter)"
  end
  if #items.packages > 0 then
    parts[#parts + 1] = list(items.packages) .. " (Mason)"
  end
  return table.concat(parts, "; ")
end

-- Each language in use, with what it has, or with what it lacks and how to
-- get it; then the languages not opened yet. A package Mason does not carry
-- is left out, as the installer leaves it out.
local function languages(s)
  local installed = install.installed_parsers()
  local waiting, any = {}, false
  for _, e in ipairs(lang.entries()) do
    if s.used[e.name] then
      any = true
      local have, lack = { parsers = {}, packages = {} }, { parsers = {}, packages = {} }
      for _, name in ipairs(e.ts or {}) do
        table.insert(installed[name] and have.parsers or lack.parsers, name)
      end
      for _, name in ipairs(lang.packages_for_ft(e.ft[1], s.map)) do
        if install.has_package(name) then
          table.insert(install.package_installed(name) and have.packages or lack.packages, name)
        end
      end
      if #lack.parsers + #lack.packages == 0 then
        vim.health.ok(("%s: %s"):format(e.name, describe(have)))
      else
        local runtime = e.runtime
        local how = ("Restart Neovim and open a %s file, since an install that failed is not tried again in the same session."):format(
          e.name
        )
        if runtime and not probe(s, runtime).ok then
          how = ("Install %s first, with: %s. Then restart Neovim and open a %s file."):format(
            runtime.name,
            lang.command(runtime),
            e.name
          )
        end
        vim.health.warn(("%s is missing %s"):format(e.name, describe(lack)), how)
      end
    elseif s.judged[e.name] then
      waiting[#waiting + 1] = e.name
    end
  end
  if not any then
    vim.health.info("No language has been opened yet.")
  end
  if next(s.map) == nil then
    vim.health.info(
      "Mason's registry has not been downloaded yet, so this list leaves out language servers. "
        .. "Open any file with the network on, or run :MasonUpdate."
    )
  end
  if #waiting > 0 then
    vim.health.info(
      ("Not opened yet, so nothing is installed for: %s. Each language's tools install the first time one of its files opens."):format(
        list(waiting)
      )
    )
  end
end

local function metals()
  local program = require("ach.managed").metals_program
  if vim.fn.executable(program) == 1 then
    vim.health.ok("Metals: " .. program)
    vim.health.info(("Update Metals with: coursier update --install-dir %s metals"):format(vim.fs.dirname(program)))
  else
    vim.health.info("Metals is not installed yet. Coursier installs it the first time a Scala file opens.")
  end
end

-- lldb-dap comes with the Command Line Tools and is found through xcrun, as
-- the debugger runs it. hdb comes from a release on GitHub and needs GHC 9.14
-- or later on the path.
local function debugging(s)
  local dap = require("ach.dap")
  local ok, path = M.run({ "xcrun", "--find", "lldb-dap" })
  if ok then
    vim.health.ok(found("lldb-dap", path))
  else
    vim.health.warn(
      ("lldb-dap was not found, so %s programs cannot be debugged."):format(list(dap.lldb_filetypes)),
      "xcode-select --install"
    )
  end
  if vim.fn.executable("hdb") ~= 1 then
    if s.used.haskell then
      vim.health.warn(dap.hdb_missing)
    else
      vim.health.info(dap.hdb_missing)
    end
    return
  end
  local _, version = M.run({ "ghc", "--numeric-version" })
  local parsed = version and vim.version.parse(version)
  if parsed and not vim.version.lt(parsed, { 9, 14, 0 }) then
    vim.health.ok(("hdb, with GHC %s"):format(version))
  else
    local ghc = version and ("the GHC on the path is " .. version) or "no GHC is on the path"
    vim.health.warn(("hdb needs GHC 9.14 or later, and %s."):format(ghc), "ghcup install ghc --set latest")
  end
end

-- Every Mason package against mason-lock.json. One with no line was
-- installed by hand from the :Mason window, and one at another version was
-- updated there; each is named with the command that settles it.
local function mason()
  local lock = require("ach.masonlock").read()
  local packages = {}
  for _, pkg in ipairs(require("mason-registry").get_installed_packages()) do
    packages[#packages + 1] = pkg
  end
  if #packages == 0 then
    vim.health.info(
      "Mason has installed nothing yet. A language's packages install the first time one of its files opens."
    )
    return
  end
  table.sort(packages, function(a, b) return a.name < b.name end)
  local unpinned, drifted = {}, 0
  for _, pkg in ipairs(packages) do
    local version, pin = pkg:get_installed_version(), lock[pkg.name]
    if pin == nil then
      unpinned[#unpinned + 1] = pkg.name
    elseif version ~= pin then
      drifted = drifted + 1
      vim.health.warn(
        ("%s is at %s, and mason-lock.json pins %s"):format(pkg.name, version or "an unknown version", pin),
        {
          (":MasonInstall %s@%s returns it to the pin"):format(pkg.name, pin),
          ":AchMasonUpdate moves every package and its pin to the latest version",
        }
      )
    end
  end
  if #unpinned > 0 then
    vim.health.warn(
      "Installed but not pinned in mason-lock.json: " .. list(unpinned),
      ":AchMasonLock pins each at the version installed now"
    )
  end
  if #unpinned + drifted == 0 then
    vim.health.ok(
      ("%d %s installed, each at the version mason-lock.json pins"):format(
        #packages,
        #packages == 1 and "package" or "packages"
      )
    )
  end
end

M.sections = {
  { "Neovim", neovim },
  { "Build tools", build },
  { "Runtimes", runtimes },
  { "Programs Mason does not carry", programs },
  { "Languages", languages },
  { "Metals", metals },
  { "Debugging", debugging },
  { "Mason", mason },
}

-- Called by :checkhealth ach. A section that fails is reported as an error
-- under its own heading, and the sections after it still run.
function M.check()
  local map = install.server_packages()
  local used, judged = M.in_use(map)
  local s = { map = map, used = used, judged = judged, runtimes = {} }
  for _, section in ipairs(M.sections) do
    vim.health.start(section[1])
    local ok, err = pcall(section[2], s)
    if not ok then
      vim.health.error("This check failed: " .. tostring(err))
    end
  end
end

return M
