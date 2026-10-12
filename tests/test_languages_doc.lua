-- The full test's document: how each layer's cell reads, the table it renders,
-- reading the committed copy back, and what counts as getting worse. Pure
-- functions over made-up results, so nothing here installs anything.
local function load(t) return dofile(t.root .. "/tests/helpers/languages_doc.lua") end

local function layer(want, works, needs) return { want = want, works = works or {}, needs = needs or {} } end

-- A language's result with every layer present, empty unless given.
local function result(name, layers)
  local r = { name = name, layers = {} }
  for _, key in ipairs({ "treesitter", "server", "formatter", "linter", "grammar" }) do
    r.layers[key] = layers[key] or layer({})
  end
  return r
end

-- What GHC's requirement installs with, as lang.command writes it.
local GHC = "brew install ghcup && ghcup install ghc --set recommended"

return {
  ["a layer with no tool reads none"] = function(t)
    local doc = load(t)
    t.eq(doc.cell(layer({})), "none")
    t.eq(doc.cell(nil), "none", "a layer the result leaves out")
  end,

  ["a cell names what worked, what failed and what is waiting on an install"] = function(t)
    local doc = load(t)
    t.eq(doc.cell(layer({ "basedpyright", "ruff" }, { "basedpyright", "ruff" })), "basedpyright, ruff")
    t.eq(doc.cell(layer({ "goimports", "gofumpt" }, { "gofumpt" })), "gofumpt; not working: goimports")
    t.eq(doc.cell(layer({ "sourcekit" }, {}, { sourcekit = "xcode-select --install" })), "waiting: sourcekit")
    t.eq(doc.cell(layer({ "a", "b", "c" }, { "a" }, { c = "brew install c" })), "a; not working: b; waiting: c")
  end,

  ["a language whose check failed reads check failed in every column"] = function(t)
    local doc = load(t)
    local text = doc.render({ { name = "java", error = "the child Neovim reported nothing (exit 124)" } }, "Measured.")
    local row = "| java | check failed | check failed | check failed | check failed | check failed |"
    t.ok(text:find(row, 1, true), text)
  end,

  ["render writes one row per language, sorted, under the stamp"] = function(t)
    local doc = load(t)
    local text = doc.render({
      result("python", {
        treesitter = layer({ "python" }, { "python" }),
        server = layer({ "basedpyright", "ruff" }, { "basedpyright" }),
      }),
      result("bsv", {}),
    }, "Measured on 2026-10-10 with Neovim 0.12.0.")
    local lines = vim.split(text, "\n")
    t.eq(lines[1], "# Languages", "the title")
    t.ok(vim.list_contains(lines, "Measured on 2026-10-10 with Neovim 0.12.0."), "the stamp")
    local rows = vim.tbl_filter(function(line) return line:sub(1, 2) == "| " end, lines)
    t.eq(rows, {
      "| Language | Tree-sitter | Server | Formatter | Linter | Grammar |",
      "| --- | --- | --- | --- | --- | --- |",
      "| bsv | none | none | none | none | none |",
      "| python | python | basedpyright; not working: ruff | none | none | none |",
    })
    t.eq(text:sub(-1), "\n", "the file ends with a newline")
  end,

  ["render lists each install a language is waiting on under the table, and none when nothing waits"] = function(t)
    local doc = load(t)
    local text = doc.render({
      result("haskell", { formatter = layer({ "fourmolu" }, {}, { fourmolu = GHC }) }),
      result("java", { server = layer({ "jdtls" }, {}, { jdtls = "brew install openjdk@21" }) }),
      result("groovy", { server = layer({ "groovyls" }, {}, { groovyls = "brew install openjdk@21" }) }),
    }, "Measured.")
    local lines = vim.split(text, "\n")
    local at = vim.fn.index(lines, "## Waiting on an install") + 1
    t.ok(at > 0, text)
    t.ok(at > vim.fn.index(lines, "| --- | --- | --- | --- | --- | --- |") + 1, "after the table")
    t.ok(vim.startswith(lines[at + 2], "The full run never installs from Homebrew or Xcode"), "says why they wait")
    t.eq(vim.list_slice(lines, at + 4, at + 5), {
      "- `" .. GHC .. "`, for haskell",
      "- `brew install openjdk@21`, for groovy, java",
    }, "one line per command, each with the languages waiting on it")
    t.eq(text:sub(-1), "\n", "the file ends with a newline")
    local none = doc.render({ result("go", { treesitter = layer({ "go" }, { "go" }) }) }, "Measured.")
    t.ok(not none:find("## Waiting on an install", 1, true), "nothing waits")
  end,

  ["parse reads back the working tools render wrote"] = function(t)
    local doc = load(t)
    local text = doc.render({
      result("go", {
        treesitter = layer({ "go" }, { "go" }),
        server = layer({ "gopls" }, { "gopls" }),
        formatter = layer({ "goimports", "gofumpt" }, { "gofumpt" }),
        linter = layer({ "golangcilint" }, {}, { golangcilint = "brew install go" }),
      }),
      { name = "java", error = "timed out" },
    }, "Measured.")
    local empty = { treesitter = {}, server = {}, formatter = {}, linter = {}, grammar = {} }
    t.eq(doc.parse(text), {
      go = { treesitter = { "go" }, server = { "gopls" }, formatter = { "gofumpt" }, linter = {}, grammar = {} },
      java = empty,
    })
    t.eq(doc.parse(""), {}, "no committed copy yet")
  end,

  ["compare names a tool that stopped working"] = function(t)
    local doc = load(t)
    local before = {
      python = {
        treesitter = { "python" },
        server = { "basedpyright", "ruff" },
        formatter = {},
        linter = {},
        grammar = {},
      },
    }
    local now = {
      result("python", {
        treesitter = layer({ "python" }, { "python" }),
        server = layer({ "basedpyright", "ruff" }, { "basedpyright" }),
      }),
    }
    t.eq(doc.compare(before, now), { "python: ruff worked before and does not now (Server)" })
  end,

  ["compare leaves out a tool not installed, one the table dropped, and a new language"] = function(t)
    local doc = load(t)
    local before = {
      swift = { treesitter = { "swift" }, server = { "sourcekit" }, formatter = {}, linter = {}, grammar = {} },
      go = {
        treesitter = { "go" },
        server = { "gopls" },
        formatter = { "goimports", "gofumpt" },
        linter = {},
        grammar = {},
      },
    }
    local now = {
      result("swift", {
        treesitter = layer({ "swift" }, { "swift" }),
        server = layer({ "sourcekit" }, {}, { sourcekit = "xcode-select --install" }),
      }),
      result("go", {
        treesitter = layer({ "go" }, { "go" }),
        server = layer({ "gopls" }, { "gopls" }),
        formatter = layer({ "gofumpt" }, { "gofumpt" }),
      }),
      result("zig", { server = layer({ "zls" }) }),
    }
    t.eq(doc.compare(before, now), {})
  end,

  ["compare names a language whose check did not finish"] = function(t)
    local doc = load(t)
    t.eq(doc.compare({}, { { name = "java", error = "timed out" } }), { "java: the check did not finish: timed out" })
  end,

  ["needs groups each install command with the languages waiting on it"] = function(t)
    local doc = load(t)
    local now = {
      result("haskell", {
        server = layer({ "haskell-tools.nvim" }, {}, { ["haskell-tools.nvim"] = GHC }),
        formatter = layer({ "fourmolu" }, {}, { fourmolu = GHC }),
        grammar = layer({ "harper_ls" }, {}, { harper_ls = GHC }),
      }),
      result("java", { server = layer({ "jdtls" }, {}, { jdtls = "brew install openjdk@21" }) }),
      result("groovy", { server = layer({ "groovyls" }, {}, { groovyls = "brew install openjdk@21" }) }),
      { name = "kotlin", error = "timed out" },
    }
    t.eq(doc.needs(now), { GHC .. " (for haskell)", "brew install openjdk@21 (for groovy, java)" })
  end,
}
