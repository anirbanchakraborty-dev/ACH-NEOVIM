-- Full mode only: scripts/check --full runs this file with the installer live.
-- It installs every language by opening its sample in a child Neovim, writes
-- what worked to docs/languages.md, and fails when a tool the committed copy
-- of that file records as working has stopped working.
local CHILD_MS = 1800000

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

local function doc(t) return dofile(t.root .. "/tests/helpers/languages_doc.lua") end

local measured -- every language's result, measured once per run

-- Opens every language's sample in its own child Neovim and returns the
-- results, sorted by language. A line after each language shows progress.
local function measure(t)
  if measured then
    return measured
  end
  local child = dofile(t.root .. "/tests/helpers/child.lua")
  local samples = dofile(t.root .. "/tests/fixtures/samples.lua")
  local probe = t.root .. "/tests/helpers/probe.lua"
  local names = {}
  for _, e in ipairs(require("ach.lang").entries()) do
    names[#names + 1] = e.name
  end
  table.sort(names)
  local results = {}
  for i, name in ipairs(names) do
    local dir = t.tmpdir()
    local body = ("report(dofile(%q)(%q, %q))"):format(probe, name, samples.write(dir, name))
    local opts = { env = { ACH_DRY_INSTALL = "0" }, cwd = dir, timeout = CHILD_MS, entered = true }
    local ok, result = pcall(child.run, t, body, opts)
    if not ok then
      io.stdout:write(("%s: %s\n"):format(name, tostring(result)))
      result = { name = name, error = tostring(result):match("[^\n]*") }
    end
    results[#results + 1] = result
    io.stdout:write(("checked %s, %d of %d\n"):format(name, i, #names))
    io.stdout:flush()
  end
  measured = results
  return results
end

-- The copy of docs/languages.md in the last commit, or "" before there is one.
local function committed(t)
  local r = vim.system({ "git", "-C", t.root, "show", "HEAD:docs/languages.md" }, { text = true }):wait()
  return r.code == 0 and r.stdout or ""
end

-- Loads Mason's registry in this Neovim. server_packages() is empty until it
-- has, and the children's downloads are not seen here until it is refreshed.
local function registry(t)
  local loaded = false
  require("ach.install").with_registry(function() loaded = true end)
  t.ok(vim.wait(300000, function() return loaded end, 100), "Mason's registry never loaded")
end

return {
  [":checkhealth ach reports no error once every language is installed"] = function(t)
    measure(t)
    registry(t)
    local errors = {}
    local h = vim.health
    local quiet = function() end
    with({
      { h, "start", quiet },
      { h, "ok", quiet },
      { h, "info", quiet },
      { h, "warn", quiet },
      {
        h,
        "error",
        function(msg) errors[#errors + 1] = msg end,
      },
    }, function() require("ach.health").check() end)
    t.eq(errors, {}, ":checkhealth ach errors")
  end,

  ["every language works as well as the committed docs/languages.md records"] = function(t)
    local d = doc(t)
    local before = d.parse(committed(t))
    local results = measure(t)
    local stamp = ("Measured on %s with Neovim %s."):format(os.date("%Y-%m-%d"), tostring(vim.version()))
    local f = assert(io.open(t.root .. "/docs/languages.md", "w"))
    f:write(d.render(results, stamp))
    f:close()
    t.eq(d.compare(before, results), {}, "what got worse")
  end,

  ["every Mason package and server in the table has a source"] = function(t)
    local install, lang, lsp = require("ach.install"), require("ach.lang"), require("ach.lsp")
    registry(t)
    local servers = install.server_packages()
    t.ok(next(servers) ~= nil, "Mason's registry is empty, so nothing can be checked against it")
    local unknown = {}
    for _, e in ipairs(lang.entries()) do
      for _, pkg in ipairs(e.mason or {}) do
        if not install.has_package(pkg) then
          unknown[#unknown + 1] = ("%s: Mason has no package %s"):format(e.name, pkg)
        end
      end
      for _, server in ipairs(e.lsp or {}) do
        local program = lsp.program(server)
        if not servers[server] and not (program and (e.system or {})[program]) then
          unknown[#unknown + 1] = ("%s: no Mason package carries %s, and the entry names no other source for %s"):format(
            e.name,
            server,
            tostring(program)
          )
        end
      end
    end
    t.eq(unknown, {}, "names with no source")
  end,

  ["every runtime and program the languages need is installed"] = function(t)
    local list = doc(t).needs(measure(t))
    if #list > 0 then
      t.human("Install these, then run scripts/check --full again:\n" .. table.concat(list, "\n"))
    end
  end,
}
