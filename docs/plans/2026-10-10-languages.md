# ACH-NEOVIM Languages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every language in the spec opens with Tree-sitter highlighting, its language server, format on save, linting and Harper's grammar checking wherever a tool for that layer exists, each language installing its own tools the first time one of its files is opened, all under the same headless suite.

**Architecture:** One table, `lua/ach/languages.lua`, names each language's file types, parsers, servers, formatters, linters, Mason packages, Homebrew tools and runtime. A pure engine, `lua/ach/lang.lua`, turns that table into the shape each plugin takes. A FileType hook in `lua/ach/install.lua` installs a language's parsers and Mason tools the first time a real file of that language is opened, asks once before Homebrew installs a compiler or runtime the language needs, then hands the buffer to the server, formatter and linter engines. Nothing installs at the first start. Under `scripts/check` the hook runs dry and only records what it would have installed, so the regular suite never downloads anything; `scripts/check --full` installs every language for real, tests each one on a sample file and writes `docs/languages.md`.

**Tech Stack:** nvim-treesitter and nvim-treesitter-textobjects (both on their `main` branch), mason.nvim 2, nvim-lspconfig (read as configuration data through `vim.lsp.config`), SchemaStore.nvim, lazydev.nvim, conform.nvim, nvim-lint, Harper (`harper-ls` from Mason), rustaceanvim, haskell-tools.nvim, nvim-jdtls, nvim-metals, lean.nvim, nvim-dap, nvim-dap-ui, nvim-nio, nvim-dap-virtual-text, mason-nvim-dap.nvim, nvim-dap-python, Xcode's `lldb-dap`.

**Spec:** `docs/specs/2026-10-10-ach-neovim-design.md`

This is the second of three plans, run in this order: foundation, languages, integrations. It starts from the configuration the foundation plan leaves behind, in which the theme, status bar, dashboard, keys, editor plugins and blink.cmp completion all work and `scripts/check` passes. It ends with every language in the table working and the suite still passing.

## Global Constraints

- Neovim 0.12 or later. Every command in this plan runs from the repository root, the folder that holds `init.lua`.
- LazyVim is a reference, never a dependency. Nothing requires or imports a `lazyvim` module. A file that adapts a LazyVim function says so in its header comment, as `-- Adapted from LazyVim (Apache-2.0), <path in LazyVim>.`
- Every key this configuration defines carries a `desc`, and that description has a line in `M.keys` in `lua/ach/icons.lua`. A task that adds a key adds its line above the marker `-- Keys added by later tasks go above this line.` in the same commit, and the same holds for groups and toggles with their own markers.
- Every icon comes from `lua/ach/icons.lua`, named there by its Nerd Fonts 3.5.1 name.
- Nothing writes into the repository while the editor runs, with three exceptions. `lazy-lock.json` changes during an update made on purpose. `mason-lock.json` gains a line the first time a Mason package is installed, and an existing line changes only under `:AchMasonUpdate`. `scripts/check --full` rewrites `docs/languages.md`.
- Language tools come from Mason, Harper's grammar checker among them, and install silently. The table's `system` and `runtime` fields name what Mason cannot supply: a compiler, a runtime or a program that only Homebrew installs. For each of those the editor asks once per session, in one line that names the language, the Homebrew formulae and a rough size. On yes, Homebrew installs it in the background, one install at a time, and the language's tools follow; on no, or when Homebrew fails, the editor asks nothing more about it that session. What Homebrew cannot install, such as Apple's Command Line Tools, is never asked about: the editor shows its command once.
- A language's parsers and tools install the first time one of its files is opened, and only for a real file: a buffer with no special type, a name, and a readable file behind it. Nothing installs at the first start. Neovim 0.12 carries the C, Lua, Markdown, query, Vim and Vim help parsers itself, which is what its help, command line and hover windows draw with.
- The regular suite never downloads and never runs Homebrew. `scripts/check` exports `ACH_DRY_INSTALL=1`, under which the installer records what it would install, and what it would ask, and installs nothing. Only `scripts/check --full` downloads, and even it answers no to every Homebrew question, so a language whose runtime is missing is recorded in `docs/languages.md` as waiting on it.
- A language server starts only once its program is installed. A missing server is never an error: the file still opens, with highlighting.
- C, C++, Objective-C, Swift and Zig debug through Apple's `lldb-dap`, from Xcode or its Command Line Tools, run as `xcrun lldb-dap`. Rust debugs through Mason's `codelldb`, which rustaceanvim drives.
- The spell file lives at `stdpath("data") .. "/spell/en.utf-8.add"`. Neovim's default would put it in the first folder of the runtime path, which is this repository through the `~/.config/nvim` link.
- Lua is formatted by `stylua.toml`: two-space indent, 120 columns, double quotes.
- Markdown in this repository keeps one paragraph per line, with no hard wrap and no numbered headings or numbered lists.
- Commits are made inside this repository, with `git commit --only <paths>` and a Conventional Commit subject that carries a scope. Nothing is pushed without the owner's yes.

## Review Focus

- **A download that fails, such as opening a Go file with no network.** The owner must see one message per tool for the session, naming the tool and the reason, and Neovim must not retry on every later Go buffer. The test lives in the Mason task.
- **A language whose compiler is missing, such as a Haskell file on a Mac with no GHC.** The owner must be asked once, in one line naming the language, `ghcup` and its rough size. On no, nothing more is asked and Mason installs nothing for Haskell that session. On yes, Homebrew runs in the background, one install at a time, and Haskell's tools install when it finishes. When Homebrew fails, one error names the command to run by hand, and the question is not asked again. The tests live in the Mason task.
- **Two files of one language opened at once, such as `:args *.py`.** Each tool must install once, not once per buffer, and both buffers must get the server when it finishes. The test lives in the Mason task.
- **A buffer that is not a file, such as a picker's preview of a Python file, a help window, or `:enew` then `:setfiletype python`.** Nothing may install for it, since only a real file shows that the owner works in that language; a new file installs its parsers once it is first written. The tests live in the tree-sitter task, and the Mason task checks that such a buffer is never asked about.
- **Saving before a language's formatter has finished installing.** The save must go through unformatted, with no error message. The test lives in the formatting task.

## File Structure

| Path | Responsibility |
| --- | --- |
| `lua/ach/languages.lua` | The language table: one entry per language, naming its file types, parsers, servers, formatters, linters and Mason packages, and what it needs from Homebrew: the formulae, any follow-up command and a rough size |
| `lua/ach/lang.lua` | The engine: pure functions that turn the table into what each plugin takes |
| `lua/ach/filetypes.lua` | File types Neovim does not detect by itself, and parsers that serve more than one file type |
| `lua/ach/treesitter.lua` | Starts highlighting, indentation and the text-object moves on a buffer whose parser is installed |
| `lua/ach/install.lua` | The FileType hook: installs a language's parsers and Mason tools the first time a real file of it is opened, asks once before Homebrew installs a compiler or runtime and runs those installs one at a time, or records all of it under `ACH_DRY_INSTALL=1` |
| `lua/ach/masonlock.lua` | `mason-lock.json`: the version of every Mason package, read, pinned on first install and moved on update |
| `lua/ach/runtimes.lua` | Puts Homebrew's Java and Ruby first on the path and the toolchain folders of rustup, cargo, ghcup, elan, opam and Homebrew's LLVM last, and checks whether a language's runtime is installed |
| `lua/ach/servers.lua` | The program behind each server whose nvim-lspconfig command is built by a function, and per-server settings |
| `lua/ach/lsp.lua` | Server capabilities, how diagnostics are drawn, the buffer-local LSP keys, and enabling a file type's servers |
| `lua/ach/format.lua` | conform's options: formatters per file type and the format-on-save rule |
| `lua/ach/lint.lua` | nvim-lint's linters per file type, the subset that can run, and when they run |
| `lua/ach/grammar.lua` | Spelling in prose, the spell file's location, and Harper's settings |
| `lua/ach/managed.lua` | Rust, Haskell, Java, Scala and Lean, whose own plugin starts the server |
| `lua/ach/health.lua` | `:checkhealth ach`, in eight sections: Neovim, the build tools, each runtime, the programs Mason does not carry, each language's Mason packages, Metals, the debuggers, and Mason's registry |
| `lua/ach/plugins/treesitter.lua` | nvim-treesitter and nvim-treesitter-textobjects |
| `lua/ach/plugins/mason.lua` | mason.nvim, and the `:AchMasonLock` and `:AchMasonUpdate` commands |
| `lua/ach/plugins/lsp.lua` | nvim-lspconfig, SchemaStore.nvim, lazydev.nvim and its completion source |
| `lua/ach/plugins/format.lua` | conform.nvim and its keys |
| `lua/ach/plugins/lint.lua` | nvim-lint |
| `lua/ach/plugins/managed.lua` | rustaceanvim, haskell-tools.nvim, nvim-jdtls, nvim-metals, lean.nvim |
| `lua/ach/dap.lua` | The breakpoint signs, which Mason adapters to set up and which to leave to a language's own plugin, the adapters and launch choices this configuration writes itself, the debug keys, and the hook-ups for Java, Scala and Haskell |
| `lua/ach/plugins/dap.lua` | nvim-dap, its interface, inline values, mason-nvim-dap and nvim-dap-python, each pinned, with `lua/ach/dap.lua` doing the setup |
| `mason-lock.json` | Pinned Mason package versions, written by `lua/ach/masonlock.lua` |
| `docs/languages.md` | The table `scripts/check --full` writes: one row per language, naming the tool behind each layer or saying none exists |
| `tests/fixtures/samples.lua` | One sample file per language, with a misformatted line and a planted lint warning where the language has those tools, and `write()`, which puts a sample on disk |
| `tests/helpers/child.lua` | Runs a second, headless Neovim with this configuration and returns what a Lua body reported |
| `tests/helpers/languages_doc.lua` | Renders `docs/languages.md` from the full mode's results, reads the committed copy back, and says what got worse and what is waiting on an install |
| `tests/helpers/probe.lua` | Runs inside a child Neovim in full mode: opens one language's sample, lets the installer finish, and tries each layer |
| `tests/test_lang.lua`, `tests/test_filetypes.lua`, `tests/test_treesitter.lua`, `tests/test_mason.lua`, `tests/test_lsp.lua`, `tests/test_format.lua`, `tests/test_lint.lua`, `tests/test_grammar.lua`, `tests/test_managed.lua`, `tests/test_dap.lua`, `tests/test_health.lua`, `tests/test_languages_doc.lua` | One file per area |
| `tests/test_full_languages.lua` | Full mode only: installs and exercises every language, writes `docs/languages.md`, and fails when a tool the committed copy records as working has stopped |
| `scripts/check` | Gains `ACH_DRY_INSTALL=1` outside full mode |
| `scripts/on-demand`, `scripts/on_demand.lua` | Prints every Homebrew formula the editor may offer to install, one per line, without starting the configuration |
| `lua/ach/init.lua` | Gains the file types, runtimes, grammar and install setup calls, in that order, before lazy.nvim |
| `lua/ach/icons.lua` | Gains a line in `M.keys` for every key this plan adds |

The samples live as text in one Lua file rather than as some ninety loose files, so that each sample sits next to the misformatted line and the warning planted in it. `write()` puts a sample on disk under its real file name, inside a temporary folder, before a test opens it, so no test ever edits a file inside the repository.

---

### Task: Language table and engine

**Files:**
- Create: `lua/ach/languages.lua`, `lua/ach/lang.lua`, `scripts/on-demand`, `scripts/on_demand.lua`
- Test: `tests/test_lang.lua`

**Interfaces:**
- Consumes: nothing from earlier tasks. Both modules are plain Lua tables and functions, with no plugin loaded.
- Produces:
  - `require("ach.languages")`: `languages: table<string, Entry>`, `parsers: table<string, {url, revision, queries}>` (parsers from outside nvim-treesitter), and `grammar = { server = "harper_ls", program = "harper-ls", package = "harper-ls" }`, where `package` is Harper's Mason package. An `Entry` has `ft: string[]` and optionally `ts`, `lsp`, `fmt`, `lint`, `mason`, `system`, `runtime`, `harper`, `manual` and `managed`, as the file's header comment defines them. `runtime` is a `Requirement` and `system` maps a program to a `Requirement`. A `Requirement` is `{ name: string, check?: string[], brew?: string[], after?: string[][], size?: string, command?: string }`: a runtime always has `check`; every requirement has either `brew` with a `size` beginning "about", or `command` alone when Homebrew cannot install it.
  - `require("ach.lang")`, every function pure and every list sorted unless said otherwise:
    - `entries(): Entry[]`, sorted by name, each a copy carrying `.name`; `get(name): Entry|nil`; `for_ft(ft): Entry|nil`.
    - `parsers_for_ft(ft): string[]`, the entry's `ts` list in table order.
    - `servers_for_ft(ft): string[]`, the entry's `lsp` list in table order, then `"harper_ls"` when Harper checks that file type. `servers(): string[]`, every server in the table plus `"harper_ls"`.
    - `formatters_by_ft(): table<ft, string[]>` and `linters_by_ft(): table<ft, string[]>`, each holding only file types with a non-empty list.
    - `packages_for_ft(ft, server_to_package: table<string,string>): string[]`, the Mason packages of the entry's servers through the given map, plus its `mason` list, plus `"harper-ls"` where Harper checks that file type.
    - `harper_filetypes(): string[]`, `is_harper_ft(ft): boolean`, `manual_filetypes(): string[]`, `is_manual(ft): boolean`.
    - `runtime_for_ft(ft): Requirement|nil`, `system_for_ft(ft): table<program, string>` (each outside program mapped to `command()` of its requirement), `managed_for_ft(ft): string|nil`.
    - `command(req: Requirement): string`, the one line that installs a requirement, as the owner would type it: `req.command`, or `brew install` with its formulae followed by each `after` argv, joined by ` && `.
    - `steps(req: Requirement): string[][]`, the argv lists the editor runs to install it, `brew install` first; an empty list for a requirement that can only be printed.
    - `formulae(): string[]`, every Homebrew formula any runtime or outside program names, sorted, each once.
    - `custom_parsers()`, `all_parsers(): string[]`, `all_packages(server_to_package): string[]`.
  - `scripts/on-demand`: prints `formulae()`, one per line, and exits 0. It needs only `nvim` on the path and does not start the configuration.

Most tools a language needs come from Mason, the package manager inside Neovim, which downloads each one into Neovim's own data folder without asking. Some cannot come from there. A compiler such as GHC, Haskell's, is several gigabytes and lives system-wide, and Homebrew, the Mac's package manager, is what installs it. The table calls such a thing a requirement. A runtime is a requirement the language's tools need before Mason can install anything for it, and carries a `check`, a command that succeeds only once the runtime is installed. An outside program is a requirement whose presence is simply whether its program is on the path. Every requirement names what it is, the Homebrew formulae that install it (a formula is one Homebrew package), any commands to run after Homebrew finishes, and a rough size, so that a later task can ask the owner one plain question before installing it. A requirement Homebrew cannot install, such as Apple's Command Line Tools, carries only the command the owner runs by hand. `scripts/on-demand` prints every formula the editor may ever offer, so that a Mac's setup can list them without installing them.

- [ ] **Write the failing tests**

`tests/test_lang.lua`:

```lua
-- The language table and the engine that reads it. Every test requires its
-- modules inside its own body, so a missing module fails each test by name.

-- The language ids harper-ls reads, from harper-ls/src/backend.rs and
-- harper-comments/src/comment_parser.rs as of 2026-10-10. Neovim sends a
-- buffer's file type as its language id. "sh" and "cs" are not on Harper's
-- list, but its comment parser falls back on the file's extension, which
-- reaches the shell and C# grammars.
local HARPER_KNOWS = {
  "asciidoc", "c", "clojure", "cmake", "cpp", "cs", "csharp", "daml", "dart", "elixir", "gitcommit", "git-commit",
  "gleam", "go", "groovy", "haskell", "html", "ink", "java", "javascript", "javascriptreact", "kotlin", "latex",
  "lhaskell", "literate haskell", "lua", "mail", "markdown", "nix", "octo", "org", "php", "plaintex", "plaintext",
  "powershell", "python", "quarto", "ruby", "rust", "scala", "scminput", "sh", "shellscript", "solidity", "swift",
  "tex", "text", "toml", "typescript", "typescriptreact", "typst", "zig",
}

local FIELDS = {
  ft = true, ts = true, lsp = true, fmt = true, lint = true, mason = true, system = true,
  runtime = true, harper = true, manual = true, managed = true,
}

local MANAGED = { rustaceanvim = true, ["haskell-tools.nvim"] = true, ["nvim-jdtls"] = true, ["nvim-metals"] = true, ["lean.nvim"] = true }

-- What is wrong with a runtime or an outside program's requirement, or nil.
-- The editor asks about a requirement by its name, formulae and size, so each
-- must be there, and a runtime also needs the check that proves it installed.
local function requirement_fault(req, is_runtime)
  if type(req) ~= "table" or type(req.name) ~= "string" then
    return "no name"
  end
  if is_runtime and not (vim.islist(req.check) and #req.check > 0) then
    return "no check"
  end
  if req.command ~= nil then
    if type(req.command) ~= "string" or req.brew or req.after or req.size then
      return "a printed command must stand alone"
    end
    return nil
  end
  if not (vim.islist(req.brew) and #req.brew > 0) then
    return "no formulae and no command"
  end
  for _, argv in ipairs(req.after or {}) do
    if not (vim.islist(argv) and #argv > 0) then
      return "a follow-up that is not an argv list"
    end
  end
  if type(req.size) ~= "string" or not req.size:match("^about ") then
    return 'no size beginning "about"'
  end
  return nil
end

return {
  ["every entry uses known fields and names its file types"] = function(t)
    local bad = {}
    for name, e in pairs(require("ach.languages").languages) do
      for field in pairs(e) do
        if not FIELDS[field] then
          bad[#bad + 1] = name .. ": unknown field " .. field
        end
      end
      if type(e.ft) ~= "table" or #e.ft == 0 then
        bad[#bad + 1] = name .. ": ft must be a non-empty list"
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "malformed entries")
  end,

  ["a file type belongs to one entry only"] = function(t)
    local owner, bad = {}, {}
    for name, e in pairs(require("ach.languages").languages) do
      for _, ft in ipairs(e.ft) do
        if owner[ft] then
          bad[#bad + 1] = ("%s is in both %s and %s"):format(ft, owner[ft], name)
        end
        owner[ft] = name
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "file types claimed twice")
  end,

  ["a per-file-type map names only the entry's own file types"] = function(t)
    local bad = {}
    for name, e in pairs(require("ach.languages").languages) do
      local own = {}
      for _, ft in ipairs(e.ft) do
        own[ft] = true
      end
      for _, field in ipairs({ "fmt", "lint" }) do
        if type(e[field]) == "table" and not vim.islist(e[field]) then
          for ft in pairs(e[field]) do
            if not own[ft] then
              bad[#bad + 1] = ("%s.%s names %s"):format(name, field, ft)
            end
          end
        end
      end
      if type(e.harper) == "table" then
        for _, ft in ipairs(e.harper) do
          if not own[ft] then
            bad[#bad + 1] = ("%s.harper names %s"):format(name, ft)
          end
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "maps naming another entry's file type")
  end,

  ["every runtime and outside program says how it is installed"] = function(t)
    local bad = {}
    for name, e in pairs(require("ach.languages").languages) do
      if e.runtime then
        local fault = requirement_fault(e.runtime, true)
        if fault then
          bad[#bad + 1] = ("%s.runtime: %s"):format(name, fault)
        end
      end
      for program, req in pairs(e.system or {}) do
        local fault = requirement_fault(req, false)
        if fault then
          bad[#bad + 1] = ("%s.system[%s]: %s"):format(name, program, fault)
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "requirements the editor could neither ask about nor print")
  end,

  ["a requirement's command is what the owner would type, and its steps are what the editor runs"] = function(t)
    local lang = require("ach.lang")
    local ghc = lang.get("haskell").runtime
    t.eq(lang.command(ghc), "brew install ghcup && ghcup install ghc --set recommended", "GHC's command")
    t.eq(
      lang.steps(ghc),
      { { "brew", "install", "ghcup" }, { "ghcup", "install", "ghc", "--set", "recommended" } },
      "GHC's steps, Homebrew first"
    )
    t.eq(lang.command(lang.get("scala").runtime), "brew install coursier openjdk@21", "two formulae in one brew")
    local xcode = lang.get("swift").system["sourcekit-lsp"]
    t.eq(lang.command(xcode), "xcode-select --install", "Homebrew cannot install the Command Line Tools")
    t.eq(lang.steps(xcode), {}, "so the editor runs nothing for them")
  end,

  ["a managed language names a known plugin and enables no server itself"] = function(t)
    local bad = {}
    for name, e in pairs(require("ach.languages").languages) do
      if e.managed and not MANAGED[e.managed] then
        bad[#bad + 1] = name .. ": unknown plugin " .. e.managed
      end
      if e.managed and e.lsp then
        bad[#bad + 1] = name .. ": a managed language must not list servers"
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "managed entries")
  end,

  ["the languages the spec names are in the table"] = function(t)
    local lang = require("ach.lang")
    local want = {
      "verilog", "systemverilog", "vhdl", "veryl", "bsv", "firrtl", "tcl", "sdc", "xdc", "dts", "ld", "llvm",
      "mlir", "tablegen", "asm", "nasm", "cuda", "scala", "python", "haskell", "sh", "perl", "swift", "html",
      "css", "make", "proto", "graphql", "glsl", "hlsl", "wgsl", "bzl", "just", "meson", "ninja", "kconfig",
    }
    local missing = {}
    for _, ft in ipairs(want) do
      if not lang.for_ft(ft) then
        missing[#missing + 1] = ft
      end
    end
    t.eq(missing, {}, "file types the spec names")
  end,

  ["every LazyVim 16.0.1 language pack has an entry"] = function(t)
    local lang = require("ach.lang")
    -- Each pack, by the name of its file in LazyVim's lua/lazyvim/plugins/extras/lang/,
    -- mapped to a file type it covers.
    local packs = {
      angular = "htmlangular", ansible = "yaml.ansible", astro = "astro", clangd = "c", clojure = "clojure",
      cmake = "cmake", dart = "dart", docker = "dockerfile", dotnet = "cs", elixir = "elixir", elm = "elm",
      ember = "handlebars", erlang = "erlang", git = "gitcommit", gleam = "gleam", go = "go", haskell = "haskell",
      helm = "helm", java = "java", json = "json", julia = "julia", kotlin = "kotlin", lean = "lean",
      markdown = "markdown", nix = "nix", nushell = "nu", ocaml = "ocaml", php = "php", prisma = "prisma",
      python = "python", r = "r", rego = "rego", ruby = "ruby", rust = "rust", scala = "scala",
      solidity = "solidity", sql = "sql", svelte = "svelte", terraform = "terraform", tex = "tex",
      thrift = "thrift", toml = "toml", twig = "twig", typescript = "typescript", typst = "typst", vue = "vue",
      yaml = "yaml", zig = "zig",
    }
    local missing = {}
    for pack, ft in pairs(packs) do
      if not lang.for_ft(ft) then
        missing[#missing + 1] = pack
      end
    end
    -- LazyVim's tailwind pack is a server, not a file type.
    if not vim.tbl_contains(lang.servers_for_ft("css"), "tailwindcss") then
      missing[#missing + 1] = "tailwind"
    end
    table.sort(missing)
    t.eq(vim.tbl_count(packs) + 1, 49, "LazyVim 16.0.1 has 49 language packs")
    t.eq(missing, {}, "packs with no entry")
  end,

  ["formatters are listed per file type"] = function(t)
    local f = require("ach.lang").formatters_by_ft()
    t.eq(f.go, { "goimports", "gofumpt" }, "go")
    t.eq(f.gomod, nil, "gomod has no formatter")
    t.eq(f.lua, { "stylua" }, "lua")
    t.eq(f.cabal, { "cabal_fmt" }, "cabal")
    t.eq(f.zsh, nil, "zsh has no formatter")
    t.eq(f.cuda, { "clang_format" }, "cuda shares C's formatter")
  end,

  ["linters are listed per file type"] = function(t)
    local l = require("ach.lang").linters_by_ft()
    t.eq(l.go, { "golangcilint" }, "go")
    t.eq(l.terraform, { "tflint" }, "terraform")
    t.eq(l.hcl, nil, "hcl has no linter")
    t.eq(l.markdown, { "markdownlint-cli2" }, "markdown")
    t.eq(l.xdc, { "tclint" }, "Xilinx constraints are Tcl")
  end,

  ["Harper checks only languages it reads"] = function(t)
    local lang = require("ach.lang")
    local known = {}
    for _, id in ipairs(HARPER_KNOWS) do
      known[id] = true
    end
    local unknown = {}
    for _, ft in ipairs(lang.harper_filetypes()) do
      if not known[ft] then
        unknown[#unknown + 1] = ft
      end
    end
    t.eq(unknown, {}, "file types Harper would be sent but cannot read")
    t.eq(lang.is_harper_ft("ps1"), false, "Harper's id is powershell, not ps1")
    t.eq(lang.is_harper_ft("gitcommit"), true, "commit messages")
    t.eq(lang.is_harper_ft("gitconfig"), false, "git's config file")
    t.eq(lang.is_harper_ft("markdown"), true, "Markdown")
  end,

  ["prose is never formatted on save"] = function(t)
    t.eq(require("ach.lang").manual_filetypes(), { "bib", "markdown", "markdown.mdx", "plaintex", "tex", "text", "typst" })
  end,

  ["a language's Mason packages include its servers' packages, and Harper's where it checks grammar"] = function(t)
    local lang = require("ach.lang")
    t.eq(
      lang.packages_for_ft("go", { gopls = "gopls" }),
      { "delve", "gofumpt", "goimports", "golangci-lint", "gomodifytags", "gopls", "harper-ls", "impl" },
      "go"
    )
    t.eq(
      lang.packages_for_ft("gomod", { gopls = "gopls" }),
      { "delve", "gofumpt", "goimports", "golangci-lint", "gomodifytags", "gopls", "impl" },
      "Harper checks go, not gomod"
    )
    t.eq(lang.packages_for_ft("rust", {}), { "codelldb", "harper-ls", "rust-analyzer" }, "rust")
    -- Mason has no package for sourcekit, so the map built from Mason's
    -- registry never names it, and Swift needs only Harper from Mason.
    t.eq(lang.packages_for_ft("swift", { gopls = "gopls" }), { "harper-ls" }, "swift's server comes with Xcode")
    t.eq(lang.packages_for_ft("gitcommit", {}), { "harper-ls" }, "commit messages")
    t.eq(lang.packages_for_ft("gitconfig", {}), {}, "git's config file")
    t.eq(lang.packages_for_ft("no such type", {}), {}, "an unknown file type")
  end,

  ["the servers for a file type include Harper where it checks grammar"] = function(t)
    local lang = require("ach.lang")
    t.eq(lang.servers_for_ft("python"), { "basedpyright", "ruff", "harper_ls" }, "python")
    t.eq(lang.servers_for_ft("rust"), { "harper_ls" }, "rust's server is rustaceanvim's")
    t.eq(lang.servers_for_ft("json"), { "jsonls" }, "json")
    t.eq(lang.servers_for_ft("no such type"), {}, "an unknown file type")
    t.ok(vim.tbl_contains(lang.servers(), "harper_ls"), "the full list includes Harper")
  end,

  ["a file type's outside programs map to the command that installs each"] = function(t)
    local lang = require("ach.lang")
    t.eq(lang.system_for_ft("swift"), { ["sourcekit-lsp"] = "xcode-select --install" }, "swift")
    t.eq(lang.system_for_ft("mlir"), { ["mlir-lsp-server"] = "brew install llvm" }, "mlir")
    t.eq(lang.system_for_ft("markdown"), {}, "Harper comes from Mason, so Markdown needs nothing from outside it")
    t.eq(lang.system_for_ft("json"), {}, "json")
  end,

  ["every parser is listed once, in order"] = function(t)
    local all = require("ach.lang").all_parsers()
    t.ok(vim.tbl_contains(all, "bash"), "the shell entry's parser")
    t.ok(vim.tbl_contains(all, "veryl"), "a parser from outside nvim-treesitter")
    local sorted = vim.deepcopy(all)
    table.sort(sorted)
    t.eq(all, sorted, "sorted")
    t.eq(#all, #vim.fn.uniq(vim.deepcopy(sorted)), "no name twice")
  end,

  ["every Homebrew formula the editor may offer is listed once, in order"] = function(t)
    t.eq(require("ach.lang").formulae(), {
      "coursier", "dart-sdk", "dotnet", "elan-init", "elixir", "erlang", "fish", "ghcup", "gleam", "go", "julia",
      "llvm", "nushell", "opam", "openjdk@21", "php", "powershell", "r", "ruby", "rustup", "zig",
    })
  end,

  ["scripts/on-demand prints the same formulae, one per line"] = function(t)
    local r = vim.system({ t.root .. "/scripts/on-demand" }, { cwd = t.root, text = true }):wait()
    t.eq(r.code, 0, "exit code, with stderr: " .. (r.stderr or ""))
    t.eq(vim.split(r.stdout, "\n", { trimempty = true }), require("ach.lang").formulae())
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_lang`
Expected: `0 passed, 18 failed, 0 need a person, 0 skipped`, exit 1. Every test fails with `module 'ach.languages' not found` or `module 'ach.lang' not found`, except the `scripts/on-demand` test, which fails because that script does not exist yet, so `vim.system` cannot start it.

- [ ] **Write the language table**

`lua/ach/languages.lua`:

```lua
-- Every language ACH-NEOVIM knows, one entry each. lua/ach/lang.lua turns this
-- table into Tree-sitter, language-server, formatter and linter settings, and
-- tests/test_lang.lua checks its shape. Each later plugin's own test checks
-- that the names in its field are ones that plugin knows.
--
-- Fields, all optional except ft:
--   ft       file types the entry covers; a file type belongs to one entry only
--   ts       nvim-treesitter parser names, or a name from M.parsers below
--   lsp      servers to enable; per-server settings live in lua/ach/servers.lua
--   fmt      conform formatters, a list for every ft or a map from ft to list
--   lint     nvim-lint linters, same two shapes
--   mason    Mason packages beyond the servers' own: debuggers, formatters, linters
--   system   programs from outside Mason, each mapped to the requirement that provides it;
--            the program being on the path is what proves it installed
--   runtime  a requirement with a check: a compiler or runtime that must exist before
--            Mason installs anything for the language
--   harper   true, or the list of this entry's file types, where Harper checks grammar
--   manual   true when the language is never formatted on save
--   managed  the plugin that starts this language's server itself
--
-- A requirement is a table. lua/ach/install.lua asks the owner once before
-- installing one, naming it, its formulae and its size.
--   name     what is asked about, as in "haskell files need GHC"
--   check    runtimes only: an argv that succeeds once the runtime is installed
--   brew     the Homebrew formulae that install it, in one `brew install`
--   after    argv lists run in order once Homebrew has finished
--   size     a rough download-and-disk size, "about 3 GB"; an estimate, never measured
--   command  instead of brew, size and after, when Homebrew cannot install it:
--            the command the owner is shown and runs by hand
local M = {}

-- Parsers that come from outside nvim-treesitter, pinned by commit.
M.parsers = {
  veryl = {
    url = "https://github.com/veryl-lang/tree-sitter-veryl",
    revision = "f38156e6fa97e7386cdfbcbcc537dc970a13c3ce",
    queries = "queries",
  },
  bsv = {
    url = "https://github.com/yuyuranium/tree-sitter-bsv",
    revision = "8c7f59f5fa86a73d56c97bbb1b84e0d5951364d8",
    queries = "queries",
  },
}

-- Harper, the grammar checker. Mason installs it, as the package named here,
-- the first time a file it checks is opened.
M.grammar = { server = "harper_ls", program = "harper-ls", package = "harper-ls" }

-- Requirements several entries share. Every size is a rough figure, rounded
-- up, there only so the owner knows what a yes costs.
local java = { name = "Java 21", check = { "java", "-version" }, brew = { "openjdk@21" }, size = "about 350 MB" }
local llvm = { name = "LLVM", brew = { "llvm" }, size = "about 2 GB" }
local xcode = { name = "the Command Line Tools", command = "xcode-select --install" }

M.languages = {
  -- Editor and shell -------------------------------------------------------
  lua = { ft = { "lua" }, ts = { "lua", "luadoc", "luap" }, lsp = { "lua_ls" }, fmt = { "stylua" }, mason = { "stylua" }, harper = true },
  vim = { ft = { "vim" }, ts = { "vim", "vimdoc" }, lsp = { "vimls" } },
  sh = { ft = { "sh", "bash", "zsh" }, ts = { "bash", "zsh" }, lsp = { "bashls" }, fmt = { sh = { "shfmt" }, bash = { "shfmt" } },
    mason = { "shfmt", "shellcheck" }, harper = { "sh" } },
  fish = { ft = { "fish" }, ts = { "fish" }, lsp = { "fish_lsp" }, fmt = { "fish_indent" },
    system = { fish = { name = "fish", brew = { "fish" }, size = "about 20 MB" } } },
  nushell = { ft = { "nu" }, ts = { "nu" }, lsp = { "nushell" },
    system = { nu = { name = "nushell", brew = { "nushell" }, size = "about 60 MB" } } },
  powershell = { ft = { "ps1" }, ts = { "powershell" }, lsp = { "powershell_es" },
    runtime = { name = "PowerShell", check = { "pwsh", "-Version" }, brew = { "powershell" }, size = "about 900 MB" } },
  perl = { ft = { "perl" }, ts = { "perl" }, lsp = { "perlnavigator" } },
  awk = { ft = { "awk" }, ts = { "awk" }, lsp = { "awk_ls" } },
  jq = { ft = { "jq" }, ts = { "jq" } },

  -- Systems ----------------------------------------------------------------
  c = { ft = { "c", "cpp", "objc", "objcpp", "cuda" }, ts = { "c", "cpp", "cuda", "objc" }, lsp = { "clangd" },
    fmt = { "clang_format" }, mason = { "clang-format" }, harper = { "c", "cpp" } },
  rust = { ft = { "rust" }, ts = { "rust", "ron" }, managed = "rustaceanvim", mason = { "rust-analyzer", "codelldb" }, harper = true,
    runtime = { name = "Rust", check = { "cargo", "--version" }, brew = { "rustup" },
      after = { { "rustup", "default", "stable" } }, size = "about 1.5 GB" } },
  go = { ft = { "go", "gomod", "gowork", "gotmpl" }, ts = { "go", "gomod", "gowork", "gosum", "gotmpl" }, lsp = { "gopls" },
    fmt = { go = { "goimports", "gofumpt" } }, lint = { go = { "golangcilint" } },
    mason = { "goimports", "gofumpt", "gomodifytags", "impl", "golangci-lint", "delve" }, harper = { "go" },
    runtime = { name = "Go", check = { "go", "version" }, brew = { "go" }, size = "about 250 MB" } },
  zig = { ft = { "zig" }, ts = { "zig" }, lsp = { "zls" }, harper = true,
    runtime = { name = "Zig", check = { "zig", "version" }, brew = { "zig" }, size = "about 2 GB" } },
  swift = { ft = { "swift" }, ts = { "swift" }, lsp = { "sourcekit" }, harper = true,
    system = { ["sourcekit-lsp"] = xcode } },
  fortran = { ft = { "fortran" }, ts = { "fortran" }, lsp = { "fortls" } },
  asm = { ft = { "asm", "nasm" }, ts = { "asm", "nasm" }, lsp = { "asm_lsp" } },
  llvm = { ft = { "llvm" }, ts = { "llvm" } },
  mlir = { ft = { "mlir" }, ts = { "mlir" }, lsp = { "mlir_lsp_server" }, system = { ["mlir-lsp-server"] = llvm } },
  tablegen = { ft = { "tablegen" }, ts = { "tablegen" }, lsp = { "tblgen_lsp_server" },
    system = { ["tblgen-lsp-server"] = llvm } },
  linker = { ft = { "ld" }, ts = { "linkerscript" } },
  devicetree = { ft = { "dts" }, ts = { "devicetree" } },
  kconfig = { ft = { "kconfig" }, ts = { "kconfig" } },

  -- Hardware description --------------------------------------------------
  systemverilog = { ft = { "verilog", "systemverilog" }, ts = { "systemverilog" }, lsp = { "verible" },
    fmt = { "verible" }, mason = { "verible" } },
  vhdl = { ft = { "vhdl" }, ts = { "vhdl" }, lsp = { "vhdl_ls" } },
  veryl = { ft = { "veryl" }, ts = { "veryl" }, lsp = { "veryl_ls" } },
  bsv = { ft = { "bsv" }, ts = { "bsv" } },
  firrtl = { ft = { "firrtl" }, ts = { "firrtl" } },
  tcl = { ft = { "tcl", "sdc", "xdc" }, ts = { "tcl" }, lsp = { "tclsp" }, lint = { "tclint" } },

  -- Build systems ------------------------------------------------------------
  cmake = { ft = { "cmake" }, ts = { "cmake" }, lsp = { "neocmake" }, fmt = { "cmake_format" }, lint = { "cmakelint" },
    mason = { "cmakelang", "cmakelint" }, harper = true },
  make = { ft = { "make", "automake" }, ts = { "make" }, lsp = { "autotools_ls" } },
  meson = { ft = { "meson" }, ts = { "meson" }, lsp = { "mesonlsp" } },
  ninja = { ft = { "ninja" }, ts = { "ninja" } },
  just = { ft = { "just" }, ts = { "just" }, lsp = { "just" } },
  starlark = { ft = { "bzl", "starlark" }, ts = { "starlark" }, lsp = { "starpls" }, fmt = { "buildifier" }, mason = { "buildifier" } },

  -- Python, JVM, .NET ---------------------------------------------------------
  python = { ft = { "python" }, ts = { "python", "rst", "requirements" }, lsp = { "basedpyright", "ruff" },
    fmt = { "ruff_format" }, mason = { "debugpy" }, harper = true },
  java = { ft = { "java" }, ts = { "java" }, managed = "nvim-jdtls", mason = { "jdtls", "java-debug-adapter", "java-test" }, harper = true, runtime = java },
  kotlin = { ft = { "kotlin" }, ts = { "kotlin" }, lsp = { "kotlin_language_server" }, fmt = { "ktlint" }, lint = { "ktlint" },
    mason = { "ktlint", "kotlin-debug-adapter" }, harper = true, runtime = java },
  scala = { ft = { "scala", "sbt" }, ts = { "scala" }, managed = "nvim-metals", harper = { "scala" },
    runtime = { name = "Coursier", check = { "coursier", "list" }, brew = { "coursier", "openjdk@21" },
      size = "about 700 MB" } },
  groovy = { ft = { "groovy" }, ts = { "groovy" }, lsp = { "groovyls" }, harper = true, runtime = java },
  clojure = { ft = { "clojure", "edn" }, ts = { "clojure" }, lsp = { "clojure_lsp" }, harper = { "clojure" } },
  dotnet = { ft = { "cs", "fsharp" }, ts = { "c_sharp", "fsharp" }, lsp = { "csharp_ls", "fsautocomplete" },
    fmt = { cs = { "csharpier" }, fsharp = { "fantomas" } }, mason = { "csharpier", "fantomas", "netcoredbg" }, harper = { "cs" },
    runtime = { name = ".NET SDK", check = { "dotnet", "--version" }, brew = { "dotnet" }, size = "about 800 MB" } },

  -- Functional ------------------------------------------------------------------
  haskell = { ft = { "haskell", "lhaskell", "cabal" }, ts = { "haskell" }, managed = "haskell-tools.nvim",
    fmt = { haskell = { "fourmolu" }, cabal = { "cabal_fmt" } }, lint = { haskell = { "hlint" } },
    mason = { "haskell-language-server", "fourmolu", "hlint" }, harper = { "haskell", "lhaskell" },
    runtime = { name = "GHC", check = { "ghc", "--version" }, brew = { "ghcup" },
      after = { { "ghcup", "install", "ghc", "--set", "recommended" } }, size = "about 3 GB" } },
  ocaml = { ft = { "ocaml", "ocamlinterface" }, ts = { "ocaml", "ocaml_interface" }, lsp = { "ocamllsp" }, fmt = { "ocamlformat" },
    mason = { "ocamlformat" }, runtime = { name = "OCaml", check = { "ocaml", "-version" }, brew = { "opam" },
      after = { { "opam", "init", "-n", "-y" } }, size = "about 600 MB" } },
  elixir = { ft = { "elixir", "eelixir", "heex" }, ts = { "elixir", "heex", "eex" }, lsp = { "elixirls" }, harper = { "elixir" },
    runtime = { name = "Elixir", check = { "elixir", "--version" }, brew = { "elixir" }, size = "about 400 MB" } },
  erlang = { ft = { "erlang" }, ts = { "erlang" }, lsp = { "elp" },
    runtime = { name = "Erlang", check = { "erl", "-version" }, brew = { "erlang" }, size = "about 350 MB" } },
  gleam = { ft = { "gleam" }, ts = { "gleam" }, lsp = { "gleam" }, fmt = { "gleam" }, harper = true,
    system = { gleam = { name = "Gleam", brew = { "gleam" }, size = "about 400 MB" } } },
  elm = { ft = { "elm" }, ts = { "elm" }, lsp = { "elmls" }, fmt = { "elm_format" }, mason = { "elm-format" } },
  lean = { ft = { "lean" }, managed = "lean.nvim",
    runtime = { name = "elan", check = { "elan", "--version" }, brew = { "elan-init" },
      after = { { "elan", "default", "stable" } }, size = "about 1.5 GB" } },
  julia = { ft = { "julia" }, ts = { "julia" }, lsp = { "julials" },
    runtime = { name = "Julia", check = { "julia", "--version" }, brew = { "julia" }, size = "about 1.5 GB" } },
  r = { ft = { "r", "rmd", "quarto", "rnoweb" }, ts = { "r", "rnoweb", "markdown" }, lsp = { "r_language_server" }, harper = { "quarto" },
    runtime = { name = "R", check = { "R", "--version" }, brew = { "r" }, size = "about 1.5 GB" } },
  nix = { ft = { "nix" }, ts = { "nix" }, lsp = { "nil_ls" }, fmt = { "nixfmt" }, lint = { "statix" }, mason = { "nixfmt", "statix" }, harper = true },

  -- Web --------------------------------------------------------------------------
  typescript = { ft = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    ts = { "javascript", "jsdoc", "typescript", "tsx" }, lsp = { "vtsls", "eslint", "tailwindcss" }, fmt = { "prettier" },
    mason = { "prettier", "js-debug-adapter" }, harper = { "javascript", "javascriptreact", "typescript", "typescriptreact" } },
  html = { ft = { "html" }, ts = { "html" }, lsp = { "html", "emmet_language_server", "tailwindcss" }, fmt = { "prettier" },
    mason = { "prettier" }, harper = true },
  css = { ft = { "css", "scss", "less" }, ts = { "css", "scss" }, lsp = { "cssls", "tailwindcss" }, fmt = { "prettier" }, mason = { "prettier" } },
  vue = { ft = { "vue" }, ts = { "vue" }, lsp = { "vue_ls", "vtsls", "tailwindcss" }, fmt = { "prettier" }, mason = { "prettier" } },
  svelte = { ft = { "svelte" }, ts = { "svelte" }, lsp = { "svelte", "tailwindcss" } },
  astro = { ft = { "astro" }, ts = { "astro" }, lsp = { "astro", "tailwindcss" } },
  angular = { ft = { "htmlangular" }, ts = { "angular" }, lsp = { "angularls", "tailwindcss" }, fmt = { "prettier" }, mason = { "prettier" } },
  ember = { ft = { "handlebars", "javascript.glimmer", "typescript.glimmer" }, ts = { "glimmer", "glimmer_javascript", "glimmer_typescript" },
    lsp = { "ember" }, fmt = { "prettier" }, mason = { "prettier" } },
  graphql = { ft = { "graphql" }, ts = { "graphql" }, lsp = { "graphql" }, fmt = { "prettier" }, mason = { "prettier" } },
  php = { ft = { "php" }, ts = { "php", "phpdoc" }, lsp = { "intelephense" }, fmt = { "php_cs_fixer" }, lint = { "phpcs" },
    mason = { "php-cs-fixer", "phpcs", "php-debug-adapter" }, harper = true,
    runtime = { name = "PHP", check = { "php", "--version" }, brew = { "php" }, size = "about 500 MB" } },
  twig = { ft = { "twig" }, ts = { "twig" }, lsp = { "twiggy_language_server" } },
  ruby = { ft = { "ruby", "eruby" }, ts = { "ruby", "embedded_template" }, lsp = { "ruby_lsp", "rubocop" },
    fmt = { ruby = { "rubocop" }, eruby = { "erb_format" } }, mason = { "erb-formatter" }, harper = { "ruby" },
    runtime = { name = "Ruby 3", check = { "ruby", "-e", "exit(RUBY_VERSION >= '3.0' ? 0 : 1)" }, brew = { "ruby" },
      size = "about 100 MB" } },
  dart = { ft = { "dart" }, ts = { "dart" }, lsp = { "dartls" }, fmt = { "dart_format" }, harper = true,
    system = { dart = { name = "the Dart SDK", brew = { "dart-sdk" }, size = "about 600 MB" } } },
  prisma = { ft = { "prisma" }, ts = { "prisma" }, lsp = { "prismals" } },
  solidity = { ft = { "solidity" }, ts = { "solidity" }, lsp = { "solidity_ls" }, harper = true },

  -- Data, config and infrastructure -----------------------------------------------
  json = { ft = { "json", "jsonc", "json5" }, ts = { "json", "json5" }, lsp = { "jsonls" }, fmt = { "prettier" }, mason = { "prettier" } },
  yaml = { ft = { "yaml" }, ts = { "yaml" }, lsp = { "yamlls" }, fmt = { "prettier" }, mason = { "prettier" } },
  toml = { ft = { "toml" }, ts = { "toml" }, lsp = { "taplo" }, fmt = { "taplo" }, harper = true },
  xml = { ft = { "xml", "xsd", "xslt", "svg" }, ts = { "xml" }, lsp = { "lemminx" } },
  ini = { ft = { "dosini", "editorconfig" }, ts = { "ini", "editorconfig" } },
  csv = { ft = { "csv", "tsv" }, ts = { "csv", "tsv" } },
  sql = { ft = { "sql", "mysql", "plsql" }, ts = { "sql" }, fmt = { "sqlfluff" }, lint = { "sqlfluff" }, mason = { "sqlfluff" } },
  proto = { ft = { "proto" }, ts = { "proto" }, lsp = { "buf_ls" }, fmt = { "buf" } },
  thrift = { ft = { "thrift" }, ts = { "thrift" }, lsp = { "thriftls" } },
  docker = { ft = { "dockerfile", "yaml.docker-compose" }, ts = { "dockerfile", "yaml" }, lsp = { "dockerls", "docker_compose_language_service" },
    lint = { dockerfile = { "hadolint" } }, mason = { "hadolint" } },
  terraform = { ft = { "terraform", "terraform-vars", "hcl" }, ts = { "terraform", "hcl" }, lsp = { "terraformls" },
    lint = { terraform = { "tflint" } }, mason = { "tflint" } },
  helm = { ft = { "helm" }, ts = { "helm" }, lsp = { "helm_ls" } },
  ansible = { ft = { "yaml.ansible" }, ts = { "yaml" }, lsp = { "ansiblels" }, mason = { "ansible-lint" } },
  rego = { ft = { "rego" }, ts = { "rego" }, lsp = { "regols", "regal" } },
  dot = { ft = { "dot" }, ts = { "dot" }, lsp = { "dotls" } },
  git = { ft = { "gitcommit", "gitconfig", "gitrebase", "gitignore", "gitattributes" },
    ts = { "git_config", "gitcommit", "git_rebase", "gitignore", "gitattributes" }, harper = { "gitcommit" } },

  -- Shaders ------------------------------------------------------------------------
  glsl = { ft = { "glsl" }, ts = { "glsl" }, lsp = { "glsl_analyzer" } },
  hlsl = { ft = { "hlsl" }, ts = { "hlsl" }, lsp = { "slangd" } },
  wgsl = { ft = { "wgsl" }, ts = { "wgsl" }, lsp = { "wgsl_analyzer" } },

  -- Prose ------------------------------------------------------------------------
  markdown = { ft = { "markdown", "markdown.mdx" }, ts = { "markdown", "markdown_inline" }, lsp = { "marksman" },
    fmt = { "prettier", "markdownlint-cli2" }, lint = { "markdownlint-cli2" }, mason = { "prettier", "markdownlint-cli2" },
    harper = { "markdown" }, manual = true },
  tex = { ft = { "tex", "plaintex", "bib" }, ts = { "latex", "bibtex" }, lsp = { "texlab" }, harper = { "tex", "plaintex" }, manual = true },
  typst = { ft = { "typst" }, ts = { "typst" }, lsp = { "tinymist" }, fmt = { "typstyle" }, mason = { "typstyle" }, harper = true, manual = true },
  text = { ft = { "text" }, harper = true, manual = true },
}

return M
```

Some lines run past 120 columns. stylua leaves a table constructor on one line only when it fits, so run `stylua lua/ach/languages.lua` once and commit what it produces; the content is what matters, not the layout above.

- [ ] **Write the engine**

`lua/ach/lang.lua`:

```lua
-- The language engine: turns lua/ach/languages.lua into the shape each plugin
-- takes. Every function is pure, so tests/test_lang.lua checks them with no
-- plugin loaded.
local L = require("ach.languages")
local M = {}

local entries, by_name, by_ft = {}, {}, {}
for name, entry in pairs(L.languages) do
  local e = vim.deepcopy(entry)
  e.name = name
  by_name[name] = e
  entries[#entries + 1] = e
  for _, ft in ipairs(e.ft) do
    by_ft[ft] = e
  end
end
table.sort(entries, function(a, b)
  return a.name < b.name
end)

-- A field that is either one list for every file type or a map from file type to list.
local function for_this_ft(value, ft)
  if value == nil then
    return {}
  end
  if vim.islist(value) then
    return value
  end
  return value[ft] or {}
end

local function harper_on(e, ft)
  local h = e.harper
  return h == true or (type(h) == "table" and vim.tbl_contains(h, ft))
end

local function sorted_unique(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out)
  return out
end

function M.entries()
  return entries
end

function M.get(name)
  return by_name[name]
end

function M.for_ft(ft)
  return by_ft[ft]
end

function M.parsers_for_ft(ft)
  local e = by_ft[ft]
  return e and e.ts or {}
end

function M.servers_for_ft(ft)
  local e = by_ft[ft]
  if not e then
    return {}
  end
  local out = vim.list_extend({}, e.lsp or {})
  if harper_on(e, ft) then
    out[#out + 1] = L.grammar.server
  end
  return out
end

function M.servers()
  local all = { L.grammar.server }
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.lsp or {})
  end
  return sorted_unique(all)
end

local function by_filetype(field)
  local out = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      local list = for_this_ft(e[field], ft)
      if #list > 0 then
        out[ft] = vim.deepcopy(list)
      end
    end
  end
  return out
end

function M.formatters_by_ft()
  return by_filetype("fmt")
end

function M.linters_by_ft()
  return by_filetype("lint")
end

function M.packages_for_ft(ft, server_to_package)
  local e = by_ft[ft]
  if not e then
    return {}
  end
  local out = {}
  for _, server in ipairs(e.lsp or {}) do
    out[#out + 1] = server_to_package[server]
  end
  vim.list_extend(out, e.mason or {})
  if harper_on(e, ft) then
    out[#out + 1] = L.grammar.package
  end
  return sorted_unique(out)
end

function M.harper_filetypes()
  local out = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      if harper_on(e, ft) then
        out[#out + 1] = ft
      end
    end
  end
  table.sort(out)
  return out
end

function M.is_harper_ft(ft)
  local e = by_ft[ft]
  return e ~= nil and harper_on(e, ft)
end

function M.manual_filetypes()
  local out = {}
  for _, e in ipairs(entries) do
    if e.manual then
      vim.list_extend(out, e.ft)
    end
  end
  table.sort(out)
  return out
end

function M.is_manual(ft)
  local e = by_ft[ft]
  return e ~= nil and e.manual == true
end

function M.runtime_for_ft(ft)
  local e = by_ft[ft]
  return e and e.runtime or nil
end

-- The one line that installs a requirement, as the owner would type it.
function M.command(req)
  if req.command then
    return req.command
  end
  local parts = { "brew install " .. table.concat(req.brew, " ") }
  for _, argv in ipairs(req.after or {}) do
    parts[#parts + 1] = table.concat(argv, " ")
  end
  return table.concat(parts, " && ")
end

-- The commands the editor runs to install a requirement, each once the one
-- before has succeeded, or none when the command can only be shown.
function M.steps(req)
  if not req.brew then
    return {}
  end
  local steps = { vim.list_extend({ "brew", "install" }, req.brew) }
  for _, argv in ipairs(req.after or {}) do
    steps[#steps + 1] = vim.deepcopy(argv)
  end
  return steps
end

-- Each outside program the file type needs, mapped to the command that installs it.
function M.system_for_ft(ft)
  local e = by_ft[ft]
  local out = {}
  for program, req in pairs(e and e.system or {}) do
    out[program] = M.command(req)
  end
  return out
end

-- Every Homebrew formula the editor may offer to install. scripts/on-demand
-- prints this list.
function M.formulae()
  local all = {}
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.runtime and e.runtime.brew or {})
    for _, req in pairs(e.system or {}) do
      vim.list_extend(all, req.brew or {})
    end
  end
  return sorted_unique(all)
end

function M.managed_for_ft(ft)
  local e = by_ft[ft]
  return e and e.managed or nil
end

function M.custom_parsers()
  return L.parsers
end

function M.all_parsers()
  local all = {}
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.ts or {})
  end
  return sorted_unique(all)
end

-- Every Mason package any file type can ask for. Each file type is asked
-- separately, since Harper checks some of an entry's file types and not others.
function M.all_packages(server_to_package)
  local all = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      vim.list_extend(all, M.packages_for_ft(ft, server_to_package))
    end
  end
  return sorted_unique(all)
end

return M
```

- [ ] **Write the on-demand list**

A Mac's setup script wants to know every formula this editor might offer to install, without installing any of them and without starting the editor. `nvim -l` runs one Lua file with Neovim's standard library and nothing else, and `--clean` makes sure no configuration is read on the way. The Lua file puts the repository's `lua` folder on Lua's search path, so `require("ach.lang")` finds the table, and prints the list.

`scripts/on-demand` (make it executable with `chmod +x scripts/on-demand`):

```bash
#!/usr/bin/env bash
# Print every Homebrew formula the editor may offer to install, one per line,
# sorted, each once. Reads lua/ach/languages.lua; starts no configuration.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
exec nvim --clean -l "$root/scripts/on_demand.lua" "$root"
```

`scripts/on_demand.lua`:

```lua
-- Prints require("ach.lang").formulae(), one per line.
-- Usage: nvim --clean -l scripts/on_demand.lua ROOT, where ROOT is the repository.
package.path = arg[1] .. "/lua/?.lua;" .. package.path
for _, formula in ipairs(require("ach.lang").formulae()) do
  io.write(formula, "\n")
end
```

Run: `chmod +x scripts/on-demand && scripts/on-demand | head -n 3`
Expected: `coursier`, `dart-sdk` and `dotnet`, one per line.

- [ ] **Format the Lua**

Run: `stylua lua/ach/languages.lua lua/ach/lang.lua scripts/on_demand.lua`
Expected: no output, exit 0.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 18 `test_lang` tests pass, along with every earlier test. Exit 0.

- [ ] **Commit**

```bash
git add lua/ach/languages.lua lua/ach/lang.lua tests/test_lang.lua scripts/on-demand scripts/on_demand.lua
git commit --only lua/ach/languages.lua lua/ach/lang.lua tests/test_lang.lua scripts/on-demand scripts/on_demand.lua -m "feat(lang): add the language table, the engine that reads it and the on-demand formula list"
```

---

### Task: File types and sample files

**Files:**
- Create: `lua/ach/filetypes.lua`, `tests/fixtures/samples.lua`
- Modify: `lua/ach/init.lua` (replace the whole file)
- Test: `tests/test_filetypes.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` from the language-table task (`entries()`, `get(name)`); `require("mini.icons").get(category, name)` from the foundation, which returns the glyph, its highlight and whether the glyph is mini.icons' default.
- Produces:
  - `require("ach.filetypes")`: `extensions: table<ext, ft>`, `parsers: table<parser, ft[]>`, `patterns: table<lua pattern, ft | fun(path): ft|nil>`, and `setup()`, which adds the three to Neovim. `init.lua` calls `setup()` before lazy.nvim starts, so the first file opened from the command line is already recognised.
  - `tests/fixtures/samples.lua`, loaded with `dofile(t.root .. "/tests/fixtures/samples.lua")`: `samples: table<entry name, { open: string, text: string, extra?: table<path, string> }>` and `write(dir, name): string`, which writes the sample and its extra files under `dir` and returns the full path of the file to open. Every sample whose language has a formatter carries at least one line that formatter changes, and every sample whose language has a linter carries a warning that linter reports. The tree-sitter, formatting, linting and full-mode tasks open these files.

- [ ] **Write the failing tests**

`tests/test_filetypes.lua`:

```lua
-- File types. Neovim must recognise every language's sample, the file types it
-- cannot detect by itself are added, a parser that serves several file types
-- is registered for each, and every file type in the table has an icon of its
-- own rather than mini.icons' default.

local function samples(t)
  return dofile(t.root .. "/tests/fixtures/samples.lua")
end

-- Opens a file in a new buffer, returns the file type Neovim gave it, then
-- wipes the buffer so the next sample starts clean.
local function detect(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local ft = vim.bo.filetype
  vim.cmd("bwipeout!")
  return ft
end

return {
  ["every language has a sample, and every sample a language"] = function(t)
    local lang = require("ach.lang")
    local s = samples(t)
    local missing, extra = {}, {}
    for _, e in ipairs(lang.entries()) do
      if not s.samples[e.name] then
        missing[#missing + 1] = e.name
      end
    end
    for name in pairs(s.samples) do
      if not lang.get(name) then
        extra[#extra + 1] = name
      end
    end
    table.sort(missing)
    table.sort(extra)
    t.eq(missing, {}, "languages with no sample")
    t.eq(extra, {}, "samples with no language")
  end,

  ["each sample opens with a file type of its language"] = function(t)
    local lang = require("ach.lang")
    local s = samples(t)
    local wrong = {}
    for _, e in ipairs(lang.entries()) do
      if s.samples[e.name] then
        local ft = detect(s.write(t.tmpdir(), e.name))
        if not vim.tbl_contains(e.ft, ft) then
          wrong[#wrong + 1] = ("%s opened as %q"):format(e.name, ft)
        end
      end
    end
    t.eq(wrong, {}, "samples Neovim did not recognise")
  end,

  ["the file types Neovim lacks are added"] = function(t)
    local want = {
      ["a.bsv"] = "bsv",
      ["a.hlsl"] = "hlsl",
      ["a.hlsli"] = "hlsl",
      ["a.mdx"] = "markdown.mdx",
      ["a.mli"] = "ocamlinterface",
      ["a.veryl"] = "veryl",
      ["a.xdc"] = "xdc",
    }
    local got = {}
    for name in pairs(want) do
      got[name] = vim.filetype.match({ filename = "/work/" .. name })
    end
    t.eq(got, want)
  end,

  ["Helm templates, Ansible playbooks and compose files are recognised by name and place"] = function(t)
    local dir = t.tmpdir()
    vim.fn.mkdir(dir .. "/chart/templates", "p")
    vim.fn.writefile({ "apiVersion: v2", "name: sample", "version: 0.1.0" }, dir .. "/chart/Chart.yaml")
    t.eq(vim.filetype.match({ filename = dir .. "/chart/templates/service.yaml" }), "helm", "a template inside a chart")
    t.eq(vim.filetype.match({ filename = dir .. "/site/templates/page.yaml" }), "yaml", "a templates folder with no Chart.yaml")
    t.eq(vim.filetype.match({ filename = dir .. "/infra/playbooks/site.yml" }), "yaml.ansible", "a playbook")
    t.eq(vim.filetype.match({ filename = dir .. "/infra/roles/web/tasks/main.yml" }), "yaml.ansible", "a role's tasks")
    t.eq(vim.filetype.match({ filename = dir .. "/app/docker-compose.yml" }), "yaml.docker-compose", "a docker-compose file")
    t.eq(vim.filetype.match({ filename = dir .. "/app/compose.yaml" }), "yaml.docker-compose", "a compose file")
    t.eq(vim.filetype.match({ filename = dir .. "/app/settings.yaml" }), "yaml", "any other YAML file")
  end,

  ["a parser that serves several file types is registered for each"] = function(t)
    local want = {
      edn = "clojure",
      mysql = "sql",
      objcpp = "objc",
      plaintex = "latex",
      plsql = "sql",
      quarto = "markdown",
      rmd = "markdown",
      sdc = "tcl",
      xdc = "tcl",
    }
    local got = {}
    for ft in pairs(want) do
      got[ft] = vim.treesitter.language.get_lang(ft)
    end
    t.eq(got, want)
  end,

  ["every file type in the table has an icon of its own"] = function(t)
    local icons = require("mini.icons")
    local plain = {}
    for _, e in ipairs(require("ach.lang").entries()) do
      for _, ft in ipairs(e.ft) do
        local _, _, is_default = icons.get("filetype", ft)
        if is_default then
          plain[#plain + 1] = ft
        end
      end
    end
    table.sort(plain)
    t.eq(plain, {}, "file types drawn with mini.icons' default icon")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_filetypes`
Expected: `1 passed, 5 failed, 0 need a person, 0 skipped`, exit 1. The icon test passes already, because the foundation's icon database covers every file type in the table. The other five fail: the first two because `tests/fixtures/samples.lua` does not exist, and the last three because `.bsv` and the others come back as `nil`, the Helm template and the compose files as `yaml`, and `get_lang("sdc")` as `sdc`.

- [ ] **Write the file-type module**

`lua/ach/filetypes.lua`:

```lua
-- File types Neovim 0.12 does not detect by itself, and parsers that serve
-- more than one file type. init.lua calls setup() before lazy.nvim starts, so
-- a file named on the command line is recognised when it first opens.
local M = {}

-- Extensions Neovim has no rule for. A .mli file is an OCaml interface, which
-- has its own parser; Neovim calls it plain ocaml.
M.extensions = {
  bsv = "bsv",
  hlsl = "hlsl",
  hlsli = "hlsl",
  mdx = "markdown.mdx",
  mli = "ocamlinterface",
  veryl = "veryl",
  xdc = "xdc",
}

-- File types that borrow another language's parser.
M.parsers = {
  clojure = { "edn" },
  latex = { "plaintex" },
  markdown = { "rmd", "quarto" },
  objc = { "objcpp" },
  sql = { "mysql", "plsql" },
  tcl = { "sdc", "xdc" },
}

-- A YAML file under templates/ is a Helm template only inside a chart, which
-- is a folder holding Chart.yaml. Returning nil lets Neovim carry on and call
-- it plain YAML.
local function helm(path)
  return vim.fs.root(path, "Chart.yaml") and "helm" or nil
end

-- Patterns run before Neovim's extension rules, so these win over plain YAML.
M.patterns = {
  [".*/templates/.*%.ya?ml"] = helm,
  [".*/templates/.*%.tpl"] = helm,
  [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
  [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
  [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
  [".*/group_vars/.*%.ya?ml"] = "yaml.ansible",
  [".*/host_vars/.*%.ya?ml"] = "yaml.ansible",
}

-- Compose files are plain YAML to Neovim, and the compose server attaches only
-- to this file type.
M.filenames = {
  ["compose.yaml"] = "yaml.docker-compose",
  ["compose.yml"] = "yaml.docker-compose",
  ["docker-compose.yaml"] = "yaml.docker-compose",
  ["docker-compose.yml"] = "yaml.docker-compose",
}

function M.setup()
  vim.filetype.add({ extension = M.extensions, filename = M.filenames, pattern = M.patterns })
  for parser, fts in pairs(M.parsers) do
    vim.treesitter.language.register(parser, fts)
  end
end

return M
```

- [ ] **Call it from the start-up sequence**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added before lazy.nvim
-- starts, so a file named on the command line is recognised when it opens.
-- Keymaps wait for VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

- [ ] **Write the samples**

Each sample is the smallest file that shows its language working. Where the language has a formatter, one line is deliberately misformatted, and the comment above the sample says which. Where it has a linter, the sample plants one warning that linter reports, also named in the comment. The full-mode test relies on both.

`tests/fixtures/samples.lua`:

```lua
-- One sample file per entry in lua/ach/languages.lua, keyed by entry name.
-- open is the path of the file to open, text is its content, and extra holds
-- any other files the language needs beside it, such as go.mod. Where the
-- language has a formatter, one line is misformatted on purpose; where it has
-- a linter, one warning is planted. The comment above each sample names both.
local M = {}

M.samples = {
  -- Editor and shell -------------------------------------------------------
  -- stylua: the spacing around "=".
  lua = { open = "sample.lua", text = [[
local x   =  1
return x
]] },
  vim = { open = "sample.vim", text = [[
let g:sample = 1
]] },
  -- shfmt: the unindented echo.
  sh = { open = "sample.sh", text = [[
#!/usr/bin/env bash
if [ -n "$1" ]; then
echo "$1"
fi
]] },
  -- fish_indent: the unindented echo.
  fish = { open = "config.fish", text = [[
if true
echo hello
end
]] },
  nushell = { open = "sample.nu", text = [[
def main [] { print "hello" }
]] },
  powershell = { open = "sample.ps1", text = [[
Write-Output "hello"
]] },
  perl = { open = "sample.pl", text = [[
use strict;
print "hello\n";
]] },
  awk = { open = "sample.awk", text = [[
{ print $1 }
]] },
  jq = { open = "sample.jq", text = [[
.name
]] },

  -- Systems ----------------------------------------------------------------
  -- clang-format: the whole function on one line.
  c = { open = "sample.c", text = [[
int main(void){return 0;}
]] },
  rust = {
    open = "src/main.rs",
    text = [[
fn main() {
    println!("hello");
}
]],
    extra = { ["Cargo.toml"] = '[package]\nname = "sample"\nversion = "0.1.0"\nedition = "2021"\n' },
  },
  -- gofumpt: the unindented call. golangci-lint: os.Remove's error is never checked.
  go = {
    open = "main.go",
    text = [[
package main

import "os"

func main() {
os.Remove("sample.tmp")
}
]],
    extra = { ["go.mod"] = "module example.com/sample\n\ngo 1.22\n" },
  },
  zig = { open = "main.zig", text = [[
pub fn main() void {}
]] },
  swift = { open = "main.swift", text = [[
print("hello")
]] },
  fortran = { open = "sample.f90", text = [[
program sample
  print *, "hello"
end program sample
]] },
  asm = { open = "sample.s", text = [[
.text
.globl main
main:
  ret
]] },
  llvm = { open = "sample.ll", text = [[
; ModuleID = 'sample'
define i32 @main() {
  ret i32 0
}
]] },
  mlir = { open = "sample.mlir", text = [[
func.func @main() {
  return
}
]] },
  tablegen = { open = "sample.td", text = [[
class Sample<int n> {
  int value = n;
}
]] },
  linker = { open = "sample.ld", text = [[
SECTIONS
{
  .text : { *(.text) }
}
]] },
  devicetree = { open = "sample.dts", text = [[
/dts-v1/;
/ {
  model = "sample";
};
]] },
  kconfig = { open = "Kconfig", text = [[
config SAMPLE
	bool "Sample option"
]] },

  -- Hardware description --------------------------------------------------
  -- verible: the whole module on one line.
  systemverilog = { open = "sample.sv", text = [[
module sample(input logic a,output logic y);assign y=a;endmodule
]] },
  vhdl = { open = "sample.vhd", text = [[
entity sample is
end entity sample;
]] },
  veryl = { open = "sample.veryl", text = [[
module Sample {
    var a: logic;
}
]] },
  bsv = { open = "Sample.bsv", text = [[
package Sample;
endpackage
]] },
  firrtl = { open = "sample.fir", text = [[
FIRRTL version 3.3.0
circuit Sample :
  module Sample :
    input a : UInt<1>
]] },
  -- tclint: an expression with substitutions that is not braced.
  tcl = { open = "sample.tcl", text = [[
set a 1
set b 2
set c [expr $a + $b]
]] },

  -- Build systems ------------------------------------------------------------
  -- cmake-format: the spaces inside add_executable. cmakelint: "Project" in mixed case.
  cmake = { open = "CMakeLists.txt", text = [[
cmake_minimum_required(VERSION 3.20)
Project(sample)
add_executable( sample   main.c )
]] },
  make = { open = "Makefile", text = "all:\n\techo hello\n" },
  meson = { open = "meson.build", text = [[
project('sample', 'c')
]] },
  ninja = { open = "build.ninja", text = [[
rule cc
  command = cc -c $in -o $out
]] },
  just = { open = "justfile", text = [[
default:
    echo hello
]] },
  -- buildifier: the call on one line, with no spaces around "=".
  starlark = { open = "BUILD", text = [[
cc_binary(name="sample",srcs=["main.c"])
]] },

  -- Python, JVM, .NET ---------------------------------------------------------
  -- ruff: the spacing and quotes in the dictionary.
  python = { open = "sample.py", text = [[
import os

x = {  'a':1 }
print(os.name, x)
]] },
  java = { open = "Sample.java", text = [[
public class Sample {
    public static void main(String[] args) {
    }
}
]] },
  -- ktlint: the trailing semicolon, both as a lint warning and as the format fix.
  kotlin = { open = "sample.kt", text = [[
fun main() {
    val x = 1;
    println(x)
}
]] },
  scala = { open = "Sample.scala", text = [[
object Sample {
  def main(args: Array[String]): Unit = println("hello")
}
]] },
  groovy = { open = "sample.groovy", text = [[
println "hello"
]] },
  clojure = { open = "sample.clj", text = [[
(ns sample)
(defn f [x] x)
]] },
  -- csharpier: the class on one line.
  dotnet = { open = "Sample.cs", text = [[
class Sample{static void Main(){}}
]] },

  -- Functional ------------------------------------------------------------------
  -- fourmolu: the spacing around "=" in main. hlint: a redundant if.
  haskell = { open = "Main.hs", text = [[
module Main where

f :: Bool -> Bool
f x = if x then True else False

main :: IO ()
main  =  print (f True)
]] },
  -- ocamlformat, which formats only inside a project with .ocamlformat: the spacing around "=".
  ocaml = {
    open = "sample.ml",
    text = [[
let x  =  1
]],
    extra = { [".ocamlformat"] = "profile = default\n" },
  },
  elixir = { open = "sample.ex", text = [[
defmodule Sample do
end
]] },
  erlang = { open = "sample.erl", text = [[
-module(sample).
]] },
  -- gleam format: the expression on one line with no spaces.
  gleam = { open = "sample.gleam", text = [[
pub fn main() {
1+1
}
]] },
  -- elm-format: the two-space indent, which it makes four.
  elm = { open = "Main.elm", text = [[
module Main exposing (main)

import Html

main =
  Html.text "hello"
]] },
  lean = { open = "Sample.lean", text = [[
def x : Nat := 1
]] },
  julia = { open = "sample.jl", text = [[
println("hello")
]] },
  -- The comment is what tells Neovim this is R rather than Rexx.
  r = { open = "sample.R", text = [[
# sample
x <- 1
]] },
  -- nixfmt: the whole expression on one line. statix: a = a, which inherit says better.
  nix = { open = "sample.nix", text = [[
let a = 1; in { a = a; }
]] },

  -- Web --------------------------------------------------------------------------
  -- prettier: the object's spacing and the missing semicolons.
  typescript = { open = "sample.ts", text = [[
const x = {a:1}
export default x
]] },
  -- prettier: the spaces between the attributes.
  html = { open = "sample.html", text = [[
<!doctype html>
<p   class="a">hello</p>
]] },
  -- prettier: the rule on one line.
  css = { open = "sample.css", text = [[
a{color:red}
]] },
  -- prettier: the single quotes and the missing semicolon.
  vue = { open = "Sample.vue", text = [[
<template><p>{{ msg }}</p></template>
<script setup>
const msg = 'hello'
</script>
]] },
  svelte = { open = "Sample.svelte", text = [[
<script>
  let name = "world";
</script>
<p>Hello {name}</p>
]] },
  astro = { open = "sample.astro", text = [[
---
const name = "world";
---
<p>Hello {name}</p>
]] },
  -- The *ngIf is what tells Neovim this is an Angular template. prettier: the
  -- spaces between the attributes.
  angular = { open = "app.component.html", text = [[
<div   *ngIf="shown"   class="a">hello</div>
]] },
  -- prettier: the spaces between the attributes.
  ember = { open = "sample.hbs", text = [[
<p   class="a">{{this.message}}</p>
]] },
  -- prettier: the type on one line.
  graphql = { open = "schema.graphql", text = [[
type Query{hello:String}
]] },
  -- php-cs-fixer: the spacing in the function. phpcs: no file doc comment.
  php = { open = "sample.php", text = [[
<?php

function  f( $x ){return $x;}
]] },
  twig = { open = "sample.html.twig", text = [[
<p>{{ name }}</p>
]] },
  -- rubocop: the spacing and the hash-rocket in the hash.
  ruby = { open = "sample.rb", text = [[
x = {  :a=>1 }
puts x
]] },
  -- dart format: the function on one line.
  dart = { open = "main.dart", text = [[
void main(){print('hello');}
]] },
  prisma = { open = "schema.prisma", text = [[
datasource db {
  provider = "sqlite"
  url      = "file:dev.db"
}
]] },
  solidity = { open = "Sample.sol", text = [[
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sample {}
]] },

  -- Data, config and infrastructure -----------------------------------------------
  -- prettier: the object on one line with no spaces.
  json = { open = "sample.json", text = [[
{"a":1}
]] },
  -- prettier: the spaces after the colon.
  yaml = { open = "sample.yaml", text = [[
a:   1
]] },
  -- taplo: the spacing around "=".
  toml = { open = "sample.toml", text = [[
a  =  1
]] },
  xml = { open = "sample.xml", text = [[
<?xml version="1.0"?>
<root/>
]] },
  ini = { open = "sample.ini", text = [[
[section]
key = value
]] },
  csv = { open = "sample.csv", text = [[
a,b
1,2
]] },
  -- sqlfluff, both as formatter and linter: the double space, and keywords in
  -- mixed case. There is deliberately no .sqlfluff beside it, because the
  -- configuration must name the dialect itself, as it must for any SQL file.
  sql = { open = "sample.sql", text = [[
SELECT a  from t
]] },
  -- buf format: the message on one line.
  proto = { open = "sample.proto", text = [[
syntax = "proto3";
message Sample{string name=1;}
]] },
  thrift = { open = "sample.thrift", text = [[
struct Sample {
  1: string name
}
]] },
  -- hadolint: an image pinned to "latest".
  docker = { open = "Dockerfile", text = [[
FROM ubuntu:latest
]] },
  -- tflint: a variable that is declared and never used.
  terraform = { open = "main.tf", text = [[
variable "unused" {}
]] },
  helm = {
    open = "chart/templates/configmap.yaml",
    text = [[
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}
]],
    extra = { ["chart/Chart.yaml"] = "apiVersion: v2\nname: sample\nversion: 0.1.0\n" },
  },
  ansible = { open = "playbooks/site.yml", text = [[
- hosts: all
  tasks:
    - name: Ping
      ansible.builtin.ping:
]] },
  rego = { open = "sample.rego", text = [[
package sample

allow := true
]] },
  dot = { open = "sample.dot", text = [[
digraph G { a -> b }
]] },
  -- Harper: the repeated "the".
  git = { open = "COMMIT_EDITMSG", text = [[
Add the sample

This is the the body.
]] },

  -- Shaders ------------------------------------------------------------------------
  glsl = { open = "sample.glsl", text = [[
#version 330 core
void main() {}
]] },
  hlsl = { open = "sample.hlsl", text = [[
float4 main() : SV_Target { return 0; }
]] },
  wgsl = { open = "sample.wgsl", text = [[
@fragment
fn main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0);
}
]] },

  -- Prose ------------------------------------------------------------------------
  -- prettier: the "*" bullet, which it makes "-". markdownlint: "#No space",
  -- a heading with no space after the hash.
  markdown = { open = "sample.md", text = [[
# Sample

#No space

* item
]] },
  tex = { open = "sample.tex", text = [[
\documentclass{article}
\begin{document}
Hello.
\end{document}
]] },
  -- typstyle: the spacing around "=".
  typst = { open = "sample.typ", text = [[
#let x  =  1
]] },
  -- Harper: the repeated "the".
  text = { open = "sample.txt", text = [[
This is the the sample.
]] },
}

-- Writes a sample and its extra files under dir and returns the full path of
-- the file to open. Folders in a path are created as needed.
function M.write(dir, name)
  local sample = assert(M.samples[name], "no sample for " .. name)
  local files = vim.tbl_extend("force", sample.extra or {}, { [sample.open] = sample.text })
  for path, text in pairs(files) do
    local full = dir .. "/" .. path
    vim.fn.mkdir(vim.fs.dirname(full), "p")
    local f = assert(io.open(full, "w"))
    f:write(text)
    f:close()
  end
  return dir .. "/" .. sample.open
end

return M
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 6 `test_filetypes` tests pass, along with every earlier test. Exit 0.

- [ ] **Commit**

```bash
git add lua/ach/filetypes.lua tests/fixtures/samples.lua tests/test_filetypes.lua
git commit --only lua/ach/filetypes.lua lua/ach/init.lua tests/fixtures/samples.lua tests/test_filetypes.lua -m "feat(lang): recognise every language's files and add a sample for each"
```

---

### Task: Tree-sitter parsers, highlighting and moves

**Files:**
- Create: `lua/ach/plugins/treesitter.lua`, `lua/ach/treesitter.lua`, `lua/ach/install.lua`, `tests/helpers/child.lua`
- Modify: `lua/ach/init.lua` (replace the whole file), `scripts/check` (one line), `lua/ach/icons.lua` (twelve lines in `M.keys`), `lazy-lock.json` (written by lazy.nvim)
- Test: `tests/test_treesitter.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` (`entries()`, `for_ft(ft)`, `custom_parsers()`, `all_parsers()`); `require("ach.filetypes").setup()`; `tests/fixtures/samples.lua` (`write(dir, name)`); `require("ach.icons").key(desc)`, which returns `{ icon, color }` or nil.
- Produces:
  - `require("ach.treesitter")`: `moves: { key, method, query, desc }[]`, `register_custom()`, which adds the table's own parsers to nvim-treesitter's list, `attach(buf)`, which starts highlighting, indentation and the moves when the parser and the matching query are present and does nothing otherwise, and `moves_for(buf)`. `attach` is safe to call any number of times.
  - `require("ach.install")`: `dry: boolean` (true under `ACH_DRY_INSTALL=1`), `requests: { parsers: string[], packages: string[], servers: string[] }` (what a dry run would have installed, each sorted and unique), `available_parsers(): table<string, true>`, `installed_parsers(): table<string, true>` (empty when dry, so a dry run records what a new Mac would install), `ensure_parsers(names: string[], done: fun())`, which calls `done` once every name is installed or has failed, `is_file(buf): boolean`, true only for a buffer with an empty `buftype`, a name and a readable file behind it, `injected_parsers(langs: string[]): string[]`, the parsers nvim-treesitter can install that the injection queries of `langs` name by a literal `injection.language`, sorted and leaving out `langs` themselves, `reset()`, which clears the requests and the session's failures, and `setup()`, which creates the `FileType` and `BufWritePost` hooks. The Mason task replaces this file and adds the package half.
  - `tests/helpers/child.lua`, loaded with `dofile`: `run(t, body: string, opts?: { env?, args?, cwd?, timeout? }): any`. It starts a second headless Neovim with this configuration and `ACH_TEST=1 ACH_DRY_INSTALL=1`, waits for VeryLazy, runs `body`, in which `report(value)` sends one value back, and returns that value decoded. It raises an error carrying the child's output when the child reports nothing or the body fails.

nvim-treesitter's `main` branch is a rewrite: it no longer starts highlighting by itself and does not support lazy loading, and it builds each parser with the `tree-sitter` command-line tool, which the Mac's setup installs from Homebrew. Neovim 0.12 already carries the C, Lua, Markdown, query, Vim and Vim help parsers, so a Lua file has highlighting in the regular suite even though nothing is downloaded, and Neovim's own help, command line and hover windows draw with them. That is why nothing installs at the first start.

A parser installs the first time a real file needs it, and only then. A real file means a buffer with no special type (Neovim's `buftype` option is empty for an ordinary file and set for help, terminals and plugin windows), a name, and a file on disk behind that name. A picker's preview of a Python file, a help page, a scratch buffer and a buffer given a file type by hand are not real files, so they install nothing and get only the parsers already there. A new file that does not exist yet installs its parsers the first time it is written.

A file can hold another language inside it: a Lua file can carry Vim script in a `vim.cmd` string and C in an `ffi.cdef` string. Tree-sitter calls this an injection, and each parser's `injections.scm` query names the language to use, either literally, as `injection.language "vim"`, or through a capture, as a Markdown code block does with the word after its opening fence. Once a file's own parsers are there, the installer reads their injection queries and installs every language they name literally. A language named only through a capture installs when a file of that language is opened, so one Markdown file never pulls in a parser for every language its code blocks could hold.

- [ ] **Write the failing tests**

`tests/test_treesitter.lua`:

```lua
-- Tree-sitter. Every parser the table names is one nvim-treesitter can
-- install, every file type's parser is on its language's list, a fresh start
-- installs nothing, a file asks for its parsers and the ones its injections
-- name, a buffer that is not a file asks for nothing until it is written, an
-- installed parser gives highlighting and the moves, a diff keeps ]c and [c,
-- and a failed parser install is tried once per session.

local function available()
  local set = {}
  for _, name in ipairs(require("nvim-treesitter").get_available()) do
    set[name] = true
  end
  return set
end

local function samples(t)
  return dofile(t.root .. "/tests/fixtures/samples.lua")
end

return {
  ["every parser the table names is one nvim-treesitter can install"] = function(t)
    local known = available()
    local missing = {}
    for _, name in ipairs(require("ach.lang").all_parsers()) do
      if not known[name] then
        missing[#missing + 1] = name
      end
    end
    t.eq(missing, {}, "parsers nvim-treesitter does not know")
  end,

  ["each file type's parser is on its language's list"] = function(t)
    local known = available()
    local wrong = {}
    for _, e in ipairs(require("ach.lang").entries()) do
      for _, ft in ipairs(e.ft) do
        local parser = vim.treesitter.language.get_lang(ft) or ft
        if known[parser] and not vim.list_contains(e.ts or {}, parser) then
          wrong[#wrong + 1] = ("%s: %s is parsed by %s"):format(e.name, ft, parser)
        end
      end
    end
    t.eq(wrong, {}, "file types whose parser the table never installs")
  end,

  ["a fresh start installs nothing"] = function(t)
    local child = dofile(t.root .. "/tests/helpers/child.lua")
    local got = child.run(t, [[report(require("ach.install").requests)]])
    t.eq(got.parsers, {}, "parsers asked for before any file was opened")
    t.eq(got.packages, {}, "tools asked for before any file was opened")
    t.eq(got.servers, {}, "servers asked for before any file was opened")
  end,

  ["a Lua file asks for its own parsers and the ones its injections name"] = function(t)
    local child = dofile(t.root .. "/tests/helpers/child.lua")
    local file = vim.fn.fnameescape(samples(t).write(t.tmpdir(), "lua"))
    local got = child.run(t, ("vim.cmd.edit(%q)\nreport(require('ach.install').requests.parsers)"):format(file))
    -- lua, luadoc and luap are the entry's own; Lua's injection query names
    -- c for ffi.cdef, vim for vim.cmd and query for vim.treesitter.query.parse.
    for _, name in ipairs({ "lua", "luadoc", "luap", "c", "query", "vim" }) do
      t.ok(vim.list_contains(got, name), name .. " is not among " .. table.concat(got, ", "))
    end
  end,

  ["a buffer that is not a file asks for nothing"] = function(t)
    local install = require("ach.install")
    local path = samples(t).write(t.tmpdir(), "python")
    local opened = {}
    local dry = install.dry
    install.dry = true -- under --full the installer is live and records nothing
    install.reset()
    local ok, err = pcall(function()
      -- A scratch buffer given a file type, as a picker's preview is.
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.bo[scratch].filetype = "python"
      -- A buffer named after a real file that is still not a file's buffer.
      local preview = vim.api.nvim_create_buf(false, false)
      opened[#opened + 1] = preview
      vim.bo[preview].buftype = "nofile"
      vim.api.nvim_buf_set_name(preview, path)
      vim.bo[preview].filetype = "python"
      -- A new buffer whose file type is set by hand.
      vim.cmd("enew")
      opened[#opened + 1] = vim.api.nvim_get_current_buf()
      vim.cmd("setfiletype python")
      -- Neovim's help, whose buftype is "help".
      vim.cmd("help")
      opened[#opened + 1] = vim.api.nvim_get_current_buf()
      vim.cmd("helpclose")
      t.eq(install.requests.parsers, {}, "parsers asked for")
    end)
    for _, buf in ipairs(opened) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    install.dry = dry
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["a new file asks for its parsers once it is first written"] = function(t)
    local install = require("ach.install")
    local path = t.tmpdir() .. "/new.py"
    local dry = install.dry
    install.dry = true
    install.reset()
    local ok, err = pcall(function()
      vim.cmd.edit(vim.fn.fnameescape(path))
      t.eq(vim.bo.filetype, "python", "the file type, from the name")
      t.eq(install.requests.parsers, {}, "parsers asked for before the file exists")
      vim.cmd.write()
      t.ok(vim.list_contains(install.requests.parsers, "python"), "the python parser, once the file is written")
    end)
    vim.cmd("bwipeout!")
    install.dry = dry
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["a file whose parser is installed gets highlighting and the moves"] = function(t)
    vim.cmd.edit(vim.fn.fnameescape(samples(t).write(t.tmpdir(), "lua")))
    local buf = vim.api.nvim_get_current_buf()
    local highlighted = vim.treesitter.highlighter.active[buf] ~= nil
    local map = vim.fn.maparg("]f", "n", false, true)
    vim.cmd("bwipeout!")
    t.ok(highlighted, "highlighting started")
    t.eq({ map.buffer, map.desc }, { 1, "Next Function Start" }, "]f in the buffer")
  end,

  ["in a diff, ]c and [c still move between changes"] = function(t)
    local dir = t.tmpdir()
    vim.fn.writefile({ "local a = 1", "local b = 2", "local c = 3", "return a" }, dir .. "/a.lua")
    vim.fn.writefile({ "local a = 1", "local b = 2", "local c = 4", "return a" }, dir .. "/b.lua")
    vim.cmd.edit(dir .. "/a.lua")
    local a = vim.api.nvim_get_current_buf()
    vim.cmd("diffthis")
    vim.cmd.vsplit(dir .. "/b.lua")
    local b = vim.api.nvim_get_current_buf()
    vim.cmd("diffthis")
    vim.cmd("wincmd p")
    local ok, err = pcall(function()
      t.eq(vim.fn.maparg("]c", "n", false, true).desc, "Next Class Start", "]c is the class move outside a diff")
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.api.nvim_feedkeys("]c", "x", false)
      t.eq(vim.api.nvim_win_get_cursor(0)[1], 3, "line after ]c")
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      vim.api.nvim_feedkeys("[c", "x", false)
      t.eq(vim.api.nvim_win_get_cursor(0)[1], 3, "line after [c")
    end)
    vim.cmd("diffoff!")
    vim.cmd("only")
    vim.api.nvim_buf_delete(b, { force = true })
    vim.api.nvim_buf_delete(a, { force = true })
    if not ok then
      error(err, 0)
    end
  end,

  ["a parser that fails to install is tried once, and every caller hears back"] = function(t)
    local install = require("ach.install")
    local ts = require("nvim-treesitter")
    local saved = { install.dry, install.available_parsers, install.installed_parsers, ts.install }
    local calls, finish, heard = 0, nil, {}
    install.reset()
    install.dry = false
    install.available_parsers = function()
      return { ach_fake = true }
    end
    install.installed_parsers = function()
      return {}
    end
    ts.install = function()
      calls = calls + 1
      return {
        await = function(_, cb)
          finish = cb
        end,
      }
    end
    local ok, err = pcall(function()
      install.ensure_parsers({ "ach_fake" }, function()
        heard[#heard + 1] = "first"
      end)
      install.ensure_parsers({ "ach_fake" }, function()
        heard[#heard + 1] = "second"
      end)
      t.eq(calls, 1, "installs started for two callers")
      finish(nil, false)
      t.ok(vim.wait(1000, function()
        return #heard == 2
      end), "both callers heard back")
      install.ensure_parsers({ "ach_fake" }, function()
        heard[#heard + 1] = "third"
      end)
      t.eq(heard, { "first", "second", "third" }, "callers heard back")
      t.eq(calls, 1, "installs started after the failure")
    end)
    install.dry, install.available_parsers, install.installed_parsers, ts.install = unpack(saved)
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["every move has an icon"] = function(t)
    local icons = require("ach.icons")
    local missing = {}
    for _, move in ipairs(require("ach.treesitter").moves) do
      local found = icons.key(move[4])
      if not (found and found.icon) then
        missing[#missing + 1] = move[4]
      end
    end
    t.eq(missing, {}, "moves with no icon")
  end,
}
```

Each test that replaces a field or opens a window puts things back before it re-raises, so one failure cannot leak into the tests after it.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_treesitter`
Expected: `0 passed, 10 failed, 0 need a person, 0 skipped`, exit 1. The first two fail on `module 'nvim-treesitter' not found`, the two children report the same error for `ach.install`, and the rest fail on the missing `ach.install` and `ach.treesitter` modules or on `]f` and `]c` having no buffer mapping.

- [ ] **Write the child-Neovim helper**

`tests/helpers/child.lua`:

```lua
-- Runs a second, headless Neovim with this configuration and returns what its
-- body reported. The body is Lua source that runs after VeryLazy and calls
-- report(value) once, with any value vim.json can encode. The child runs
-- dry, so it never downloads, whatever mode the suite itself is in.
local M = {}

function M.run(t, body, opts)
  opts = opts or {}
  local dir = t.tmpdir()
  local out = dir .. "/report.json"
  local script = dir .. "/child.lua"
  local source = table.concat({
    "vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })",
    "vim.wait(10000, function() return vim.g.did_very_lazy == true end, 20)",
    ("local out = %q"):format(out),
    "local function report(value)",
    "  vim.fn.writefile({ vim.json.encode(value) }, out)",
    "  vim.cmd('qall!')",
    "end",
    "local ok, err = pcall(function()",
    body,
    "end)",
    "vim.fn.writefile({ vim.json.encode({ child_error = ok and 'the body never called report()' or tostring(err) }) }, out)",
    "vim.cmd('qall!')",
  }, "\n")
  vim.fn.writefile(vim.split(source, "\n"), script)

  local cmd = { vim.v.progpath, "--headless", "-u", t.root .. "/init.lua" }
  vim.list_extend(cmd, opts.args or {})
  cmd[#cmd + 1] = "+luafile " .. script
  local env = vim.tbl_extend("force", { ACH_TEST = "1", ACH_DRY_INSTALL = "1" }, opts.env or {})
  local result = vim.system(cmd, { env = env, cwd = opts.cwd, text = true, timeout = opts.timeout or 30000 }):wait()

  local f = io.open(out)
  if not f then
    error(("the child Neovim reported nothing (exit %s)\n%s%s"):format(result.code, result.stdout or "", result.stderr or ""), 0)
  end
  local value = vim.json.decode(f:read("*a"))
  f:close()
  if type(value) == "table" and value.child_error then
    error("the child Neovim failed: " .. value.child_error, 0)
  end
  return value
end

return M
```

`vim.system` adds `env` to the current environment rather than replacing it, so the child inherits the throwaway state folder `scripts/check` set up.

- [ ] **Make the regular suite run dry**

In `scripts/check`, add one line directly after `export XDG_STATE_HOME="$scratch/state" CLAUDE_CONFIG_DIR="$scratch/claude"`:

```bash
if [ "$full" = 0 ]; then export ACH_DRY_INSTALL=1; fi
```

- [ ] **Write the plugin specs**

`lua/ach/plugins/treesitter.lua`:

```lua
-- Tree-sitter. nvim-treesitter installs parsers and their queries, and
-- nvim-treesitter-textobjects carries the function, class and parameter
-- queries the moves use. Both track their main branch, which needs Neovim
-- 0.12 and the tree-sitter command-line tool. lua/ach/install.lua decides
-- when a parser installs, and lua/ach/treesitter.lua starts it on a buffer.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- the main branch does not support lazy loading
    build = ":TSUpdate",
    init = function()
      -- nvim-treesitter rereads its parser list on this event, so the table's
      -- own parsers are added back each time.
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("ach.treesitter").register_custom()
        end,
      })
    end,
    config = function()
      require("nvim-treesitter").setup({})
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
      -- Buffers opened before VeryLazy were attached before these queries
      -- were on the runtime path, so they get their moves now.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          require("ach.treesitter").attach(buf)
        end
      end
    end,
  },
}
```

- [ ] **Write the attach module**

`lua/ach/treesitter.lua`:

```lua
-- Starts Tree-sitter on a buffer: highlighting, indentation and the moves,
-- each only when the parser loads and the query that feature reads exists.
-- A file type with no parser, such as Snacks' "bigfile", gets nothing and
-- keeps Neovim's own syntax.
local M = {}

-- Moves between functions, classes and parameters, from
-- nvim-treesitter-textobjects. Each row is the key, the move, the query
-- capture and the description, which has a line in M.keys in icons.lua.
M.moves = {
  { "]f", "goto_next_start", "@function.outer", "Next Function Start" },
  { "]c", "goto_next_start", "@class.outer", "Next Class Start" },
  { "]a", "goto_next_start", "@parameter.inner", "Next Parameter Start" },
  { "]F", "goto_next_end", "@function.outer", "Next Function End" },
  { "]C", "goto_next_end", "@class.outer", "Next Class End" },
  { "]A", "goto_next_end", "@parameter.inner", "Next Parameter End" },
  { "[f", "goto_previous_start", "@function.outer", "Prev Function Start" },
  { "[c", "goto_previous_start", "@class.outer", "Prev Class Start" },
  { "[a", "goto_previous_start", "@parameter.inner", "Prev Parameter Start" },
  { "[F", "goto_previous_end", "@function.outer", "Prev Function End" },
  { "[C", "goto_previous_end", "@class.outer", "Prev Class End" },
  { "[A", "goto_previous_end", "@parameter.inner", "Prev Parameter End" },
}

-- Adds the table's own parsers, the ones nvim-treesitter does not carry, to
-- its parser list. Runs on every User TSUpdate event.
function M.register_custom()
  local parsers = require("nvim-treesitter.parsers")
  for name, p in pairs(require("ach.lang").custom_parsers()) do
    parsers[name] = { install_info = { url = p.url, revision = p.revision, queries = p.queries } }
  end
end

local function has_query(lang, name)
  local ok, query = pcall(vim.treesitter.query.get, lang, name)
  return ok and query ~= nil
end

-- The moves as buffer keys. In a diff, ]c and [c keep Neovim's meaning, the
-- next and previous change, which matters more there than classes do.
function M.moves_for(buf)
  for _, move in ipairs(M.moves) do
    local key, method, query, desc = unpack(move)
    vim.keymap.set({ "n", "x", "o" }, key, function()
      if vim.wo.diff and key:find("[cC]") then
        vim.cmd("normal! " .. vim.v.count1 .. key)
        return
      end
      require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
    end, { buffer = buf, desc = desc, silent = true })
  end
end

function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if not (ok and added) then
    return
  end
  if has_query(lang, "highlights") then
    pcall(vim.treesitter.start, buf, lang)
  end
  if has_query(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  if has_query(lang, "textobjects") then
    M.moves_for(buf)
  end
end

return M
```

- [ ] **Write the parser half of the installer**

`lua/ach/install.lua`:

```lua
-- Installs what a language needs the first time one of its files opens, then
-- starts Tree-sitter on the buffer. Under ACH_DRY_INSTALL=1, which
-- scripts/check sets outside --full, it installs nothing and records what it
-- would have installed in M.requests, so the regular suite never downloads.
local M = {}

M.dry = vim.env.ACH_DRY_INSTALL == "1"
M.requests = { parsers = {}, packages = {}, servers = {} }

local available -- nvim-treesitter's parser names, read once
local failed = {} -- parsers that failed this session, never retried
local pending = {} -- parser name -> callbacks waiting on its install

local function record(kind, names)
  local list = M.requests[kind]
  for _, name in ipairs(names) do
    if not vim.list_contains(list, name) then
      list[#list + 1] = name
    end
  end
  table.sort(list)
end

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
  require("nvim-treesitter").install(new, { summary = false }):await(function()
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

function M.reset()
  M.requests = { parsers = {}, packages = {}, servers = {} }
  available, failed, pending = nil, {}, {}
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

-- Installs the parsers a buffer's file type needs, then starts Tree-sitter on
-- it. Anything that is not a real file gets whatever parser is already there.
local function handle(buf, ft)
  local attach = function()
    require("ach.treesitter").attach(buf)
  end
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
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ach_install", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
      handle(ev.buf, ev.match)
    end,
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
```

`ensure_parsers` calls `done` straight away when nothing needs installing, so a buffer whose parser is already there is attached inside its own `FileType` event, before the first screen draws it. Nothing is created for the first start: the parsers Neovim carries draw its help, command line and hover windows, and Neovim's own help file type starts Tree-sitter on a help page by itself.

- [ ] **Start the installer before lazy.nvim**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added and the installer's
-- hooks created before lazy.nvim starts, so a file named on the command line
-- is recognised and gets its parsers when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.install").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

- [ ] **Give the moves their icons**

In `lua/ach/icons.lua`, add these lines to `M.keys`, directly above `-- Keys added by later tasks go above this line.`:

```lua
  -- Tree-sitter moves
  ["Next Function Start"] = { "kinds.Function", "purple" },
  ["Next Function End"] = { "kinds.Function", "purple" },
  ["Prev Function Start"] = { "kinds.Function", "purple" },
  ["Prev Function End"] = { "kinds.Function", "purple" },
  ["Next Class Start"] = { "kinds.Class", "yellow" },
  ["Next Class End"] = { "kinds.Class", "yellow" },
  ["Prev Class Start"] = { "kinds.Class", "yellow" },
  ["Prev Class End"] = { "kinds.Class", "yellow" },
  ["Next Parameter Start"] = { "kinds.Parameter", "cyan" },
  ["Next Parameter End"] = { "kinds.Parameter", "cyan" },
  ["Prev Parameter Start"] = { "kinds.Parameter", "cyan" },
  ["Prev Parameter End"] = { "kinds.Parameter", "cyan" },
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones nvim-treesitter and nvim-treesitter-textobjects and adds both to `lazy-lock.json`. No parser is built: parsers install from the hooks, not from the build step, and `:TSUpdate` updates only what is already installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 10 `test_treesitter` tests pass, along with every earlier test, including `test_lock`'s check that every plugin loads without a warning. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/plugins/treesitter.lua lua/ach/treesitter.lua lua/ach/install.lua tests/helpers/child.lua tests/test_treesitter.lua
git commit --only lua/ach/plugins/treesitter.lua lua/ach/treesitter.lua lua/ach/install.lua lua/ach/init.lua lua/ach/icons.lua tests/helpers/child.lua tests/test_treesitter.lua scripts/check lazy-lock.json -m "feat(treesitter): install each language's parsers on first open and add the moves"
```

---

### Task: Mason, the lock file and the tool installer

**Files:**
- Create: `lua/ach/masonlock.lua`, `lua/ach/runtimes.lua`, `lua/ach/plugins/mason.lua`, `mason-lock.json`
- Modify: `lua/ach/install.lua` (replace the whole file), `lua/ach/init.lua` (replace the whole file), `lua/ach/icons.lua` (one line in `M.keys`), `lazy-lock.json` (written by lazy.nvim)
- Test: `tests/test_mason.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` (`for_ft`, `packages_for_ft(ft, server_to_package)`, `servers_for_ft`, `command(req)`, `steps(req)`); an entry's `runtime` and each value of its `system`, a requirement `{ name, check?, brew?, after?, size?, command? }`; `require("ach.treesitter").attach(buf)`; the parser half of `lua/ach/install.lua` from the tree-sitter task, `is_file` and `injected_parsers` among it, carried over unchanged apart from the hook, which now installs a file's tools as well; `I.mason.installed`, `I.mason.pending`, `I.mason.uninstalled` from `lua/ach/icons.lua`; `tests/fixtures/samples.lua`.
- Produces:
  - `require("ach.masonlock")`: `path: string` (`vim.g.ach_root .. "/mason-lock.json"`, replaceable in tests), `read(path?): table<string, string>` (empty for a missing or broken file), `encode(lock): string`, `write(lock, path?)`, `install(name, done: fun(ok: boolean, err?: string))`, which installs the pinned version or, with no pin, the latest and pins what it installed, `adopt(): string[]`, which adds a line for each installed package the lock lacks and returns their names, and `update(done: fun(changed: string[], failed: string[]))`.
  - `require("ach.runtimes")`: `setup(opts?: { java?: string[], first?: string[], last?: string[] }): string|nil`, which puts Homebrew's Ruby first on `PATH` and the rustup, cargo, ghcup, elan, opam and Homebrew LLVM folders last, each only if it exists and is not there already, then sets `JAVA_HOME`, puts its `bin` first and returns the JDK's home, `probe(argv, cb: fun(ok: boolean))`, `check(runtime, cb: fun(ok: boolean))`, which probes each runtime once per session, and `reset(name?: string)`, which forgets the answer for one runtime, as once Homebrew has installed it, or for all of them.
  - `require("ach.install")` gains `ensure_tools(buf, ft)`, which does nothing for a buffer that is not a real file, `ensure_packages(names, done)`, `with_registry(cb)`, `server_packages(): table<string, string>`, `has_package(name)`, `package_installed(name)`, `offer(req, ft, entry)`, which asks once a session whether Homebrew should install a missing requirement, `ask(question, cb: fun(yes: boolean))` and `run(argv, cb: fun(ok: boolean, output?: string))`, the two calls through which it asks and runs, which tests replace, and `ready(buf, ft, entry)`, which is called once a buffer's packages are installed and does nothing yet. The language-server task fills `ready` in. `reset()` now clears every failure, warning, question, queued Homebrew install and wait the session has collected. Under a dry run `requests.packages` and `requests.servers` are filled, and so is `requests.asks: { question: string, run: string[][] }[]`, each question it would have asked, or command it would have shown, with the commands a yes would run.
  - The `<leader>cm` key, "Mason", and the commands `:AchMasonLock` and `:AchMasonUpdate`.

Mason has no lock file of its own, and the plugin that used to add one, mason-lock.nvim, does not support mason.nvim 2. `lua/ach/masonlock.lua` replaces it in about a hundred lines. The rule it keeps is the Global Constraint's: a line is added the first time a package installs, and an existing line changes only under `:AchMasonUpdate`. Lines for packages that are not installed on this Mac are kept, because another Mac may use them.

Mason cannot install everything. A Haskell file needs the GHC compiler before Mason's Haskell server is any use, and a Swift file needs Apple's `sourcekit-lsp`. The language table names each such requirement, and `ensure_tools` checks for it the first time a real file of the language opens. When it is missing, `offer` asks the owner one question through `vim.ui.select`, Neovim's way of letting the user pick from a short list, here Yes and No. A yes puts the requirement's commands, `brew install` and any follow-up such as `ghcup install ghc`, in a queue that runs one command at a time in the background through `vim.system`, which starts a program without waiting for it to finish; one at a time, because two Homebrew installs at once wait on each other's lock. When the queue finishes a requirement, every open file that was waiting for it goes through `ensure_tools` again, and this time its Mason tools install. A no, or a failure, settles the matter for the session. What Homebrew cannot install, such as Apple's Command Line Tools, is never asked about; its command is shown once.

- [ ] **Write the failing tests**

`tests/test_mason.lua`:

```lua
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
  return seen, function(msg, level)
    seen[#seen + 1] = { msg = msg, level = level }
  end
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
  function pkg:is_installing()
    return false
  end
  function pkg:install(opts, cb)
    self.asked[#self.asked + 1] = opts.version or "latest"
    cb(err == nil, err)
  end
  function pkg:get_installed_version()
    return installed_version
  end
  return pkg, {
    get_package = function()
      return pkg
    end,
  }
end

-- The stubs that stand the installer up live, with no registry behind it.
local function live(install, extra)
  local stubs = {
    { install, "dry", false },
    { install, "with_registry", function(cb)
      cb()
    end },
    { install, "server_packages", function()
      return DOCKER
    end },
    { install, "has_package", function()
      return true
    end },
    { install, "package_installed", function()
      return false
    end },
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
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("noautocmd setlocal filetype=" .. ft)
  end)
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
      lock.install("fake", function(ok)
        results[#results + 1] = ok
      end)
      t.ok(vim.wait(1000, function()
        return #results == 1
      end), "the first install finished")
      lock.install("fake", function(ok)
        results[#results + 1] = ok
      end)
      t.ok(vim.wait(1000, function()
        return #results == 2
      end), "the second install finished")
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
      lock.install("fake", function(ok, err)
        got = { ok, err }
      end)
      t.ok(vim.wait(1000, function()
        return got ~= nil
      end), "the install finished")
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
        get_installed_version = function()
          return version
        end,
      }
    end
    local registry = {
      get_installed_packages = function()
        return { installed("current", "2.0"), installed("new", "3.0") }
      end,
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
      function p:get_installed_version()
        return self.installed
      end
      function p:get_latest_version()
        return latest
      end
      function p:is_installing()
        return false
      end
      function p:install(opts, cb)
        self.installed = opts.version
        cb(true, {})
      end
      return p
    end
    local old, current = package_at("old", "1.0", "1.1"), package_at("current", "2.0", "2.0")
    local registry = {
      refresh = function(cb)
        cb(true, {})
      end,
      get_installed_packages = function()
        return { old, current }
      end,
    }
    lock.write({ current = "2.0", old = "1.0", other_mac = "0.1" }, path)
    with({ { lock, "path", path }, { package.loaded, "mason-registry", registry } }, function()
      local changed, failed
      lock.update(function(c, f)
        changed, failed = c, f
      end)
      t.ok(vim.wait(1000, function()
        return changed ~= nil
      end), "the update finished")
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
      runtimes.probe(argv, function(ok)
        result = ok
      end)
      vim.wait(5000, function()
        return result ~= nil
      end)
      return result
    end
    t.eq({ probe({ "true" }), probe({ "false" }), probe({ "ach-no-such-program" }) }, { true, false, false })
  end,

  ["a dry run records a file type's packages and servers"] = function(t)
    local install = require("ach.install")
    local samples = dofile(t.root .. "/tests/fixtures/samples.lua")
    with({
      { install, "dry", true },
      { install, "server_packages", function()
        return DOCKER
      end },
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
    local function count()
      calls = calls + 1
    end
    with({
      { install, "dry", true },
      { install, "server_packages", function()
        return {}
      end },
      { install, "ask", count },
      { install, "run", count },
      { runtimes, "probe", function(_, cb)
        cb(false)
      end },
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
        { install, "ready", function()
          ready = ready + 1
        end },
        { install, "ask", function(question, cb)
          asked[#asked + 1] = question
          cb(false)
        end },
        { lock, "install", function()
          installs = installs + 1
        end },
        { runtimes, "probe", function(_, cb)
          probes = probes + 1
          cb(false)
        end },
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
        { install, "ready", function(buf)
          ready[#ready + 1] = buf
        end },
        { install, "ask", function(question, cb)
          asked[#asked + 1] = question
          cb(true)
        end },
        { install, "run", function(argv, cb)
          ran[#ran + 1] = table.concat(argv, " ")
          finish[#finish + 1] = cb
        end },
        { lock, "install", function(name, done)
          installed[#installed + 1] = name
          done(true)
        end },
        { runtimes, "setup", function() end },
        { runtimes, "probe", function(argv, cb)
          cb(found[argv[1]] == true)
        end },
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
        { install, "ask", function(_, cb)
          asked = asked + 1
          cb(true)
        end },
        { install, "run", function(argv, cb)
          ran[#ran + 1] = table.concat(argv, " ")
          cb(false, "curl: (6) Could not resolve host: ghcr.io")
        end },
        { lock, "install", function()
          installs = installs + 1
        end },
        { runtimes, "setup", function() end },
        { runtimes, "probe", function(_, cb)
          cb(false)
        end },
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
        { install, "ask", function()
          asked = asked + 1
        end },
        { lock, "install", function(_, done)
          done(true)
        end },
        { vim.fn, "executable", function(program)
          return program == "sourcekit-lsp" and 0 or executable(program)
        end },
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
    local function count()
      calls = calls + 1
    end
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
        { install, "ready", function()
          ready = ready + 1
        end },
        { lock, "install", function(_, done)
          installs = installs + 1
          done(false, "network is unreachable")
        end },
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
        { install, "ready", function(buf)
          ready[#ready + 1] = buf
        end },
        { lock, "install", function(name, done)
          started[#started + 1] = name
          finish[#finish + 1] = function()
            done(true)
          end
        end },
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
```

The Review Focus tests call `ensure_tools` directly rather than opening a file, so the live installer they stand up never reaches nvim-treesitter, which would download a parser. `file_buf` gives each of them a real file on disk, since `ensure_tools` does nothing for any other buffer, and sets its file type with `noautocmd`, which keeps the installer's own `FileType` hook from running for it. None of them asks a question or runs Homebrew: they replace `ask`, which would show the question, and `run`, which would start the command, with stubs that answer at once or hold the answer until the test releases it, the way a slow `brew install` would.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_mason`
Expected: `0 passed, 19 failed, 0 need a person, 0 skipped`, exit 1. Each test fails on `module 'ach.masonlock' not found` or `module 'ach.runtimes' not found`, whichever it requires first, except the last, which fails on `<leader>cm` having no mapping.

- [ ] **Write the lock file module**

`lua/ach/masonlock.lua`:

```lua
-- mason-lock.json: the version of every Mason package, so a second Mac
-- installs what this one has. A package's line is added the first time it
-- installs, and an existing line changes only under :AchMasonUpdate. Lines
-- for packages not installed on this Mac are kept, since another Mac may use
-- them. Every function that writes runs on the main loop.
local M = {}

M.path = vim.g.ach_root .. "/mason-lock.json"

function M.read(path)
  local f = io.open(path or M.path)
  if not f then
    return {}
  end
  local text = f:read("*a")
  f:close()
  local ok, lock = pcall(vim.json.decode, text)
  return ok and type(lock) == "table" and lock or {}
end

-- One package to a line, sorted, so a diff shows exactly what moved.
function M.encode(lock)
  local names = vim.tbl_keys(lock)
  if #names == 0 then
    return "{}\n"
  end
  table.sort(names)
  local lines = {}
  for _, name in ipairs(names) do
    lines[#lines + 1] = ("  %s: %s"):format(vim.json.encode(name), vim.json.encode(lock[name]))
  end
  return "{\n" .. table.concat(lines, ",\n") .. "\n}\n"
end

function M.write(lock, path)
  local f = assert(io.open(path or M.path, "w"))
  f:write(M.encode(lock))
  f:close()
end

-- Installs a package at its pinned version, or at the latest when it has no
-- pin, and pins what Mason installed. done(ok, err) runs on the main loop.
function M.install(name, done)
  local pkg = require("mason-registry").get_package(name)
  local function finish(ok, err)
    vim.schedule(function()
      done(ok, err)
    end)
  end
  -- Installed from the :Mason window a moment ago: wait for that install
  -- rather than start a second, which mason.nvim refuses.
  if pkg:is_installing() then
    local succeeded, failed
    succeeded = function()
      pkg:off("install:failed", failed)
      finish(true)
    end
    failed = function(err)
      pkg:off("install:success", succeeded)
      finish(false, tostring(err))
    end
    pkg:once("install:success", succeeded)
    pkg:once("install:failed", failed)
    return
  end
  local pinned = M.read()[name]
  pkg:install({ version = pinned }, function(ok, result)
    vim.schedule(function()
      if ok and not pinned then
        local lock = M.read()
        lock[name] = pkg:get_installed_version()
        M.write(lock)
      end
      done(ok, not ok and tostring(result) or nil)
    end)
  end)
end

-- Writes the installed version of each installed package into the lock,
-- over an existing line only when overwrite is set. Returns the names whose
-- line was added or changed.
local function pin(overwrite)
  local lock, touched = M.read(), {}
  for _, pkg in ipairs(require("mason-registry").get_installed_packages()) do
    local version = pkg:get_installed_version()
    if version and lock[pkg.name] ~= version and (overwrite or lock[pkg.name] == nil) then
      lock[pkg.name] = version
      touched[#touched + 1] = pkg.name
    end
  end
  table.sort(touched)
  M.write(lock)
  return touched
end

-- :AchMasonLock. Pins each package installed by hand from the :Mason window.
function M.adopt()
  return pin(false)
end

-- :AchMasonUpdate. Refreshes the registry, installs the latest version of
-- every installed package that is behind, and moves each one's pin.
function M.update(done)
  local registry = require("mason-registry")
  registry.refresh(function()
    vim.schedule(function()
      local stale = {}
      for _, pkg in ipairs(registry.get_installed_packages()) do
        local latest = pkg:get_latest_version()
        if not pkg:is_installing() and pkg:get_installed_version() ~= latest then
          stale[#stale + 1] = { pkg = pkg, version = latest }
        end
      end
      local failed, remaining = {}, #stale
      local function finish()
        table.sort(failed)
        done(pin(true), failed)
      end
      if remaining == 0 then
        return finish()
      end
      for _, s in ipairs(stale) do
        s.pkg:install({ version = s.version }, function(ok)
          vim.schedule(function()
            if not ok then
              failed[#failed + 1] = s.pkg.name
            end
            remaining = remaining - 1
            if remaining == 0 then
              finish()
            end
          end)
        end)
      end
    end)
  end)
end

return M
```

- [ ] **Write the runtimes module**

`lua/ach/runtimes.lua`:

```lua
-- Language runtimes Mason cannot install. setup() puts Homebrew's Java on
-- the path, because macOS ships /usr/bin/java as a stub that only offers to
-- install Java, and Java, Kotlin, Groovy and Scala tools all look for a real
-- one. It also adds the folders a shell profile would, so Neovim started from
-- the Dock finds the same programs as Neovim started from a terminal. check()
-- says whether a runtime works, asking once per session.
local M = {}

M.kegs = { "/opt/homebrew/opt/openjdk@21", "/opt/homebrew/opt/openjdk" }

-- Homebrew's Ruby is keg-only: it is not linked into /opt/homebrew/bin, so
-- without this the path finds macOS's own Ruby 2.6, which ruby-lsp cannot run
-- on. It goes first so it wins over /usr/bin/ruby.
M.first = { "/opt/homebrew/opt/ruby/bin" }

-- Toolchain managers install into folders of their own: rustup (keg-only in
-- Homebrew) and the programs cargo builds, ghcup for Haskell, elan for Lean,
-- and opam for OCaml, whose `opam init -n` makes a switch named default and
-- leaves the shell's startup files alone. Homebrew's LLVM is keg-only too, and
-- its folder holds mlir-lsp-server and tblgen-lsp-server. They go last, so a
-- program Homebrew also provides is still found in Homebrew first, and LLVM's
-- clang never stands in front of Apple's. Each is added only once it exists,
-- and setup() runs again after every Homebrew install, so a folder that
-- install made is on the path straight away.
M.last = {
  "/opt/homebrew/opt/rustup/bin",
  "~/.cargo/bin",
  "~/.ghcup/bin",
  "~/.elan/bin",
  "~/.opam/default/bin",
  "/opt/homebrew/opt/llvm/bin",
}

local function on_path(dir)
  for _, d in ipairs(vim.split(vim.env.PATH or "", ":", { plain = true })) do
    if d ~= "" and vim.fs.normalize(d) == dir then
      return true
    end
  end
  return false
end

-- Adds each folder that exists and is not already on the path. Folders added
-- to the front go in reverse, so the list's first entry ends up first.
local function add(dirs, front)
  local from, to, step = 1, #dirs, 1
  if front then
    from, to, step = #dirs, 1, -1
  end
  for i = from, to, step do
    local dir = vim.fs.normalize(dirs[i])
    if vim.fn.isdirectory(dir) == 1 and not on_path(dir) then
      vim.env.PATH = front and (dir .. ":" .. vim.env.PATH) or (vim.env.PATH .. ":" .. dir)
    end
  end
end

local function java(kegs)
  if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
    return nil
  end
  for _, keg in ipairs(kegs) do
    local home = keg .. "/libexec/openjdk.jdk/Contents/Home"
    if vim.uv.fs_stat(home .. "/bin/java") then
      vim.env.JAVA_HOME = home
      vim.env.PATH = home .. "/bin:" .. vim.env.PATH
      return home
    end
  end
  return nil
end

-- opts: { java = kegs, first = folders, last = folders }, each defaulting to
-- the lists above. Returns the JDK's home when it set one.
function M.setup(opts)
  opts = opts or {}
  add(opts.first or M.first, true)
  add(opts.last or M.last, false)
  return java(opts.java or M.kegs)
end

-- Runs argv and reports whether it exited 0. A program that is not on the
-- path is false at once, since vim.system raises for it.
function M.probe(argv, cb)
  if vim.fn.executable(argv[1]) ~= 1 then
    return cb(false)
  end
  local ok = pcall(vim.system, argv, { text = true, timeout = 10000 }, function(result)
    vim.schedule(function()
      cb(result.code == 0)
    end)
  end)
  if not ok then
    cb(false)
  end
end

local results, waiting = {}, {}

function M.check(runtime, cb)
  local name = runtime.name
  if results[name] ~= nil then
    return cb(results[name])
  end
  if waiting[name] then
    table.insert(waiting[name], cb)
    return
  end
  waiting[name] = { cb }
  M.probe(runtime.check, function(ok)
    results[name] = ok
    local list = waiting[name]
    waiting[name] = nil
    for _, f in ipairs(list) do
      f(ok)
    end
  end)
end

-- Forgets what check found for the runtime named name, as once Homebrew has
-- installed it, or for every runtime when name is nil.
function M.reset(name)
  if name then
    results[name] = nil
  else
    results, waiting = {}, {}
  end
end

return M
```

- [ ] **Write the installer**

`lua/ach/install.lua` (replace the whole file; the parser half is the tree-sitter task's, unchanged apart from where its state is declared and the one line in the hook that now installs a file's tools as well):

```lua
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
  require("nvim-treesitter").install(new, { summary = false }):await(function()
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
        warn_once("registry", ("Mason could not update its registry: %s"):format(tostring(result)), vim.log.levels.ERROR)
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

function M.has_package(name)
  return require("mason-registry").has_package(name)
end

function M.package_installed(name)
  return require("mason-registry").is_installed(name)
end

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
  vim.ui.select({ "Yes", "No" }, { prompt = question }, function(choice)
    cb(choice == "Yes")
  end)
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
    vim.schedule(function()
      cb(result.code == 0, said)
    end)
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

-- Called once a buffer's packages are installed, or have failed. The
-- language-server task fills this in; until then a buffer gets Tree-sitter
-- and nothing more.
function M.ready(buf, ft, entry) end

-- The hook ------------------------------------------------------------------------

-- Installs the parsers a buffer's file type needs and starts Tree-sitter on
-- it, then installs the file type's tools. Anything that is not a real file
-- gets whatever parser is already there, and nothing more.
local function handle(buf, ft)
  local attach = function()
    require("ach.treesitter").attach(buf)
  end
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
    callback = function(ev)
      handle(ev.buf, ev.match)
    end,
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
```

A language whose runtime is missing gets no `M.ready` until Homebrew has installed it, so none of its own servers start. Harper waits too, because `harper-ls` is one of the file type's Mason packages, so after a no the file has highlighting and nothing more for the rest of the session. Harper can still attach to such a buffer once it is enabled for some other file, because an enabled server attaches to every file type its configuration lists. A program the language needs besides its runtime, such as `dart` for Dart files, does not hold the Mason packages back: they install while the question waits, and a yes sends the buffer through `ensure_tools` again once Homebrew finishes, which starts the server whose program has just arrived. A package that fails to download still hands the buffer on, because the file's other servers, and Harper, may be fine.

- [ ] **Write the plugin spec**

`lua/ach/plugins/mason.lua`:

```lua
-- mason.nvim installs language servers, formatters, linters and debuggers
-- into Neovim's data folder and puts them on the path. lua/ach/install.lua
-- decides what to install and when, and lua/ach/masonlock.lua pins each
-- package's version in mason-lock.json, which mason.nvim has no notion of.
local I = require("ach.icons")

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" },
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    init = function()
      vim.api.nvim_create_user_command("AchMasonLock", function()
        local added = require("ach.masonlock").adopt()
        vim.notify(
          #added == 0 and "mason-lock.json already pins every installed package"
            or ("Pinned %s in mason-lock.json"):format(table.concat(added, ", "))
        )
      end, { desc = "Pin each installed Mason package that mason-lock.json does not list" })
      vim.api.nvim_create_user_command("AchMasonUpdate", function()
        vim.notify("Updating Mason packages")
        require("ach.masonlock").update(function(changed, failed)
          local lines = { #changed == 0 and "Every Mason package is up to date" or ("Updated " .. table.concat(changed, ", ")) }
          if #failed > 0 then
            lines[#lines + 1] = "Could not update " .. table.concat(failed, ", ")
          end
          vim.notify(table.concat(lines, "\n"), #failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
        end)
      end, { desc = "Update every installed Mason package and move its pin" })
    end,
    opts = {
      ui = {
        icons = {
          package_installed = I.mason.installed,
          package_pending = I.mason.pending,
          package_uninstalled = I.mason.uninstalled,
        },
      },
    },
  },
}
```

lazy.nvim loads mason.nvim the first time anything requires `mason-registry`, so the installer and both commands work without the key having been pressed.

- [ ] **Start an empty lock file**

`mason-lock.json`:

```json
{}
```

- [ ] **Put Java on the path before anything starts**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added, Homebrew's Java,
-- Ruby and the toolchain folders put on the path and the installer's hooks
-- created before lazy.nvim starts, so a file named on the command line is
-- recognised and gets its parsers and tools when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.runtimes").setup()
require("ach.install").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

- [ ] **Give the key its icon**

In `lua/ach/icons.lua`, add this line to `M.keys`, directly above `-- Keys added by later tasks go above this line.`:

```lua
  ["Mason"] = { "mason.mason", "green" },
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones mason.nvim and adds it to `lazy-lock.json`. Nothing is installed through Mason.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 19 `test_mason` tests pass, along with every earlier test. `mason-lock.json` still reads `{}`, since the regular suite installs nothing, and no Homebrew question appears, since the tests answer every one themselves. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/masonlock.lua lua/ach/runtimes.lua lua/ach/plugins/mason.lua mason-lock.json tests/test_mason.lua
git commit --only lua/ach/masonlock.lua lua/ach/runtimes.lua lua/ach/plugins/mason.lua lua/ach/install.lua lua/ach/init.lua lua/ach/icons.lua mason-lock.json tests/test_mason.lua lazy-lock.json -m "feat(mason): install each language's tools on first open, ask before installing its compiler, and pin versions"
```

---

### Task: Language servers

**Files:**
- Create: `lua/ach/servers.lua`, `lua/ach/lsp.lua`, `lua/ach/plugins/lsp.lua`
- Modify: `lua/ach/install.lua` (replace `M.ready` only), `lua/ach/icons.lua` (five glyphs in `M.code`, lines in `M.keys`), `lazy-lock.json` (written by lazy.nvim)
- Test: `tests/test_lsp.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` (`servers()`, `servers_for_ft(ft)`); `require("ach.install")`'s `M.ready(buf, ft, entry)`, called once a buffer's packages are installed and never under a dry run; `require("ach.icons")` (`I.key(desc)`, `I.diagnostics`); `Snacks.picker.pick(source)`, `Snacks.rename.rename_file()`, `Snacks.words.jump(count)`; `require("blink.cmp").get_lsp_capabilities()`; the foundation's blink spec with `opts_extend = { "sources.default" }`.
- Produces:
  - `require("ach.servers")`: `programs: table<string, string>`, the program behind each server whose nvim-lspconfig command is built by a function, and `settings: table<string, table>`, passed to `vim.lsp.config(name, …)`.
  - `require("ach.lsp")`: `keys` (the buffer-local key list), `pickers: string[]` (every picker a key opens), `setup()`, `diagnostics(): table` (what `vim.diagnostic.config` receives), `capabilities(): table`, `program(name): string|nil`, `attach(buf, client)`, `enable_for(ft)` and `reset()`.
  - `install.ready(buf, ft, entry)` now enables the file type's servers. The managed-languages task adds the languages whose own plugin starts the server.
  - Glyphs `code.calls_in`, `code.calls_out`, `code.source_action`, `code.organize_imports` and `code.rename_file`.

Neovim 0.12 does most of what nvim-lspconfig once did. `vim.lsp.config(name, settings)` merges settings over the file nvim-lspconfig ships at `lsp/<name>.lua`, and `vim.lsp.enable(name)` starts the server for every buffer of its file types, open ones included. What is left for this task is deciding when to enable a server, and what a buffer gets once one attaches.

A server is enabled the first time a file of its language finishes installing and only if its program is on the path, so a package that failed to download, or a program Homebrew has not installed, starts nothing and prints nothing beyond the installer's own question or message. When the owner says yes and Homebrew installs the program, the installer goes over the file again and `ready` runs a second time, which is when the server starts. Neovim cannot tell whether a server is installed by itself, because twelve of nvim-lspconfig's servers build their command in a function, and `servers.programs` names the program for those twelve, and for `julials`, whose command this task replaces.

Neovim 0.12 already maps `grn` (rename), `gra` (code action), `grx` (run code lens), `grr`, `gri`, `grt`, `gO` and insert-mode `<C-S>` everywhere, and `K` on a server's buffer. This task keeps those and adds the rest on the buffer: `grr`, `gri` and `grt` open snacks pickers instead of the quickfix list, and every key below appears only when one of the buffer's servers can answer it. LazyVim also maps `<C-K>` in insert mode to signature help; this configuration leaves it alone, because `<C-K>` is how Vim types a character such as é, and Neovim's `<C-S>` already does the job.

| Key | Mode | What it does | Shown when the server supports |
| --- | --- | --- | --- |
| `<leader>cl` | normal | Lists the buffer's servers and their settings | always |
| `gd` | normal | Goes to the definition | `textDocument/definition` |
| `gD` | normal | Goes to the declaration | `textDocument/declaration` |
| `grr` | normal | Lists references | `textDocument/references` |
| `gri` | normal | Goes to the implementation | `textDocument/implementation` |
| `grt` | normal | Goes to the type's definition | `textDocument/typeDefinition` |
| `gai` | normal | Lists the functions that call this one | `callHierarchy/incomingCalls` |
| `gao` | normal | Lists the functions this one calls | `callHierarchy/outgoingCalls` |
| `K` | normal | Shows the documentation under the cursor | `textDocument/hover` |
| `gK` | normal | Shows the signature of the call under the cursor | `textDocument/signatureHelp` |
| `<leader>ca` | normal, visual | Offers code actions | `textDocument/codeAction` |
| `<leader>cA` | normal | Offers actions for the whole file | `textDocument/codeAction` |
| `<leader>co` | normal | Sorts and prunes the imports | `textDocument/codeAction` |
| `<leader>cc` | normal, visual | Runs the code lens on this line | `textDocument/codeLens` |
| `<leader>cC` | normal | Shows or hides code lenses | `textDocument/codeLens` |
| `<leader>cr` | normal | Renames the symbol everywhere | `textDocument/rename` |
| `<leader>cR` | normal | Renames the file and fixes the imports that name it | `workspace/didRenameFiles` or `workspace/willRenameFiles` |
| `]]` | normal | Jumps to the next use of the word under the cursor | `textDocument/documentHighlight` |
| `[[` | normal | Jumps to the previous use | `textDocument/documentHighlight` |
| `<leader>ss` | normal | Searches the file's symbols | `textDocument/documentSymbol` |
| `<leader>sS` | normal | Searches the project's symbols | `workspace/symbol` |

A server may also announce a capability after it has started, which LSP calls registering it. `setup()` wraps Neovim's handler for that message, so a key appears as soon as its capability does.

Inlay hints, the grey type and parameter names drawn inside a line, and code lenses, the clickable lines such as "3 references" drawn above a function, are both turned on for a buffer whose server supports them. `<leader>uh` (from the foundation) and `<leader>cC` turn them off.

- [ ] **Write the failing tests**

`tests/test_lsp.lua`:

```lua
-- Language servers. Every server in the table has a program to look for; a
-- file type's servers are enabled once each and only when installed; a
-- server's buffer gets exactly the keys its capabilities allow, each with an
-- icon, plus inlay hints and code lenses; a capability registered later adds
-- its key; the pickers the keys open exist; and SchemaStore, the per-server
-- settings, the diagnostic signs and lazydev all reach their places. The
-- buffer tests talk to a fake server inside this Neovim, so no program runs.
local I = require("ach.icons")

-- Replaces fields for the length of body, then puts every one back and
-- clears ach.lsp's state, even when body fails. Each stub is
-- { table, key, value }.
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
  require("ach.lsp").reset()
  if not ok then
    error(err, 0)
  end
end

-- A server that runs inside this Neovim. It answers initialize with the
-- given capabilities and ignores every other request.
local function fake(capabilities)
  return function(dispatchers)
    local closing, id = false, 0
    return {
      request = function(method, _, callback)
        id = id + 1
        if method == "initialize" then
          callback(nil, { capabilities = capabilities })
        elseif method == "shutdown" then
          callback(nil, vim.NIL)
        end
        return true, id
      end,
      notify = function(method)
        if method == "exit" then
          closing = true
          dispatchers.on_exit(0, 15)
        end
        return true
      end,
      is_closing = function()
        return closing
      end,
      terminate = function()
        if not closing then
          closing = true
          dispatchers.on_exit(0, 15)
        end
      end,
    }
  end
end

-- The descriptions of a buffer's own keys, in normal, visual and insert mode.
local function descs(buf)
  local out = {}
  for _, mode in ipairs({ "n", "x", "i" }) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      if map.desc then
        out[map.desc] = true
      end
    end
  end
  return out
end

-- Opens a new file, starts a fake server on it and waits for its keys.
local function attach(t, name, capabilities)
  local dir = t.tmpdir()
  local path = dir .. "/sample.txt"
  vim.fn.writefile({ "one two one" }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local id = vim.lsp.start({ name = name, cmd = fake(capabilities), root_dir = dir }, { bufnr = buf })
  t.ok(id, "the fake server started")
  vim.wait(2000, function()
    return descs(buf)["Lsp Info"] ~= nil
  end)
  return buf, vim.lsp.get_client_by_id(id)
end

local function detach(buf, client)
  local id = client.id
  client:stop(true)
  vim.wait(2000, function()
    return vim.lsp.get_client_by_id(id) == nil
  end)
  vim.api.nvim_buf_delete(buf, { force = true })
end

local function sorted_keys(t)
  local out = vim.tbl_keys(t)
  table.sort(out)
  return out
end

return {
  ["every server in the table has a program to look for"] = function(t)
    local lsp = require("ach.lsp")
    local missing = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      local program = lsp.program(name)
      if type(program) ~= "string" or program == "" then
        missing[#missing + 1] = name
      end
    end
    table.sort(missing)
    t.eq(missing, {}, "servers with no program")
  end,

  ["a program is listed exactly where the command is built by a function"] = function(t)
    local want = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      local config = vim.lsp.config[name]
      if config and type(config.cmd) == "function" then
        want[#want + 1] = name
      end
    end
    table.sort(want)
    t.eq(sorted_keys(require("ach.servers").programs), want)
  end,

  ["every server with settings is one the table names"] = function(t)
    local known = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      known[name] = true
    end
    local stray = {}
    for name in pairs(require("ach.servers").settings) do
      if not known[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "settings for servers the table does not name")
  end,

  ["a file type's servers are enabled once each, when their programs are installed"] = function(t)
    local lsp = require("ach.lsp")
    local installed = { dockerls = "true" }
    local enabled = {}
    with({
      { lsp, "program", function(name)
        return installed[name] or "ach-no-such-program"
      end },
      { lsp, "capabilities", function()
        return {}
      end },
      { vim.lsp, "enable", function(name)
        enabled[#enabled + 1] = name
      end },
    }, function()
      lsp.enable_for("dockerfile")
      lsp.enable_for("dockerfile")
      t.eq(enabled, { "dockerls" }, "after two Dockerfiles")
      installed.docker_compose_language_service = "true"
      lsp.enable_for("yaml.docker-compose")
      t.eq(enabled, { "dockerls", "docker_compose_language_service" }, "after the compose server installs")
    end)
  end,

  ["a server's buffer gets the keys its capabilities allow, each with an icon"] = function(t)
    local buf, client = attach(t, "ach-fake-keys", {
      definitionProvider = true,
      hoverProvider = true,
      codeActionProvider = true,
      codeLensProvider = { resolveProvider = false },
      documentHighlightProvider = true,
      inlayHintProvider = true,
    })
    local ok, err = pcall(function()
      local got = descs(buf)
      local absent = {}
      for _, desc in ipairs({
        "Lsp Info", "Goto Definition", "Hover", "Code Action", "Source Action", "Organize Imports",
        "Run Codelens", "Toggle Codelens", "Next Reference", "Prev Reference",
      }) do
        if not got[desc] then
          absent[#absent + 1] = desc
        end
      end
      t.eq(absent, {}, "keys the capabilities allow but the buffer lacks")
      local extra = {}
      for _, desc in ipairs({ "Rename", "Rename File", "References", "Goto Declaration", "LSP Workspace Symbols" }) do
        if got[desc] then
          extra[#extra + 1] = desc
        end
      end
      t.eq(extra, {}, "keys set without their capability")
      local plain = {}
      for desc in pairs(got) do
        if not I.key(desc) then
          plain[#plain + 1] = desc
        end
      end
      table.sort(plain)
      t.eq(plain, {}, "buffer keys with no icon")
      t.ok(vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), "inlay hints are on")
      t.ok(vim.lsp.codelens.is_enabled({ bufnr = buf }), "code lenses are on")
    end)
    detach(buf, client)
    if not ok then
      error(err, 0)
    end
  end,

  ["a capability the server registers later adds its key"] = function(t)
    local buf, client = attach(t, "ach-fake-later", { hoverProvider = true })
    local ok, err = pcall(function()
      t.ok(not descs(buf)["Rename"], "Rename before the server registers it")
      vim.lsp.handlers["client/registerCapability"](
        nil,
        { registrations = { { id = "ach-rename", method = "textDocument/rename" } } },
        { client_id = client.id, method = "client/registerCapability" }
      )
      t.ok(descs(buf)["Rename"], "Rename once the server registers it")
    end)
    detach(buf, client)
    if not ok then
      error(err, 0)
    end
  end,

  ["every key opens a picker that exists and has an icon of its own"] = function(t)
    local lsp = require("ach.lsp")
    local sources = require("snacks.picker.config.sources")
    local unknown, plain = {}, {}
    for _, name in ipairs(lsp.pickers) do
      if not sources[name] then
        unknown[#unknown + 1] = name
      end
    end
    for _, key in ipairs(lsp.keys) do
      if not I.key(key.desc) then
        plain[#plain + 1] = key.desc
      end
    end
    t.ok(#lsp.pickers >= 10, "the keys open at least ten pickers")
    t.eq(unknown, {}, "pickers snacks does not have")
    t.eq(plain, {}, "keys with no icon")
  end,

  ["JSON and YAML servers get SchemaStore's catalogue"] = function(t)
    for _, case in ipairs({ { "jsonls", "json" }, { "yamlls", "yaml" } }) do
      local config = vim.deepcopy(vim.lsp.config[case[1]])
      config.before_init({}, config)
      local schemas = config.settings[case[2]].schemas
      t.ok(type(schemas) == "table" and vim.tbl_count(schemas) > 100, case[1] .. " has SchemaStore's schemas")
    end
    t.eq(vim.lsp.config.yamlls.settings.yaml.schemaStore.enable, false, "yamlls' own download of the catalogue")
  end,

  ["each server's own settings reach its configuration"] = function(t)
    local client = { server_capabilities = { hoverProvider = true } }
    vim.lsp.config.ruff.on_init(client)
    t.eq(client.server_capabilities.hoverProvider, false, "ruff leaves hover to basedpyright")
    t.ok(vim.tbl_contains(vim.lsp.config.clangd.cmd, "--clang-tidy"), "clangd runs clang-tidy")
    t.eq(type(vim.lsp.config.julials.cmd), "function", "julials' command")
    t.ok(vim.endswith(vim.lsp.config.powershell_es.bundle_path, "/mason/packages/powershell-editor-services"), "PowerShell's bundle")
    t.ok(vim.tbl_contains(vim.lsp.config.vtsls.filetypes, "vue"), "vtsls serves Vue files")
    local plugin = vim.lsp.config.vtsls.settings.vtsls.tsserver.globalPlugins[1]
    t.eq(plugin.name, "@vue/typescript-plugin", "the Vue plugin")
    t.ok(vim.endswith(plugin.location, "/vue-language-server/node_modules/@vue/language-server"), "the Vue plugin's location")
    t.eq(vim.lsp.config.gopls.settings.gopls.gofumpt, true, "gopls formats with gofumpt")
  end,

  ["diagnostics draw with the icon database's glyphs"] = function(t)
    local config = vim.diagnostic.config()
    local severity = vim.diagnostic.severity
    t.eq(config.signs.text, {
      [severity.ERROR] = I.diagnostics.Error,
      [severity.WARN] = I.diagnostics.Warn,
      [severity.INFO] = I.diagnostics.Info,
      [severity.HINT] = I.diagnostics.Hint,
    }, "the signs")
    t.eq(config.virtual_text.prefix({ severity = severity.WARN }), I.diagnostics.Warn, "the inline prefix")
    t.eq({ config.severity_sort, config.update_in_insert }, { true, false }, "severity_sort and update_in_insert")
  end,

  ["Lua files complete from lazydev"] = function(t)
    require("lazy").load({ plugins = { "blink.cmp" } })
    local config = require("blink.cmp.config")
    t.ok(vim.tbl_contains(config.sources.default, "lazydev"), "lazydev is a default source")
    for _, source in ipairs({ "lsp", "path", "snippets", "buffer" }) do
      t.ok(vim.tbl_contains(config.sources.default, source), source .. " is still a default source")
    end
    t.eq(config.sources.providers.lazydev.module, "lazydev.integrations.blink", "lazydev's provider")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_lsp`
Expected: `0 passed, 11 failed, 0 need a person, 0 skipped`, exit 1. Five fail on `module 'ach.lsp' not found` or `module 'ach.servers' not found`. The two buffer tests wait two seconds each for keys that never come, then fail on `keys the capabilities allow but the buffer lacks` and `Rename once the server registers it`. The SchemaStore and settings tests fail on `attempt to index local 'config' (a nil value)` and `attempt to index field 'ruff' (a nil value)`, because Neovim resolves a server it has no file for to `nil` and nvim-lspconfig is not installed yet. The diagnostics test fails on `attempt to index field 'signs' (a boolean value)`, Neovim's default, and the lazydev test on `lazydev is a default source`.

- [ ] **Write the per-server facts**

`lua/ach/servers.lua`:

```lua
-- Per-server facts the language table does not hold. programs names the
-- program a server runs where nvim-lspconfig builds its command in a
-- function, so lsp.lua can tell whether the server is installed before it
-- enables it. settings goes to vim.lsp.config() and is merged over
-- nvim-lspconfig's own file for that server.
local M = {}

M.programs = {
  angularls = "ngserver",
  astro = "astro-ls",
  csharp_ls = "csharp-ls",
  cssls = "vscode-css-language-server",
  eslint = "vscode-eslint-language-server",
  html = "vscode-html-language-server",
  jsonls = "vscode-json-language-server",
  julials = "julia-lsp",
  powershell_es = "pwsh",
  ruby_lsp = "ruby-lsp",
  svelte = "svelteserver",
  tailwindcss = "tailwindcss-language-server",
  yamlls = "yaml-language-server",
}

local mason = vim.fn.stdpath("data") .. "/mason/packages"

local typescript = {
  updateImportsOnFileMove = { enabled = "always" },
  suggest = { completeFunctionCalls = true },
  inlayHints = {
    enumMemberValues = { enabled = true },
    functionLikeReturnTypes = { enabled = true },
    parameterNames = { enabled = "literals" },
    parameterTypes = { enabled = true },
    propertyDeclarationTypes = { enabled = true },
    variableTypes = { enabled = false },
  },
}

M.settings = {
  lua_ls = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        codeLens = { enable = true },
        completion = { callSnippet = "Replace" },
        doc = { privateName = { "^_" } },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },

  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
    },
    init_options = { usePlaceholders = true, completeUnimported = true, clangdFileStatus = true },
  },

  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        codelenses = {
          generate = true,
          regenerate_cgo = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
          vulncheck = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = { nilness = true, unusedparams = true, unusedwrite = true },
        usePlaceholders = true,
        staticcheck = true,
        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
        semanticTokens = true,
      },
    },
  },

  -- basedpyright's default mode reports far more than most code is written
  -- for; "standard" matches what pyright checks.
  basedpyright = {
    settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
  },

  -- Ruff's hover only explains its own rule codes, and two hovers in one
  -- window bury basedpyright's, which documents the code itself.
  ruff = {
    init_options = { settings = { logLevel = "error" } },
    on_init = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  },

  -- vtsls also serves Vue files, through Vue's TypeScript plugin, which Mason
  -- installs inside the Vue server's package.
  vtsls = {
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
      "vue",
    },
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          maxInlayHintLength = 30,
          completion = { enableServerSideFuzzyMatch = true },
        },
        tsserver = {
          globalPlugins = {
            {
              name = "@vue/typescript-plugin",
              location = mason .. "/vue-language-server/node_modules/@vue/language-server",
              languages = { "vue" },
              configNamespace = "typescript",
              enableForWorkspaceTypeScriptVersions = true,
            },
          },
        },
      },
      typescript = typescript,
      javascript = vim.deepcopy(typescript),
    },
  },

  -- SchemaStore's catalogue, read when the server starts rather than when
  -- this file loads, so opening a Lua file never pays for it.
  jsonls = {
    before_init = function(_, config)
      config.settings.json.schemas = config.settings.json.schemas or {}
      vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = { json = { format = { enable = true }, validate = { enable = true } } },
  },

  yamlls = {
    before_init = function(_, config)
      config.settings.yaml.schemas =
        vim.tbl_deep_extend("force", config.settings.yaml.schemas or {}, require("schemastore").yaml.schemas())
    end,
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        keyOrdering = false,
        format = { enable = true },
        validate = true,
        -- SchemaStore.nvim supplies the catalogue; yamlls' own download is off.
        schemaStore = { enable = false, url = "" },
      },
    },
  },

  powershell_es = {
    bundle_path = mason .. "/powershell-editor-services",
  },

  -- Mason's julia-lsp takes the Julia environment to load as its one
  -- argument; nvim-lspconfig's command runs julia directly instead.
  julials = {
    cmd = function(dispatchers, config)
      local root = (config and config.root_dir) or vim.fn.getcwd()
      return vim.lsp.rpc.start({ "julia-lsp", root }, dispatchers)
    end,
  },
}

return M
```

- [ ] **Write the server engine**

`lua/ach/lsp.lua`:

```lua
-- Language servers: what the client tells a server it can do, how
-- diagnostics are drawn, the keys a server's buffer gets, and enabling a
-- file type's servers once their programs are installed.
local M = {}

local I = require("ach.icons")

-- Every picker a key opens, collected as the keys are defined, so a test can
-- check that snacks has each one.
M.pickers = {}

local function picker(name)
  M.pickers[#M.pickers + 1] = name
  return function()
    Snacks.picker.pick(name)
  end
end

-- Each key is set on a buffer only when one of its servers supports the
-- method in has, or one of the methods when has is a list. A key with no has
-- is set for any server.
M.keys = {
  { "<leader>cl", picker("lsp_config"), desc = "Lsp Info" },
  { "gd", picker("lsp_definitions"), desc = "Goto Definition", has = "textDocument/definition" },
  { "gD", picker("lsp_declarations"), desc = "Goto Declaration", has = "textDocument/declaration" },
  { "grr", picker("lsp_references"), desc = "References", has = "textDocument/references" },
  { "gri", picker("lsp_implementations"), desc = "Goto Implementation", has = "textDocument/implementation" },
  { "grt", picker("lsp_type_definitions"), desc = "Goto Type Definition", has = "textDocument/typeDefinition" },
  { "gai", picker("lsp_incoming_calls"), desc = "Incoming Calls", has = "callHierarchy/incomingCalls" },
  { "gao", picker("lsp_outgoing_calls"), desc = "Outgoing Calls", has = "callHierarchy/outgoingCalls" },
  {
    "K",
    function()
      vim.lsp.buf.hover()
    end,
    desc = "Hover",
    has = "textDocument/hover",
  },
  {
    "gK",
    function()
      vim.lsp.buf.signature_help()
    end,
    desc = "Signature Help",
    has = "textDocument/signatureHelp",
  },
  {
    "<leader>ca",
    function()
      vim.lsp.buf.code_action()
    end,
    desc = "Code Action",
    mode = { "n", "x" },
    has = "textDocument/codeAction",
  },
  {
    "<leader>cA",
    function()
      vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
    end,
    desc = "Source Action",
    has = "textDocument/codeAction",
  },
  {
    "<leader>co",
    function()
      vim.lsp.buf.code_action({ apply = true, context = { only = { "source.organizeImports" }, diagnostics = {} } })
    end,
    desc = "Organize Imports",
    has = "textDocument/codeAction",
  },
  {
    "<leader>cc",
    function()
      vim.lsp.codelens.run()
    end,
    desc = "Run Codelens",
    mode = { "n", "x" },
    has = "textDocument/codeLens",
  },
  {
    "<leader>cC",
    function()
      local filter = { bufnr = vim.api.nvim_get_current_buf() }
      vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled(filter), filter)
    end,
    desc = "Toggle Codelens",
    has = "textDocument/codeLens",
  },
  {
    "<leader>cr",
    function()
      vim.lsp.buf.rename()
    end,
    desc = "Rename",
    has = "textDocument/rename",
  },
  {
    "<leader>cR",
    function()
      Snacks.rename.rename_file()
    end,
    desc = "Rename File",
    has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
  },
  {
    "]]",
    function()
      Snacks.words.jump(vim.v.count1)
    end,
    desc = "Next Reference",
    has = "textDocument/documentHighlight",
  },
  {
    "[[",
    function()
      Snacks.words.jump(-vim.v.count1)
    end,
    desc = "Prev Reference",
    has = "textDocument/documentHighlight",
  },
  { "<leader>ss", picker("lsp_symbols"), desc = "LSP Symbols", has = "textDocument/documentSymbol" },
  { "<leader>sS", picker("lsp_workspace_symbols"), desc = "LSP Workspace Symbols", has = "workspace/symbol" },
}

local function supports(client, has, buf)
  if not has then
    return true
  end
  for _, method in ipairs(type(has) == "table" and has or { has }) do
    if client:supports_method(method, buf) then
      return true
    end
  end
  return false
end

-- Sets the keys this client allows on buf and turns on inlay hints and code
-- lenses where it draws them. Running it again for the same buffer is
-- harmless, which is what lets a capability registered later add its key.
function M.attach(buf, client)
  for _, key in ipairs(M.keys) do
    if supports(client, key.has, buf) then
      vim.keymap.set(key.mode or "n", key[1], key[2], { buf = buf, desc = key.desc })
    end
  end
  if vim.bo[buf].buftype == "" and client:supports_method("textDocument/inlayHint", buf) then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end
  if client:supports_method("textDocument/codeLens", buf) then
    vim.lsp.codelens.enable(true, { bufnr = buf })
  end
end

local names = {
  [vim.diagnostic.severity.ERROR] = "Error",
  [vim.diagnostic.severity.WARN] = "Warn",
  [vim.diagnostic.severity.INFO] = "Info",
  [vim.diagnostic.severity.HINT] = "Hint",
}

function M.diagnostics()
  local text = {}
  for severity, name in pairs(names) do
    text[severity] = I.diagnostics[name]
  end
  return {
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = function(diagnostic)
        return I.diagnostics[names[diagnostic.severity]]
      end,
    },
    signs = { text = text },
    float = { source = "if_many" },
  }
end

-- blink's completion capabilities, plus file renames, which a server only
-- offers to a client that says it can send them.
function M.capabilities()
  return vim.tbl_deep_extend("force", require("blink.cmp").get_lsp_capabilities(), {
    workspace = { fileOperations = { didRename = true, willRename = true } },
  })
end

-- The program a server runs, or nil when neither servers.programs nor
-- nvim-lspconfig's command names one.
function M.program(name)
  local listed = require("ach.servers").programs[name]
  if listed then
    return listed
  end
  local config = vim.lsp.config[name]
  local cmd = config and config.cmd
  return type(cmd) == "table" and cmd[1] or nil
end

local enabled, configured = {}, false

-- Enables each of the file type's servers whose program is on the path, once
-- per session. A server that is missing now is tried again on the next file
-- of its language, which is when the installer has had another go. The
-- capabilities are set before the first server starts; they load blink.cmp,
-- which would otherwise wait for the first InsertEnter.
function M.enable_for(ft)
  if not configured then
    vim.lsp.config("*", { capabilities = M.capabilities() })
    configured = true
  end
  for _, name in ipairs(require("ach.lang").servers_for_ft(ft)) do
    if not enabled[name] then
      local program = M.program(name)
      if program and vim.fn.executable(program) == 1 then
        enabled[name] = true
        vim.lsp.enable(name)
      end
    end
  end
end

function M.reset()
  enabled, configured = {}, false
end

local did_setup = false

function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  vim.diagnostic.config(M.diagnostics())
  for name, settings in pairs(require("ach.servers").settings) do
    vim.lsp.config(name, settings)
  end
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ach_lsp", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        M.attach(ev.buf, client)
      end
    end,
  })
  local register = vim.lsp.handlers["client/registerCapability"]
  vim.lsp.handlers["client/registerCapability"] = function(err, result, ctx)
    local ret = register(err, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then
      for buf in pairs(client.attached_buffers) do
        M.attach(buf, client)
      end
    end
    return ret
  end
end

return M
```

`enable_for` is called only from `install.ready`, which a dry run never reaches, so the regular suite starts no real server. The test that calls it replaces `capabilities`, so it does not load blink.cmp either.

- [ ] **Write the plugin specs**

`lua/ach/plugins/lsp.lua`:

```lua
-- nvim-lspconfig supplies each server's command, file types and root
-- markers; SchemaStore.nvim the JSON and YAML schema catalogue; lazydev.nvim
-- the types of Neovim's API, snacks and lazy.nvim when editing this
-- configuration, as a completion source.
return {
  {
    "neovim/nvim-lspconfig",
    -- Not lazy: its lsp/ folder must be on the runtime path before the first
    -- server is enabled, which happens during startup when a file is named on
    -- the command line. Loading it runs one small plugin file.
    lazy = false,
    config = function()
      require("ach.lsp").setup()
    end,
  },

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        "lazy.nvim",
      },
    },
  },

  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lazydev" },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
    },
  },
}
```

The blink spec adds to the foundation's rather than replacing it: lazy.nvim merges the two, and `opts_extend = { "sources.default" }` appends `"lazydev"` to the four sources already listed. lazydev's own source reports itself enabled only in a Lua buffer it has attached to, so other file types never see it.

- [ ] **Hand each installed buffer to the servers**

In `lua/ach/install.lua`, replace the `M.ready` stub and its comment:

```lua
-- Called once a buffer's packages are installed, or have failed. The
-- language-server task fills this in; until then a buffer gets Tree-sitter
-- and nothing more.
function M.ready(buf, ft, entry) end
```

with:

```lua
-- Called once a buffer's packages are installed, or have failed: enables the
-- file type's servers whose programs are now on the path. The
-- managed-languages task adds the languages whose own plugin starts the
-- server.
function M.ready(buf, ft, entry)
  require("ach.lsp").enable_for(ft)
end
```

Harper is in `servers_for_ft` for every file type it checks, so this also enables it, with nvim-lspconfig's own list of file types until the grammar task narrows it.

- [ ] **Give the glyphs and keys their icons**

In `lua/ach/icons.lua`, add these five lines to `M.code`, directly below `benchmark = "\u{F051B}", -- md-timer_outline`:

```lua
  calls_in = "\u{F00FA}", -- md-call_received
  calls_out = "\u{F00F7}", -- md-call_made
  source_action = "\u{F1801}", -- md-lightbulb_auto_outline
  organize_imports = "\u{F05BD}", -- md-sort_alphabetical_ascending
  rename_file = "\u{F1031}", -- md-file_move_outline
```

Then add these lines to `M.keys`, directly above `-- Keys added by later tasks go above this line.`. The last one covers the `K` Neovim sets on a server's buffer before this task's own `K` replaces it.

```lua
  ["Lsp Info"] = { "code.lsp", "purple" },
  ["Goto Definition"] = { "code.definition", "purple" },
  ["Goto Declaration"] = { "code.declaration", "purple" },
  ["References"] = { "code.references", "purple" },
  ["Goto Implementation"] = { "code.implementation", "purple" },
  ["Goto Type Definition"] = { "code.type_definition", "purple" },
  ["Incoming Calls"] = { "code.calls_in", "purple" },
  ["Outgoing Calls"] = { "code.calls_out", "purple" },
  ["Hover"] = { "code.hover", "purple" },
  ["Signature Help"] = { "code.signature", "purple" },
  ["Code Action"] = { "code.action", "purple" },
  ["Source Action"] = { "code.source_action", "purple" },
  ["Organize Imports"] = { "code.organize_imports", "purple" },
  ["Run Codelens"] = { "code.codelens", "purple" },
  ["Toggle Codelens"] = { "code.codelens", "purple" },
  ["Rename"] = { "code.rename", "purple" },
  ["Rename File"] = { "code.rename_file", "purple" },
  ["Next Reference"] = { "code.words", "purple" },
  ["Prev Reference"] = { "code.words", "purple" },
  ["LSP Symbols"] = { "code.symbols", "purple" },
  ["LSP Workspace Symbols"] = { "code.symbols", "purple" },
  ["vim.lsp.buf.hover()"] = { "code.hover", "purple" },
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones nvim-lspconfig, SchemaStore.nvim and lazydev.nvim and adds them to `lazy-lock.json`. No server is installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 11 `test_lsp` tests pass, along with every earlier test, the foundation's icon tests included: the five glyphs are Nerd Font codepoints, and each new key description is its own which-key rule. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/servers.lua lua/ach/lsp.lua lua/ach/plugins/lsp.lua tests/test_lsp.lua
git commit --only lua/ach/servers.lua lua/ach/lsp.lua lua/ach/plugins/lsp.lua lua/ach/install.lua lua/ach/icons.lua tests/test_lsp.lua lazy-lock.json -m "feat(lsp): start each language's servers once installed, with keys their capabilities allow"
```

---

### Task: Formatting

**Files:**
- Create: `lua/ach/format.lua`, `lua/ach/plugins/format.lua`
- Modify: `lua/ach/icons.lua` (one line in `M.keys`), `lazy-lock.json` (written by lazy.nvim)
- Test: `tests/test_format.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` (`formatters_by_ft()`, `is_manual(ft)`, `manual_filetypes()`); the foundation's switches `vim.g.autoformat` (true at startup) and `vim.b.autoformat`, which `<leader>uf` and `<leader>uF` flip; the status bar's `M.tools()`, which names `conform.list_formatters_to_run(buf)` once conform is loaded and either switch is not off; `require("ach.icons")` (`I.key(desc)`).
- Produces:
  - `require("ach.format")`: `timeout_ms: integer`; `slow: table<formatter, true>`; `four_wide: string[]`; `dialects: table<ft, string>`; `sqlfluff_root(dir): string|nil` and `sqlfluff_dialect(buf, dir): string|nil`, which the linting task uses so that `sqlfluff lint` runs in the same folder with the same dialect; `formatters: table<string, table>`, conform's overrides; `when(buf): "now"|"after"|nil`; `on_save(buf)` and `after_save(buf)`, conform's `format_on_save` and `format_after_save`; `formatexpr(): integer`; `opts(): table`; `setup()`; and `reset()`, which forgets the session's timeouts.
  - conform.nvim, loaded as soon as a file opens. Every prose buffer starts with `vim.b.autoformat == false`.
  - `'formatexpr'` set to `v:lua.require'ach.format'.formatexpr()`.

conform.nvim runs formatters: it sends the buffer through each program a file type names and replaces the text with what comes back, keeping the cursor where it was and the change as one step of undo. What is left for this task is deciding when a save formats, and with what arguments.

A save formats in one of three ways. Most file types format during the save, which waits at most one second. Seven formatters start a whole language runtime before they do anything: ktlint starts Java, csharpier and fantomas start .NET, sqlfluff starts Python, rubocop and erb_format start Ruby, and php_cs_fixer starts PHP. For those the file is written first, formatted in the background, then written again. A file type whose formatter runs out of its second joins them for the rest of the session, and a message says so. Finally, a save does not format at all when either switch is off, or when nothing that could format the file is installed. A file opened while its formatter is still downloading saves exactly as typed, with no message; without that check, conform warns on the first such save of every file type.

Prose is formatted only when asked. Markdown, MDX, LaTeX, BibTeX, Typst and plain text buffers start with their own switch off, so `<leader>cf` formats them and a save does not. Prettier and markdownlint rewrite list markers, emphasis and blank lines, which is welcome on request and unwelcome halfway through a paragraph. `<leader>uF` turns a buffer's switch on, and the status bar names the formatter only while it is on.

Three formatters get arguments of this configuration's own:

| Formatter | Arguments | Why |
| --- | --- | --- |
| prettier | `--config-precedence prefer-file --tab-width 4` for JavaScript, TypeScript, JSON and CSS, and nothing extra for the rest | Four spaces is the owner's indent for these four languages, where prettier's own default is two. With `prefer-file`, prettier drops both flags when the project has a `.prettierrc` or an `.editorconfig` of its own |
| shfmt | `-i 4`, unless an `.editorconfig` is found in the file's folder or above it | Four spaces. shfmt reads an `.editorconfig` only when given no formatting flag, so the flag is left off where one exists |
| sqlfluff | `format --dialect` with `ansi`, `mysql` or `oracle`, by file type; plain `format`, run from the folder holding the configuration, inside a project that configures sqlfluff | conform's own definition runs sqlfluff only inside a configured project, so a loose `.sql` file was never formatted. sqlfluff reads its configuration from the folder it runs in, which is why it runs there. `format` applies only the layout and capitalisation rules, where `fix` would also rewrite the query, for example by removing an unnecessary `CASE` |

| Key | Mode | What it does |
| --- | --- | --- |
| `<leader>cf` | normal, visual | Formats the file, or the selection, in the background, whatever the switches say |
| `<leader>cF` | normal, visual | Formats code embedded in the file, such as a fenced block in Markdown, each part with its own language's formatter |
| `gq` and a motion | normal, visual | Formats the lines the motion covers with the file type's formatter, or with its language server; where neither is installed, rewraps them to `'textwidth'` as Vim always has |

conform's own `formatexpr` does nothing at all when a file type has no formatter, which would leave `gq` dead in a commit message or a plain text file; `M.formatexpr` hands those lines back to Vim instead. `:ConformInfo` lists each formatter for the current file and whether it is installed.

- [ ] **Write the failing tests**

`tests/test_format.lua`:

```lua
-- Formatting. Every formatter the table names is one conform knows, and
-- reaches it; prettier, shfmt and sqlfluff get this configuration's
-- arguments; prose formats on save only when switched on; either switch stops
-- a save from formatting; a save runs the file type's formatter, and one not
-- installed yet lets the save through as typed and silent; a formatter that
-- runs out of time, or is known to be slow, runs after the write instead; the
-- keys have their icons; and gq rewraps where nothing formats. The buffer
-- tests use a file type of their own, achtest, whose formatter is a command
-- every Mac has, so no real formatter needs to be installed.
local I = require("ach.icons")

local opened = {}

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

-- Runs body, then wipes the buffers it opened and forgets any timeouts, even
-- when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if package.loaded["ach.format"] then
    package.loaded["ach.format"].reset()
  end
  if not ok then
    error(err, 0)
  end
end

-- A new scratch buffer, of file type ft when one is given.
local function scratch(ft)
  local buf = vim.api.nvim_create_buf(false, true)
  opened[#opened + 1] = buf
  if ft then
    vim.bo[buf].filetype = ft
  end
  return buf
end

-- Writes one line of text to a new file and opens it as an achtest buffer.
local function open(t, text)
  local path = t.tmpdir() .. "/sample.achtest"
  vim.fn.writefile({ text }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  opened[#opened + 1] = buf
  vim.bo[buf].filetype = "achtest"
  return buf, path
end

-- Gives the file type achtest one formatter, ach_test, which runs command
-- with args, for the length of body.
local function with_formatter(command, args, body)
  local conform = require("conform")
  tidy(function()
    with({
      { conform.formatters, "ach_test", { command = command, args = args } },
      { conform.formatters_by_ft, "achtest", { "ach_test" } },
    }, body)
  end)
end

-- The arguments conform would give the formatter called name for a file of
-- type ft in the folder dir. Call it inside tidy.
local function args_for(name, ft, dir)
  local buf = scratch(ft)
  local config = assert(require("conform").get_formatter_config(name, buf), "conform has no " .. name)
  local ctx = { buf = buf, filename = dir .. "/sample", dirname = dir, shiftwidth = vim.bo[buf].shiftwidth }
  if type(config.args) == "function" then
    return config.args(config, ctx)
  end
  return config.args
end

return {
  ["every formatter the table names is one conform knows"] = function(t)
    local conform = require("conform")
    local unknown, used = {}, {}
    for ft, names in pairs(require("ach.lang").formatters_by_ft()) do
      for _, name in ipairs(names) do
        used[name] = true
        if not conform.get_formatter_config(name) then
          unknown[#unknown + 1] = ft .. ": " .. name
        end
      end
    end
    table.sort(unknown)
    t.eq(unknown, {}, "formatters conform has no definition for")
    local stray = {}
    for name in pairs(require("ach.format").slow) do
      if not used[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "slow formatters no file type uses")
  end,

  ["conform has every file type's formatters"] = function(t)
    local conform = require("conform")
    local want = require("ach.lang").formatters_by_ft()
    local got = {}
    for ft in pairs(want) do
      got[ft] = conform.formatters_by_ft[ft]
    end
    t.eq(got, want)
  end,

  ["prettier indents scripts, JSON and stylesheets by four and leaves the rest alone"] = function(t)
    local fmt = require("ach.format")
    local formats = require("ach.lang").formatters_by_ft()
    tidy(function()
      local dir = t.tmpdir()
      local four = { "--config-precedence", "prefer-file", "--tab-width", "4", "--stdin-filepath", "$FILENAME" }
      for _, ft in ipairs(fmt.four_wide) do
        t.ok(vim.list_contains(formats[ft] or {}, "prettier"), ft .. " is formatted by prettier")
        t.eq(args_for("prettier", ft, dir), four, ft)
      end
      for _, ft in ipairs({ "yaml", "html", "markdown", "graphql", "vue" }) do
        t.eq(args_for("prettier", ft, dir), { "--stdin-filepath", "$FILENAME" }, ft)
      end
    end)
  end,

  ["shfmt indents by four unless an .editorconfig above the file says otherwise"] = function(t)
    tidy(function()
      t.eq(args_for("shfmt", "sh", t.tmpdir()), { "-filename", "$FILENAME", "-i", "4" }, "with no .editorconfig")
      local project = t.tmpdir()
      vim.fn.writefile({ "root = true" }, project .. "/.editorconfig")
      vim.fn.mkdir(project .. "/scripts", "p")
      t.eq(args_for("shfmt", "bash", project .. "/scripts"), { "-filename", "$FILENAME" }, "below an .editorconfig")
    end)
  end,

  ["sqlfluff is told the dialect, or runs beside the project's own configuration"] = function(t)
    local function project(file, lines)
      local dir = t.tmpdir()
      vim.fn.writefile(lines, dir .. "/" .. file)
      return dir
    end
    tidy(function()
      local loose = t.tmpdir()
      t.eq(args_for("sqlfluff", "sql", loose), { "format", "--dialect", "ansi", "-" }, "sql")
      t.eq(args_for("sqlfluff", "mysql", loose), { "format", "--dialect", "mysql", "-" }, "mysql")
      t.eq(args_for("sqlfluff", "plsql", loose), { "format", "--dialect", "oracle", "-" }, "plsql")
      local own = project(".sqlfluff", { "[sqlfluff]", "dialect = postgres" })
      t.eq(args_for("sqlfluff", "sql", own), { "format", "-" }, "beside a .sqlfluff")
      local py = project("pyproject.toml", { "[tool.sqlfluff.core]", 'dialect = "bigquery"' })
      t.eq(args_for("sqlfluff", "sql", py), { "format", "-" }, "beside a pyproject.toml with a sqlfluff section")
      local other = project("pyproject.toml", { "[tool.ruff]", "line-length = 100" })
      t.eq(args_for("sqlfluff", "sql", other), { "format", "--dialect", "ansi", "-" }, "beside one without")
      local config = require("conform").get_formatter_config("sqlfluff")
      t.eq(config.require_cwd, false, "runs outside a configured project")
      vim.fn.mkdir(own .. "/queries", "p")
      t.eq(config.cwd(config, { dirname = own .. "/queries" }), own, "the folder it runs in, below a .sqlfluff")
      t.eq(config.cwd(config, { dirname = other }), nil, "the folder it runs in, outside a configured project")
    end)
  end,

  ["prose formats on save only when switched on"] = function(t)
    tidy(function()
      local on = {}
      for _, ft in ipairs(require("ach.lang").manual_filetypes()) do
        if vim.b[scratch(ft)].autoformat ~= false then
          on[#on + 1] = ft
        end
      end
      t.eq(on, {}, "prose file types that would format on save")
      t.eq(vim.b[scratch("python")].autoformat, nil, "a python buffer's switch")
      local became = scratch("markdown")
      vim.bo[became].filetype = "python"
      t.eq(vim.b[became].autoformat, nil, "a markdown buffer that became python")
      local mine = scratch("python")
      vim.b[mine].autoformat = true
      vim.bo[mine].filetype = "markdown"
      t.eq(vim.b[mine].autoformat, true, "a buffer switched on by hand that became markdown")
    end)
  end,

  ["either switch stops a save from formatting"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      local buf, path = open(t, "hello")
      t.eq(fmt.when(buf), "now", "with both switches on")
      with({ { vim.g, "autoformat", false } }, function()
        t.eq(fmt.when(buf), nil, "with the global switch off")
      end)
      with({ { vim.b[buf], "autoformat", false } }, function()
        t.eq(fmt.when(buf), nil, "with the buffer's switch off")
        vim.cmd.write()
        t.eq(vim.fn.readfile(path), { "hello" }, "the file, saved with the buffer's switch off")
      end)
    end)
  end,

  ["a save runs the file type's formatter"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local buf, path = open(t, "hello")
      vim.cmd.write()
      t.eq(vim.fn.readfile(path), { "HELLO" }, "the file on disk")
      t.eq(vim.bo[buf].modified, false, "the buffer is saved")
    end)
  end,

  ["a save before the formatter is installed writes the file as typed and says nothing"] = function(t)
    with_formatter("ach-formatter-not-installed-yet", {}, function()
      local notes = {}
      local function note(msg, level)
        notes[#notes + 1] = { msg, level }
      end
      with({ { vim, "notify", note } }, function()
        local buf, path = open(t, "hello")
        vim.v.errmsg = ""
        vim.cmd.write()
        vim.wait(200) -- conform sends its messages on the next turn of the event loop
        t.eq(vim.fn.readfile(path), { "hello" }, "the file on disk")
        t.eq(vim.bo[buf].modified, false, "the buffer is saved")
        t.eq(vim.v.errmsg, "", "the last error message")
        t.eq(notes, {}, "messages")
        require("conform").format({ bufnr = buf })
        vim.wait(200)
        t.ok(#notes > 0, "conform warns when asked outright, so the save's silence is this configuration's doing")
      end)
    end)
  end,

  ["a formatter that runs out of time formats after the write from then on"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      local buf = open(t, "hello")
      local opts, done = fmt.on_save(buf)
      t.eq(opts, { timeout_ms = fmt.timeout_ms, lsp_format = "fallback" }, "the save's options")
      done(nil)
      done("Formatter 'ach_test' exited with code 2")
      t.eq(fmt.when(buf), "now", "after a success and a failure")
      local notes = {}
      local function note(msg)
        notes[#notes + 1] = msg
      end
      with({ { vim, "notify", note } }, function()
        done("Formatter 'ach_test' timeout")
      end)
      t.eq(notes, { "achtest files format after each save from now on" }, "the message")
      t.eq(fmt.when(buf), "after", "after a timeout")
      t.eq(fmt.on_save(buf), nil, "the save's options")
      t.eq(fmt.after_save(buf), { lsp_format = "fallback" }, "the options after the save")
    end)
  end,

  ["formatters known to be slow run after the write"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      with({ { fmt.slow, "ach_test", true } }, function()
        local buf, path = open(t, "hello")
        t.eq(fmt.when(buf), "after", "when it runs")
        t.eq(fmt.on_save(buf), nil, "the save's options")
        vim.cmd.write()
        t.eq(vim.fn.readfile(path), { "hello" }, "the file as the save wrote it")
        local formatted = vim.wait(3000, function()
          return vim.fn.readfile(path)[1] == "HELLO"
        end)
        t.ok(formatted, "the file is written again, formatted")
        t.eq(vim.bo[buf].modified, false, "the buffer is saved")
      end)
    end)
  end,

  ["the format keys are mapped, each with an icon"] = function(t)
    local keys = { ["<leader>cf"] = "Format", ["<leader>cF"] = "Format Injected Langs" }
    for lhs, desc in pairs(keys) do
      for _, mode in ipairs({ "n", "x" }) do
        t.eq(vim.fn.maparg(lhs, mode, false, true).desc, desc, lhs .. " in mode " .. mode)
      end
      t.ok(I.key(desc), desc .. " has an icon")
    end
  end,

  ["gq formats with the file type's formatter, and rewraps where there is none"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local buf = open(t, "one two three four")
      vim.cmd("normal! gqq")
      t.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "ONE TWO THREE FOUR" }, "with a formatter")
      local plain = scratch()
      vim.api.nvim_set_current_buf(plain)
      vim.bo[plain].textwidth = 10
      vim.api.nvim_buf_set_lines(plain, 0, -1, false, { "one two three four" })
      vim.cmd("normal! gqq")
      t.eq(vim.api.nvim_buf_get_lines(plain, 0, -1, false), { "one two", "three four" }, "with none")
    end)
  end,
}
```

The save test is the review-focus case: `ach-formatter-not-installed-yet` stands for a formatter whose package is still downloading, since conform judges both the same way, by whether the command is on the path. Its last two lines prove the test is not passing by accident: asked to format outright, conform does warn, so the silence during the save comes from `on_save` declining to format. conform warns once per file type per session, and no other test asks it to format an achtest buffer with nothing installed.

The slow-formatter test can read the file straight after `:write` and see it unformatted, because the background format can only finish when the test yields to the event loop, which `vim.wait` does on the next line.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_format`
Expected: `0 passed, 13 failed, 0 need a person, 0 skipped`, exit 1. Eleven fail on `module 'conform' not found` or `module 'ach.format' not found`. The prose test fails on `prose file types that would format on save`, listing all seven, and the key test on `<leader>cf in mode n` or `<leader>cF in mode n`, whichever `pairs` visits first, with no mapping behind it yet.

- [ ] **Write the formatting rules**

`lua/ach/format.lua`:

```lua
-- Formatting. conform.nvim runs the formatters; this module decides which
-- run, with what arguments, and when: during a save, after it, or not at all.
local M = {}

-- How long a save waits for its formatters before writing the file as typed.
M.timeout_ms = 1000

-- Formatters that start a Java, .NET, Python, Ruby or PHP runtime, too slow
-- for a save to wait on. They run once the file is written, and the buffer is
-- written again with their changes.
M.slow = {
  ktlint = true,
  csharpier = true,
  fantomas = true,
  sqlfluff = true,
  rubocop = true,
  erb_format = true,
  php_cs_fixer = true,
}

-- File types prettier indents by four spaces rather than its default of two.
M.four_wide = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "json",
  "jsonc",
  "json5",
  "css",
  "scss",
  "less",
}

-- sqlfluff's dialect for each SQL file type, used where the project names none.
M.dialects = { sql = "ansi", mysql = "mysql", plsql = "oracle" }

local sqlfluff_files = { ".sqlfluff", "pyproject.toml", "setup.cfg", "tox.ini", "pep8.ini" }

-- File types whose formatters ran out of time this session.
local timed_out = {}

-- The folder holding the sqlfluff configuration nearest to dir, at dir or
-- above it: a .sqlfluff, or a pyproject.toml, setup.cfg, tox.ini or pep8.ini
-- with a sqlfluff section. nil when there is none.
function M.sqlfluff_root(dir)
  for _, path in ipairs(vim.fs.find(sqlfluff_files, { path = dir, upward = true, limit = math.huge })) do
    local configures = vim.fs.basename(path) == ".sqlfluff"
    if not configures then
      local f = io.open(path)
      if f then
        local text = f:read("*a")
        f:close()
        configures = text:find("[sqlfluff", 1, true) ~= nil or text:find("[tool.sqlfluff", 1, true) ~= nil
      end
    end
    if configures then
      return vim.fs.dirname(path)
    end
  end
  return nil
end

-- The dialect to give sqlfluff for this buffer, or nil inside a project that
-- configures sqlfluff, whose configuration names the dialect.
function M.sqlfluff_dialect(buf, dir)
  if M.sqlfluff_root(dir) then
    return nil
  end
  return M.dialects[vim.bo[buf].filetype] or "ansi"
end

-- Changes merged over conform's own definitions of these formatters.
M.formatters = {
  -- prefer-file: prettier drops both flags when the project has a
  -- configuration of its own, an .editorconfig included.
  prettier = {
    prepend_args = function(_, ctx)
      if vim.list_contains(M.four_wide, vim.bo[ctx.buf].filetype) then
        return { "--config-precedence", "prefer-file", "--tab-width", "4" }
      end
      return {}
    end,
  },
  -- shfmt reads an .editorconfig only when given no formatting flag, so -i is
  -- left off wherever one is found.
  shfmt = {
    args = function(_, ctx)
      local args = { "-filename", "$FILENAME" }
      if not vim.fs.find(".editorconfig", { path = ctx.dirname, upward = true })[1] then
        vim.list_extend(args, { "-i", "4" })
      end
      return args
    end,
  },
  -- format applies only the layout and capitalisation rules. conform's own
  -- definition runs fix, and only inside a configured project. sqlfluff reads
  -- its configuration from the folder it runs in.
  sqlfluff = {
    require_cwd = false,
    cwd = function(_, ctx)
      return M.sqlfluff_root(ctx.dirname)
    end,
    args = function(_, ctx)
      local dialect = M.sqlfluff_dialect(ctx.buf, ctx.dirname)
      if dialect then
        return { "format", "--dialect", dialect, "-" }
      end
      return { "format", "-" }
    end,
  },
  -- A code block that fails to format does not stop the others.
  injected = { options = { ignore_errors = true } },
}

-- When a save formats this buffer: "now", during the save; "after", once the
-- file is written; or nil, not at all, because a switch is off or nothing
-- that could format it is installed.
function M.when(buf)
  if vim.g.autoformat == false or vim.b[buf].autoformat == false then
    return nil
  end
  local formatters, lsp = require("conform").list_formatters_to_run(buf)
  if #formatters == 0 and not lsp then
    return nil
  end
  if timed_out[vim.bo[buf].filetype] then
    return "after"
  end
  for _, f in ipairs(formatters) do
    if M.slow[f.name] then
      return "after"
    end
  end
  return "now"
end

-- conform's format_on_save. Returning nothing lets the save through as
-- typed, which is what a file whose formatter is still installing gets, with
-- no message. A file type that runs out of time moves to after the save.
function M.on_save(buf)
  if M.when(buf) ~= "now" then
    return nil
  end
  local ft = vim.bo[buf].filetype
  return { timeout_ms = M.timeout_ms, lsp_format = "fallback" }, function(err)
    if err and err:match("timeout$") then
      timed_out[ft] = true
      vim.notify(("%s files format after each save from now on"):format(ft), vim.log.levels.INFO)
    end
  end
end

-- conform's format_after_save: formats in the background once the file is
-- written, then writes it again.
function M.after_save(buf)
  if M.when(buf) == "after" then
    return { lsp_format = "fallback" }
  end
  return nil
end

-- 'formatexpr'. gq formats with the file type's formatter or language server
-- where one is installed, and leaves the lines to Vim's own rewrapping where
-- neither is, and while typing past 'textwidth'.
function M.formatexpr()
  if vim.fn.mode():match("^[iR]") then
    return 1
  end
  local formatters, lsp = require("conform").list_formatters_to_run(0)
  if #formatters == 0 and not lsp then
    return 1
  end
  return require("conform").formatexpr()
end

-- A buffer of a prose file type starts with its switch off. One that leaves
-- prose gets the switch back, unless it was set by hand.
local function on_filetype(buf, ft)
  local manual = require("ach.lang").is_manual(ft)
  if manual and vim.b[buf].autoformat == nil then
    vim.b[buf].autoformat = false
    vim.b[buf].ach_prose_off = true
  elseif not manual and vim.b[buf].ach_prose_off then
    vim.b[buf].autoformat = nil
    vim.b[buf].ach_prose_off = nil
  end
end

-- Called from the conform spec's init, before any file is open.
function M.setup()
  vim.o.formatexpr = "v:lua.require'ach.format'.formatexpr()"
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ach_format", { clear = true }),
    callback = function(ev)
      on_filetype(ev.buf, ev.match)
    end,
  })
end

-- Forgets which file types ran out of time this session.
function M.reset()
  timed_out = {}
end

-- conform's options.
function M.opts()
  return {
    formatters_by_ft = require("ach.lang").formatters_by_ft(),
    formatters = M.formatters,
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = M.on_save,
    format_after_save = M.after_save,
  }
end

return M
```

`lsp_format = "fallback"` lets a language server format a file whose formatter is not installed, Lua with lua_ls for example, and stays out of the way once the formatter is. A file written in the background is written by conform's own `:update`, which conform marks so that its after-save hook does not run a second time; `on_save` declines the same write because `when` still answers "after".

- [ ] **Write the plugin spec**

`lua/ach/plugins/format.lua`:

```lua
-- conform.nvim runs each file type's formatters. lua/ach/format.lua decides
-- which, with what arguments, and when.
return {
  {
    "stevearc/conform.nvim",
    -- Loaded when a file opens rather than at the first save, so the status
    -- bar can name the formatter from the start.
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true })
        end,
        mode = { "n", "x" },
        desc = "Format",
      },
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, async = true })
        end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    init = function()
      require("ach.format").setup()
    end,
    opts = function()
      return require("ach.format").opts()
    end,
  },
}
```

lazy.nvim passes `opts` to `require("conform").setup`. Both keys run in the background, because conform's one-second limit applies only to a format the editor waits for, and ktlint on a large file can take longer than that. In visual mode conform formats only the selected lines.

- [ ] **Give the new key its icon**

In `lua/ach/icons.lua`, add this line to `M.keys`, directly above `-- Keys added by later tasks go above this line.`:

```lua
  ["Format Injected Langs"] = { "code.format", "purple" },
```

`<leader>cf` needs no line of its own. Its description, "Format", is already listed for which-key's `gq` operator, with `edit.format`, and one description draws one icon wherever it appears.

- [ ] **Install the plugin**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones conform.nvim and adds it to `lazy-lock.json`. No formatter is installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 13 `test_format` tests pass, along with every earlier test, the foundation's toggle and icon tests included. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/format.lua lua/ach/plugins/format.lua tests/test_format.lua
git commit --only lua/ach/format.lua lua/ach/plugins/format.lua lua/ach/icons.lua tests/test_format.lua lazy-lock.json -m "feat(format): format on save, in the background for slow formatters, and prose only on request"
```

---

### Task: Linting

**Files:**
- Create: `lua/ach/lint.lua`, `lua/ach/plugins/lint.lua`
- Modify: `lazy-lock.json` (written by lazy.nvim)
- Test: `tests/test_lint.lua`

**Interfaces:**
- Consumes: `require("ach.lang").linters_by_ft()`; `require("ach.format")` (`sqlfluff_root(dir)`, `sqlfluff_dialect(buf, dir)`); the status bar's `M.tools()`, which names `require("ach.lint").linters_for(buf)` once `ach.lint` is in `package.loaded`.
- Produces:
  - `require("ach.lint")`: `events: string[]`; `debounce_ms: integer`; `commands: table<linter, string[]>`, the programs each linter needs; `adapt: table<linter, fun(def: table, buf: integer): table>`, this configuration's changes to three upstream definitions; `linters_for(buf): string[]`; `run(buf, all: boolean)`; `schedule(buf, all: boolean)`; `setup()`.
  - nvim-lint, loaded as soon as a file opens, with `linters_by_ft` from the table.

nvim-lint runs linters: programs that read code and report problems without changing anything, such as a variable declared and never used, or a Dockerfile whose base image is pinned to `latest`. What they report appears as diagnostics, the same underlines and margin signs a language server's errors get. Most languages have no linter here, because their language server already reports the same problems; the table names one only where a separate tool finds more.

Linting runs a tenth of a second after a file opens, after each save, and after leaving insert mode. The pause makes a burst of those events, such as leaving insert mode and saving with one key, cost one run. Leaving insert mode runs only the linters that are sent the buffer's text. Four linters, cmakelint, hlint, golangci-lint and tflint, read the file on disk instead, so before a save they would report on text that is no longer there, at line numbers that no longer match; they run when the file opens and after each save. Markdown is linted like any other language: markdownlint only reports, so it has nothing to do with the switch that keeps prose from formatting on save.

A linter whose program is not installed yet is left out, silently, as a formatter is, and the status bar names only the linters that will run. A compound file type the table does not name, such as `markdown.pandoc`, gets the linters of each of its parts, which is how nvim-lint itself resolves one. Whether a linter is installed is checked by the names of its programs, listed in this module, rather than by loading its definition, because loading golangci-lint's definition runs `golangci-lint version` and `go env GOMOD`, and a definition loaded before Mason has installed golangci-lint is broken for the rest of the session.

Three linters need more than their upstream definition:

| Linter | Change | Why |
| --- | --- | --- |
| sqlfluff | `--dialect`, chosen as the formatter chooses it; run from the folder holding the project's configuration | Without a dialect sqlfluff stops before checking anything, and nvim-lint shows nothing, so a loose `.sql` file was never linted. sqlfluff reads its configuration from the folder it runs in |
| tflint | Run in the file's own folder, without `--recursive` | Upstream runs `tflint --recursive` from Neovim's working folder, which, from the home folder, means every Terraform module under it. A Terraform module is one folder |
| golangci-lint | Run from the folder holding `go.mod`, on the file's whole package | Upstream chooses between the package and the lone file once, from Neovim's working folder, when it is loaded. A file linted alone reports every name its sibling files define as undefined |

Linting has no keys. The diagnostics it produces move and list with the same keys as a language server's.

- [ ] **Write the failing tests**

`tests/test_lint.lua`:

```lua
-- Linting. Every linter the table names is one nvim-lint knows, run by the
-- program listed for it; only installed linters run, and only on files; one
-- not installed yet stays silent; linters sent the buffer's text run when
-- insert mode ends, and those that read the file wait for a save; events
-- lint after a short pause; and sqlfluff, tflint and golangci-lint get this
-- configuration's changes. The buffer tests use a file type of their own,
-- achtest, whose linters run cat, so no real linter needs to be installed.
local opened = {}

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

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- A scratch buffer named path, which nothing writes to disk.
local function named(path)
  local buf = vim.api.nvim_create_buf(false, true)
  opened[#opened + 1] = buf
  vim.api.nvim_buf_set_name(buf, path)
  return buf
end

-- Writes one line of text to a new file and opens it as an achtest buffer.
local function open(t, text)
  local path = t.tmpdir() .. "/sample.achtest"
  vim.fn.writefile({ text }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  opened[#opened + 1] = buf
  vim.bo[buf].filetype = "achtest"
  return buf, path
end

-- A linter that runs cat and reports what it read as one warning on the
-- first line: the buffer's text when stdin is true, the file on disk when not.
local function cat(stdin)
  return {
    cmd = "cat",
    stdin = stdin,
    stream = "stdout",
    parser = function(output)
      return { { lnum = 0, col = 0, message = vim.trim(output), severity = vim.diagnostic.severity.WARN } }
    end,
  }
end

-- Gives the file type achtest the linters in defs, for the length of body.
-- defs maps each name to { definition, program }.
local function with_linters(defs, body)
  local lint, L = require("lint"), require("ach.lint")
  local stubs, names = {}, {}
  for name, def in pairs(defs) do
    names[#names + 1] = name
    stubs[#stubs + 1] = { lint.linters, name, def[1] }
    stubs[#stubs + 1] = { L.commands, name, { def[2] } }
  end
  table.sort(names)
  stubs[#stubs + 1] = { lint.linters_by_ft, "achtest", names }
  tidy(function()
    with(stubs, body)
  end)
end

-- The messages of the diagnostics the linter called name has put on buf.
local function messages(buf, name)
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(buf, { namespace = require("lint").get_namespace(name) })) do
    out[#out + 1] = d.message
  end
  return out
end

return {
  ["every linter the table names is one nvim-lint knows, run by the program listed"] = function(t)
    local L = require("ach.lint")
    local bad, used = {}, {}
    for ft, names in pairs(require("ach.lang").linters_by_ft()) do
      for _, name in ipairs(names) do
        used[name] = true
        local ok, def = pcall(require, "lint.linters." .. name)
        local cmd = ok and type(def) == "table" and def.cmd or nil
        if type(cmd) == "function" then
          cmd = cmd()
        end
        local listed = L.commands[name] or {}
        if cmd == nil or cmd ~= listed[1] then
          bad[#bad + 1] = ("%s: %s runs %s, listed as %s"):format(ft, name, tostring(cmd), tostring(listed[1]))
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "linters nvim-lint has no definition for, or listed with another program")
    local stray = {}
    for name in pairs(L.commands) do
      if not used[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "listed linters no file type uses")
    for name in pairs(L.adapt) do
      t.ok(used[name], name .. " is changed here and used by a file type")
    end
  end,

  ["nvim-lint has every file type's linters"] = function(t)
    local lint = require("lint")
    local want, got = require("ach.lang").linters_by_ft(), {}
    for ft in pairs(want) do
      got[ft] = lint.linters_by_ft[ft]
    end
    t.eq(got, want)
  end,

  ["only installed linters run, and only on files"] = function(t)
    local defs = { ach_missing = { cat(true), "ach-linter-not-installed-yet" }, ach_test = { cat(true), "cat" } }
    with_linters(defs, function()
      local L = require("ach.lint")
      local file = open(t, "hello")
      t.eq(L.linters_for(file), { "ach_test" }, "a file")
      vim.bo[file].filetype = "achtest.extra"
      t.eq(L.linters_for(file), { "ach_test" }, "a compound file type the table does not name")
      local scratch = named(t.tmpdir() .. "/scratch.achtest")
      vim.bo[scratch].filetype = "achtest"
      t.eq(L.linters_for(scratch), {}, "a scratch buffer")
      local unnamed = vim.api.nvim_create_buf(true, false)
      opened[#opened + 1] = unnamed
      vim.bo[unnamed].filetype = "achtest"
      t.eq(L.linters_for(unnamed), {}, "a buffer with no file")
    end)
  end,

  ["a linter not installed yet stays silent"] = function(t)
    local missing = { cmd = "ach-linter-not-installed-yet", stdin = true, parser = function() return {} end }
    with_linters({ ach_missing = { missing, "ach-linter-not-installed-yet" } }, function()
      local notes = {}
      local function note(msg)
        notes[#notes + 1] = msg
      end
      with({ { vim, "notify", note } }, function()
        local buf = open(t, "hello")
        vim.v.errmsg = ""
        vim.cmd.write()
        vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
        vim.wait(300)
        t.eq(notes, {}, "messages")
        t.eq(vim.v.errmsg, "", "the last error message")
        require("lint").try_lint("ach_missing")
        t.ok(#notes > 0, "nvim-lint complains when asked outright, so the silence above is this configuration's doing")
      end)
    end)
  end,

  ["a linter sent the buffer's text reports on what is typed"] = function(t)
    with_linters({ ach_test = { cat(true), "cat" } }, function()
      local buf = open(t, "hello")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed, not saved" })
      require("ach.lint").run(buf, false)
      local linted = vim.wait(2000, function()
        return messages(buf, "ach_test")[1] == "typed, not saved"
      end)
      t.ok(linted, "the warning reports the unsaved text")
    end)
  end,

  ["a linter that reads the file waits for a save"] = function(t)
    with_linters({ ach_test = { cat(false), "cat" } }, function()
      local L = require("ach.lint")
      local ns = require("lint").get_namespace("ach_test")
      local buf = open(t, "hello")
      local linted = vim.wait(2000, function()
        return messages(buf, "ach_test")[1] == "hello"
      end)
      t.ok(linted, "the file is linted when it opens")
      vim.diagnostic.reset(ns, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed, not saved" })
      vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
      vim.wait(300)
      t.eq(messages(buf, "ach_test"), {}, "after leaving insert mode")
      vim.cmd.write()
      linted = vim.wait(2000, function()
        return messages(buf, "ach_test")[1] == "typed, not saved"
      end)
      t.ok(linted, "after the save, the saved text")
      vim.diagnostic.reset(ns, buf)
      L.schedule(buf, true)
      L.schedule(buf, false)
      linted = vim.wait(2000, function()
        return #messages(buf, "ach_test") > 0
      end)
      t.ok(linted, "a save followed at once by leaving insert mode")
    end)
  end,

  ["saving and leaving insert mode lint after a short pause"] = function(t)
    with_linters({ ach_test = { cat(true), "cat" } }, function()
      local buf = open(t, "hello")
      vim.wait(2000, function()
        return #messages(buf, "ach_test") > 0
      end)
      vim.diagnostic.reset(require("lint").get_namespace("ach_test"), buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "saved" })
      vim.cmd.write()
      t.eq(messages(buf, "ach_test"), {}, "straight after the save")
      local linted = vim.wait(2000, function()
        return messages(buf, "ach_test")[1] == "saved"
      end)
      t.ok(linted, "after the save")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed" })
      vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
      linted = vim.wait(2000, function()
        return messages(buf, "ach_test")[1] == "typed"
      end)
      t.ok(linted, "after leaving insert mode")
    end)
  end,

  ["sqlfluff lints in the formatter's dialect, from the folder of the project's configuration"] = function(t)
    local L = require("ach.lint")
    local upstream = require("lint.linters.sqlfluff")
    local function adapted(path, ft)
      local buf = named(path)
      vim.bo[buf].filetype = ft
      return L.adapt.sqlfluff(vim.deepcopy(upstream), buf)
    end
    tidy(function()
      local loose = t.tmpdir()
      local def = adapted(loose .. "/query.sql", "sql")
      t.eq(def.args, { "lint", "--format=json", "--dialect", "ansi", "-" }, "a loose sql file")
      t.eq(def.cwd, loose, "where a loose file is linted")
      t.eq(adapted(loose .. "/query.mysql", "mysql").args[4], "mysql", "a mysql file's dialect")
      local project = t.tmpdir()
      vim.fn.writefile({ "[sqlfluff]", "dialect = postgres" }, project .. "/.sqlfluff")
      vim.fn.mkdir(project .. "/queries", "p")
      def = adapted(project .. "/queries/report.sql", "sql")
      t.eq(def.args, { "lint", "--format=json", "-" }, "a file below a .sqlfluff")
      t.eq(def.cwd, project, "where it is linted")
      t.eq(upstream.args, { "lint", "--format=json", "-" }, "upstream's own arguments, unchanged")
    end)
  end,

  ["tflint lints the file's own module"] = function(t)
    local L = require("ach.lint")
    tidy(function()
      local module = t.tmpdir()
      local buf = named(module .. "/main.tf")
      local def = L.adapt.tflint(vim.deepcopy(require("lint.linters.tflint")), buf)
      t.eq(def.cwd, module, "where it runs")
      t.eq(def.args, { "--format=json" }, "its arguments")
      local function issue(file, rule)
        return {
          rule = { name = rule, severity = "warning", link = "https://github.com/terraform-linters/tflint" },
          message = "declared but not used",
          range = { filename = file, start = { line = 2, column = 1 }, ["end"] = { line = 2, column = 13 } },
        }
      end
      local output = vim.json.encode({ issues = { issue("main.tf", "here"), issue("variables.tf", "there") } })
      local rules = {}
      for _, d in ipairs(def.parser(output, buf, module)) do
        rules[#rules + 1] = d.message:match("%((.-)%)")
      end
      t.eq(rules, { "here" }, "the rules reported for this file")
    end)
  end,

  ["golangci-lint lints the whole package, from the module's folder"] = function(t)
    local L = require("ach.lint")
    local upstream = {
      cmd = "golangci-lint",
      args = {
        "run",
        "--issues-exit-code=0",
        function()
          return "upstream's target"
        end,
      },
    }
    tidy(function()
      local module = t.tmpdir()
      vim.fn.writefile({ "module example.com/sample", "", "go 1.23" }, module .. "/go.mod")
      vim.fn.mkdir(module .. "/server", "p")
      local def = L.adapt.golangcilint(vim.deepcopy(upstream), named(module .. "/server/handler.go"))
      t.eq(def.cwd, module, "where it runs inside a module")
      t.eq(def.args, { "run", "--issues-exit-code=0", module .. "/server" }, "its arguments inside a module")
      local loose = t.tmpdir()
      def = L.adapt.golangcilint(vim.deepcopy(upstream), named(loose .. "/main.go"))
      t.eq(def.cwd, loose, "where it runs outside a module")
      t.eq(def.args, { "run", "--issues-exit-code=0", loose .. "/main.go" }, "its arguments outside a module")
      local real = require("lint.linters.golangcilint")
      if real.args then
        t.eq(type(real.args[#real.args]), "function", "upstream's last argument, the target this replaces")
      end
    end)
  end,
}
```

The silent-linter test is the linting half of the review-focus case, and proves itself the same way the formatting one does: asked outright, nvim-lint reports the missing program, so the quiet save and the quiet return from insert mode come from `linters_for` leaving it out.

The test of a linter that reads the file clears its warnings before leaving insert mode, because otherwise a second run would report the same saved text and the test could not tell that the linter had not run. Its last three lines schedule a save and then a return from insert mode inside the same tenth of a second, and expect the file linter to run, because the later event must not narrow the run the earlier one asked for.

The golangci-lint test uses a definition of its own shape rather than the real one, because loading the real one runs `golangci-lint` and `go`, which the dry run does not install. Where golangci-lint is installed, as in `scripts/check --full`, its last line checks the one fact about the real definition the change depends on: its last argument is the function that names what to lint.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_lint`
Expected: `0 passed, 10 failed, 0 need a person, 0 skipped`, exit 1, each failing on `module 'lint' not found` or `module 'ach.lint' not found`.

- [ ] **Write the linting rules**

`lua/ach/lint.lua`:

```lua
-- Linting. nvim-lint runs the linters; this module decides which can run and
-- when, and what three of them need beyond their upstream definitions.
local M = {}

-- When linting runs. Leaving insert mode runs only the linters that are sent
-- the buffer's text; the rest read the file on disk, so they wait for a save.
M.events = { "BufReadPost", "BufWritePost", "InsertLeave" }

-- How long linting waits after an event, so a burst of events costs one run.
M.debounce_ms = 100

-- The programs each linter needs, its own first. A linter runs only once all
-- of them are installed. They are listed here rather than read from the
-- definitions because loading golangcilint's definition runs golangci-lint
-- and go, and one loaded before they are installed stays broken.
M.commands = {
  cmakelint = { "cmakelint" },
  golangcilint = { "golangci-lint", "go" },
  hadolint = { "hadolint" },
  hlint = { "hlint" },
  ktlint = { "ktlint" },
  ["markdownlint-cli2"] = { "markdownlint-cli2" },
  phpcs = { "phpcs" },
  sqlfluff = { "sqlfluff" },
  statix = { "statix" },
  tclint = { "tclint" },
  tflint = { "tflint" },
}

-- Changes to three upstream definitions. Each takes a copy of the definition
-- and the buffer about to be linted, and returns the linter to run.
M.adapt = {
  -- Without a dialect sqlfluff checks nothing, and it reads a project's
  -- configuration from the folder it runs in.
  sqlfluff = function(def, buf)
    local fmt = require("ach.format")
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    local dialect = fmt.sqlfluff_dialect(buf, dir)
    if dialect then
      table.insert(def.args, #def.args, "--dialect")
      table.insert(def.args, #def.args, dialect)
    end
    def.cwd = fmt.sqlfluff_root(dir) or dir
    return def
  end,

  -- A Terraform module is one folder. tflint names files relative to the
  -- folder it runs in, and upstream matches them against the buffer's name
  -- relative to Neovim's, so each name is rewritten before it is matched.
  tflint = function(def, buf)
    def.cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    def.args = vim.tbl_filter(function(arg)
      return arg ~= "--recursive"
    end, def.args)
    local parse = def.parser
    def.parser = function(output, bufnr, cwd)
      local ok, decoded = pcall(vim.json.decode, output)
      if ok and type(decoded) == "table" and type(decoded.issues) == "table" then
        for _, issue in ipairs(decoded.issues) do
          local file = type(issue.range) == "table" and issue.range.filename or nil
          if type(file) == "string" and file:sub(1, 1) ~= "/" then
            issue.range.filename = vim.fn.fnamemodify(vim.fs.joinpath(cwd, file), ":.")
          end
        end
        output = vim.json.encode(decoded)
      end
      return parse(output, bufnr, cwd)
    end
    return def
  end,

  -- golangci-lint checks a whole package, from inside its module. Upstream
  -- chooses between the package and the lone file once, from Neovim's own
  -- folder; this chooses for each file. Upstream's last argument is the
  -- function that names what to lint, and it is replaced.
  golangcilint = function(def, buf)
    local file = vim.api.nvim_buf_get_name(buf)
    local dir = vim.fs.dirname(file)
    local mod = vim.fs.find("go.mod", { path = dir, upward = true })[1]
    def.cwd = mod and vim.fs.dirname(mod) or dir
    local args = def.args or {}
    def.args = vim.list_slice(args, 1, #args - 1)
    def.args[#def.args + 1] = mod and dir or file
    return def
  end,
}

local function installed(name)
  local programs = M.commands[name]
  if not programs then
    return false
  end
  for _, program in ipairs(programs) do
    if vim.fn.executable(program) ~= 1 then
      return false
    end
  end
  return true
end

-- The linters that will run on buf, in the table's order: those of its file
-- type whose programs are installed. None for a buffer that is not a file. A
-- compound file type the table does not name, such as markdown.pandoc, gets
-- the linters of each of its parts, as nvim-lint resolves it.
function M.linters_for(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
    return {}
  end
  local by_ft, ft = require("lint").linters_by_ft, vim.bo[buf].filetype
  local wanted = by_ft[ft]
  if not wanted then
    wanted = {}
    for _, part in ipairs(vim.split(ft, ".", { plain = true })) do
      vim.list_extend(wanted, by_ft[part] or {})
    end
  end
  local names, seen = {}, {}
  for _, name in ipairs(wanted) do
    if not seen[name] and installed(name) then
      seen[name] = true
      names[#names + 1] = name
    end
  end
  return names
end

-- Lints buf now: every linter when all is true, otherwise only those that are
-- sent the buffer's text.
function M.run(buf, all)
  local names = M.linters_for(buf)
  if #names == 0 then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    require("lint").try_lint(names, { filter = not all and "stdin" or nil })
  end)
end

-- Calls waiting out their pause, by buffer.
local pending = {}

-- Lints buf once debounce_ms passes with no further call for it, running
-- every linter if any of the calls asked for all of them.
function M.schedule(buf, all)
  local p = pending[buf] or { all = false, n = 0 }
  pending[buf] = p
  p.all = p.all or all
  p.n = p.n + 1
  local n = p.n
  vim.defer_fn(function()
    if pending[buf] == p and p.n == n then
      pending[buf] = nil
      M.run(buf, p.all)
    end
  end, M.debounce_ms)
end

-- Called from nvim-lint's spec once the plugin loads.
function M.setup()
  local lint = require("lint")
  lint.linters_by_ft = require("ach.lang").linters_by_ft()
  for name, adapt in pairs(M.adapt) do
    lint.linters[name] = function()
      return adapt(vim.deepcopy(require("lint.linters." .. name)), vim.api.nvim_get_current_buf())
    end
  end
  vim.api.nvim_create_autocmd(M.events, {
    group = vim.api.nvim_create_augroup("ach_lint", { clear = true }),
    callback = function(ev)
      M.schedule(ev.buf, ev.event ~= "InsertLeave")
    end,
  })
end

return M
```

nvim-lint calls a linter given as a function each time it lints, with the buffer about to be linted current, which is how each change sees the right file. `run` makes the buffer current for that call with `nvim_buf_call`, since by the time a pause ends the cursor may be in another window.

- [ ] **Write the plugin spec**

`lua/ach/plugins/lint.lua`:

```lua
-- nvim-lint runs each file type's linters. lua/ach/lint.lua decides which,
-- and when.
return {
  {
    "mfussenegger/nvim-lint",
    -- Loaded when a file opens, so the first file is linted and the status
    -- bar can name its linters from the start.
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      require("ach.lint").setup()
    end,
  },
}
```

lazy.nvim loads nvim-lint during the first file's `BufReadPost` and then fires that event again for the autocommands the plugin's `config` created, which is how the first file gets linted.

- [ ] **Install the plugin**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones nvim-lint and adds it to `lazy-lock.json`. No linter is installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 10 `test_lint` tests pass, along with every earlier test, the status bar's included. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/lint.lua lua/ach/plugins/lint.lua tests/test_lint.lua
git commit --only lua/ach/lint.lua lua/ach/plugins/lint.lua tests/test_lint.lua lazy-lock.json -m "feat(lint): lint each file on open, save and leaving insert mode, once its linters are installed"
```

---

### Task: Grammar

**Files:**
- Create: `lua/ach/grammar.lua`
- Modify: `lua/ach/init.lua` (replace the whole file)
- Test: `tests/test_grammar.lua`

**Interfaces:**
- Consumes: `require("ach.lang")` (`for_ft(ft)`, `is_manual(ft)`, `parsers_for_ft(ft)`, `harper_filetypes()`, `manual_filetypes()`); the tree-sitter task's `FileType` hook, which starts the highlighter that marks what spelling checks; nvim-lspconfig's `lsp/harper_ls.lua`, which supplies Harper's command and root markers; `require("ach.lsp").enable_for(ft)`, which enables `harper_ls` wherever `servers_for_ft` names it; `require("ach.languages").grammar.package`, `harper-ls`, which `packages_for_ft` adds to the Mason packages of every file type Harper checks; the installer's dry run and its `requests.packages`, for the test that Harper is installed only where it checks.
- Produces:
  - `require("ach.grammar")`: `spellfile: string`; `kind_for(ft): "prose"|"code"|nil`; `kind(buf): "prose"|"code"|nil`; `apply(buf)`; `harper(): { filetypes: string[], settings: table }`; `setup()`.
  - Spelling on in the window of every file whose language the table knows, and Harper's configuration narrowed to the table's file types before any server starts.

Two tools check writing. Neovim's own spell checker underlines a word its English word list does not contain, such as "teh", and Harper, a language server that runs entirely on this Mac, reports grammar: a repeated word, "a" before a vowel, a missing capital at the start of a sentence. Harper's program, `harper-ls`, is a Mason package like any language's server. The installer installs it silently, and pins its version in `mason-lock.json`, the first time a file Harper checks is opened, and a file Harper does not check never installs it. Spelling is a window setting in Neovim and off by default, so this task decides where it goes on, and how much of the file it reads:

| Kind | File types | What spelling checks | Long lines |
| --- | --- | --- | --- |
| Prose | The seven the table formats only by hand: `markdown`, `markdown.mdx`, `tex`, `plaintex`, `bib`, `typst`, `text` | Every word of the text, except what the language's parser marks as code, such as a Markdown code block or a LaTeX command | Wrap at a word boundary, a list item's continuation lines indented under its text |
| Code | Every other file type whose language has a Tree-sitter parser | Only what the parser marks for checking: comments, and in a few languages a docstring or a commit message's text | Unchanged |
| Neither | Lean, which has no parser, every file type the table does not name, and every buffer that is not a file, such as help, a terminal or a picker | Nothing | Unchanged |

In code, two words in `spelloptions` change how a word is read. `noplainbuffer` checks nothing until a parser or a syntax file marks what to check, so before a language's parser is installed its identifiers are never underlined. `camel` reads a camelCase name in a comment as the words it is made of, so `getUserName` passes, where it would otherwise be one long unknown word, while `parseHedaer` is still caught on its misspelt part. Plain text has no parser at all, so it is checked word by word.

Both kinds go further than the spec's "spelling in prose", on purpose. A misspelt word in a comment is as visible to a reader as one in a document, so code gets its comments checked, and a paragraph kept on one line is unreadable unless the window wraps it, so prose wraps at word boundaries. Wrapping is on only in the window, never in the file: nothing is inserted, so a paragraph stays one line, as the owner's rule for Markdown and LaTeX asks. `linebreak`, on since the foundation, makes each wrap fall between words.

`zg` adds the word under the cursor to the spell file, `zw` marks it wrong, `z=` lists suggestions, and `]s` and `[s` move to the next and previous misspelling. These are Neovim's own keys, so this task adds none. The spell file lives in the data folder, as the global constraints require, and the folder is created at startup, because `zg` cannot create it once `spellfile` names it. Neovim ships the English word list itself, so no download prompt appears the first time spelling turns on.

Harper is told three things. Its file types are the table's, from `harper_filetypes()`, rather than nvim-lspconfig's list of every language Harper reads; until now Harper would attach to any buffer of that longer list once some other file had enabled it. Neovim replaces a list in a server's configuration rather than merging it, so this list is the whole of it. Three of Harper's rules are off, each for the reason in this table:

| Rule | Why it is off |
| --- | --- |
| SpellCheck | Neovim already underlines misspelt words, and two marks on one word is noise. It also keeps one dictionary: a word added with `zg` would otherwise go on being reported by Harper |
| LongSentences | A long sentence is a choice in this author's prose, which carries its qualifications in clauses, rather than a mistake |
| Spaces | Comments in this configuration align columns with runs of spaces, as `lua/ach/languages.lua` does at its top, and Harper reads a comment as prose |

Harper reads its settings from the `harper-ls` key of what Neovim sends when it connects. Neovim sends a buffer's file type as its language, and the table already limits `harper_filetypes()` to the languages Harper reads.

- [ ] **Write the failing tests**

`tests/test_grammar.lua`:

```lua
-- Spelling and grammar. The spell file is kept in the data folder; prose is
-- checked word by word and wraps, code has only its comments checked, and
-- buffers that are not files, or files the table does not know, get no
-- spelling; Harper comes from Mason, only for a file it checks, and checks
-- the table's file types with three of its rules off.
local opened = {}

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- Writes lines to a new file called name and opens it in the current window.
local function open(t, name, lines)
  local path = t.tmpdir() .. "/" .. name
  vim.fn.writefile(lines, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  opened[#opened + 1] = buf
  return buf
end

-- The first misspelling on the current window's first line, and where it
-- starts, as { word, kind, column }. The column is zero-based.
local function first_misspelling()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local bad = vim.fn.spellbadword()
  return { bad[1], bad[2], vim.api.nvim_win_get_cursor(0)[2] }
end

return {
  ["the words zg adds are kept in the data folder"] = function(t)
    local G = require("ach.grammar")
    t.eq(G.spellfile, vim.fn.stdpath("data") .. "/spell/en.utf-8.add")
    t.eq(vim.go.spellfile, G.spellfile, "the spell file")
    t.ok(not vim.startswith(G.spellfile, t.root), "not in this repository")
    t.eq(vim.fn.isdirectory(vim.fs.dirname(G.spellfile)), 1, "its folder exists, so the first zg can write it")
    t.ok(#vim.api.nvim_get_runtime_file("spell/en.utf-8.spl", false) > 0, "Neovim's English word list")
  end,

  ["each file type is prose, code or neither"] = function(t)
    local G = require("ach.grammar")
    local cases = {
      text = "prose",
      markdown = "prose",
      ["markdown.mdx"] = "prose",
      tex = "prose",
      bib = "prose",
      typst = "prose",
      lua = "code",
      python = "code",
      gitcommit = "code",
      systemverilog = "code",
      lean = false,
      help = false,
      [""] = false,
      ["markdown.pandoc"] = "prose",
      ["lua.achtest"] = "code",
    }
    local got = {}
    for ft in pairs(cases) do
      got[ft] = G.kind_for(ft) or false
    end
    t.eq(got, cases)
    for _, ft in ipairs(require("ach.lang").manual_filetypes()) do
      t.eq(G.kind_for(ft), "prose", ft .. " is formatted by hand, so it is prose")
    end
  end,

  ["prose windows wrap, and code windows check only what the parser marks"] = function(t)
    tidy(function()
      local md = open(t, "notes.md", { "# Notes", "", "- one item" })
      t.ok(vim.wo.spell, "spelling in a Markdown window")
      t.ok(vim.wo.wrap, "long lines wrap")
      t.ok(vim.wo.breakindent, "wrapped lines keep their indent")
      t.eq(vim.wo.breakindentopt, "list:-1", "a list item's continuation lines sit under its text")
      t.eq(vim.bo[md].spellfile, vim.go.spellfile, "a new buffer gets the spell file")
      t.ok(not vim.tbl_contains(vim.opt_local.spelloptions:get(), "camel"), "camel is for code")

      local lua = open(t, "sample.lua", { "local x = 1" })
      t.ok(vim.wo.spell, "spelling in a Lua window")
      t.ok(not vim.wo.wrap, "code does not wrap, though the window showed prose before")
      local options = vim.opt_local.spelloptions:get()
      t.ok(vim.tbl_contains(options, "camel"), "camelCase names are checked part by part")
      t.ok(vim.tbl_contains(options, "noplainbuffer"), "only what the parser marks is checked")
      t.eq(vim.bo[lua].filetype, "lua")

      local txt = open(t, "sample.txt", { "one two" })
      t.ok(vim.wo.spell, "spelling in a text window")
      t.ok(vim.wo.wrap, "text wraps")
      t.ok(not vim.tbl_contains(vim.opt_local.spelloptions:get(), "noplainbuffer"), "text has no parser, so every word is checked")
      t.eq(vim.bo[txt].filetype, "text")
      t.ok(not vim.go.spell and not vim.go.wrap, "only the windows changed, not the defaults")
    end)
  end,

  ["a misspelt comment is found and a misspelt name is not"] = function(t)
    tidy(function()
      local buf = open(t, "sample.lua", { "local teh = 1 -- one teh two" })
      vim.treesitter.start(buf, "lua")
      vim.treesitter.get_parser(buf, "lua"):parse(true)
      t.eq(first_misspelling(), { "teh", "bad", 21 }, "the word in the comment, not the name at column 6")
    end)
  end,

  ["plain text is checked word by word"] = function(t)
    tidy(function()
      open(t, "sample.txt", { "one teh two" })
      t.eq(first_misspelling(), { "teh", "bad", 4 })
    end)
  end,

  ["buffers that are not files, and files the table does not know, get no spelling"] = function(t)
    local G = require("ach.grammar")
    tidy(function()
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.api.nvim_win_set_buf(0, scratch)
      vim.bo[scratch].filetype = "markdown"
      t.eq(G.kind(scratch), nil, "a scratch buffer")
      t.ok(not vim.wo.spell, "no spelling in its window")

      local file = open(t, "notes.achtest", { "one teh two" })
      t.eq(vim.bo[file].filetype, "", "a file Neovim does not recognise")
      t.eq(G.kind(file), nil, "a file the table does not know")
      t.ok(not vim.wo.spell, "no spelling in its window")
      t.eq(G.kind(-1), nil, "a buffer that does not exist")
    end)
  end,

  ["Harper comes from Mason, for the file types it checks and no others"] = function(t)
    local install = require("ach.install")
    t.eq(require("ach.languages").grammar.package, "harper-ls", "the Mason package")
    local saved_dry, saved_map = install.dry, install.server_packages
    install.dry = true
    install.server_packages = function()
      return {}
    end
    local ok, err = pcall(tidy, function()
      install.reset()
      open(t, "data.json", { "{}" })
      t.ok(not vim.list_contains(install.requests.packages, "harper-ls"), "nothing of Harper's for a JSON file")
      open(t, "notes.md", { "# Notes" })
      t.ok(vim.list_contains(install.requests.packages, "harper-ls"), "harper-ls for a Markdown file")
    end)
    install.dry, install.server_packages = saved_dry, saved_map
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["Harper checks only the table's file types, with three rules off"] = function(t)
    local config = vim.lsp.config.harper_ls
    t.eq(config.cmd[1], "harper-ls", "nvim-lspconfig's command")
    t.eq(config.filetypes, require("ach.lang").harper_filetypes(), "the table's file types")
    t.eq(config.settings, {
      ["harper-ls"] = { linters = { SpellCheck = false, LongSentences = false, Spaces = false } },
    })
  end,
}
```

The comment test starts the Lua highlighter and parses the whole file itself, rather than waiting for the tree-sitter task's hook, because spelling in code reads only what the parser has marked, and a test that raced the parser would pass or fail by timing. Lua's parser ships with Neovim, so it is always there. `spellbadword()` asks the highlighter for those marks directly, so it works with no screen drawn. Lean, the one language the table knows that has no parser, is checked through `kind_for` alone. Opening a `.lean` file would start the managed-languages task's Lean plugin, which has nothing to do with spelling.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_grammar`
Expected: `1 passed, 7 failed, 0 need a person, 0 skipped`, exit 1. The one that passes is the Mason test: the language-table task already puts `harper-ls` among the packages of every file type Harper checks, and the test is here so that nothing this task changes about Harper's file types can part them from where it is installed. Three fail on `module 'ach.grammar' not found`. The window test fails on `spelling in a Markdown window`, and the two misspelling tests on a result whose word is empty, because spelling is off and `spellbadword()` finds nothing. The Harper test fails on `the table's file types`, because nvim-lspconfig's own list is longer.

- [ ] **Write the grammar rules**

`lua/ach/grammar.lua`:

```lua
-- Spelling and grammar. Neovim's spell checker underlines misspelt words in
-- prose and in code comments; Harper, a language server, reports grammar in
-- the same places. This module decides where spelling is on and how much of
-- a file it reads, where the words zg adds are kept, and what Harper is told.
local M = {}

-- The words zg adds. Neovim would otherwise write them into the first folder
-- of the runtime path, which is this repository.
M.spellfile = vim.fn.stdpath("data") .. "/spell/en.utf-8.add"

local function kind_of(ft)
  local lang = require("ach.lang")
  if lang.is_manual(ft) then
    return "prose"
  end
  if #lang.parsers_for_ft(ft) > 0 then
    return "code"
  end
  return nil
end

-- What spelling treats a file type as: "prose", where every word is checked
-- and long lines wrap; "code", where only what the parser marks is checked,
-- comments for the most part; or nil, where spelling stays off. A compound
-- file type the table does not name, such as markdown.pandoc, is read by its
-- parts, the first that is known deciding.
function M.kind_for(ft)
  local kind = kind_of(ft)
  if kind or require("ach.lang").for_ft(ft) then
    return kind
  end
  for _, part in ipairs(vim.split(ft, ".", { plain = true })) do
    kind = kind_of(part)
    if kind then
      return kind
    end
  end
  return nil
end

-- The kind of a buffer: nil for one that does not exist or is not a file,
-- such as help, a terminal or a picker.
function M.kind(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  return M.kind_for(vim.bo[buf].filetype)
end

-- Turns spelling on in the window showing buf, as :setlocal does, so a file
-- opened in that window later starts from the defaults again. Prose also
-- wraps at word boundaries, a list item's continuation lines indented under
-- its text. In code, noplainbuffer leaves the buffer unchecked until a parser
-- or syntax file marks what to check, so names are never underlined, and
-- camel reads a camelCase name in a comment as the words it is made of.
function M.apply(buf)
  local kind = M.kind(buf)
  if not kind then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.spell = true
    if kind == "prose" then
      vim.opt_local.wrap = true
      vim.opt_local.breakindent = true
      vim.opt_local.breakindentopt = "list:-1"
    else
      vim.opt_local.spelloptions:append({ "camel", "noplainbuffer" })
    end
  end)
end

-- Harper's file types and settings. The file types are the table's, which
-- Neovim puts in place of nvim-lspconfig's longer list. SpellCheck is off
-- because Neovim already underlines misspelt words and keeps the one
-- dictionary; LongSentences because a long sentence is a choice in this
-- author's prose; Spaces because comments here align columns with spaces.
function M.harper()
  return {
    filetypes = require("ach.lang").harper_filetypes(),
    settings = {
      ["harper-ls"] = {
        linters = { SpellCheck = false, LongSentences = false, Spaces = false },
      },
    },
  }
end

-- Runs once, before lazy.nvim, so the first file named on the command line
-- gets its spelling, and Harper is narrowed before any server is enabled.
function M.setup()
  vim.opt.spellfile = M.spellfile
  vim.fn.mkdir(vim.fs.dirname(M.spellfile), "p")
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ach_grammar", { clear = true }),
    callback = function(ev)
      M.apply(ev.buf)
    end,
  })
  vim.lsp.config("harper_ls", M.harper())
end

return M
```

The hook is created before the installer's, which is where the tree-sitter task starts the highlighter, so it runs first on every file. When the highlighter starts it adds `noplainbuffer` itself and remembers the options it found, which by then include this module's, so stopping the highlighter later leaves them in place. `vim.lsp.config` only records Harper's settings; Neovim merges them over nvim-lspconfig's file when Harper is first enabled, by which time nvim-lspconfig, which is not lazy, is on the runtime path.

- [ ] **Load it at startup**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added, Homebrew's Java,
-- Ruby and the toolchain folders put on the path, spelling and Harper's
-- settings put in place and the installer's hooks created before lazy.nvim
-- starts, so a file named on the command line is recognised, checked, and
-- gets its parsers and tools when it opens. Keymaps wait for VeryLazy, after
-- the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.runtimes").setup()
require("ach.grammar").setup()
require("ach.install").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 8 `test_grammar` tests pass, along with every earlier test. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/grammar.lua tests/test_grammar.lua
git commit --only lua/ach/grammar.lua lua/ach/init.lua tests/test_grammar.lua -m "feat(grammar): check spelling in prose and code comments, and narrow Harper to the table's file types"
```

---

### Task: Managed languages

**Files:**
- Create: `lua/ach/managed.lua`, `lua/ach/plugins/managed.lua`
- Modify: `lua/ach/install.lua` (`M.ready`), `lua/ach/init.lua` (replace the whole file), `lua/ach/icons.lua` (fifteen keys and one group), `lazy-lock.json`
- Test: `tests/test_managed.lua`

**Interfaces:**
- Consumes: `require("ach.lang").for_ft(ft)`, whose entry carries `managed`, the plugin's name; `require("ach.lsp")` (`capabilities()`, `enable_for(ft)`); the installer's `FileType` hook, which calls `install.ready(buf, ft, entry)` once a buffer's packages are installed or have failed, and never under `ACH_DRY_INSTALL=1`; `require("ach.icons")` (`key(desc)`, `group(name)`); which-key's `add(spec)`.
- Produces:
  - `require("ach.managed")`: `clients: table<plugin, string>`, the client name each plugin gives its server; `share: string`, Mason's shared-files folder; `metals_program: string`; `lean: { [1]: string, [2]: string, [3]: string }[]`, each Lean key after the local leader with its command and description; `jdtls_root(buf): string`; `jdtls_bundles(): string[]`; `jdtls_config(buf): table`; `start(buf, entry, opts?: { install?: boolean })`; `lean_keys(buf)`; `setup()`.
  - `install.ready` now hands every managed language's buffer to `managed.start`, after enabling the file type's other servers. The Debugging task registers Java's debugger, with hot code replace, before the Java starter starts jdtls; gives the Metals configuration built in the Scala starter an `on_attach` that registers Scala's debugger; and turns off haskell-tools' search for launch configurations when a file opens.

Five languages do not start their server through `vim.lsp.enable`. Each has a plugin that starts it and adds what a bare server cannot: Cargo's commands and macro expansion for Rust, evaluation of a module's examples for Haskell, the project import that jdtls needs before it answers anything for Java, the build-server import for Scala, and the infoview, the pane where Lean shows the proof state at the cursor. The language table marks these entries `managed` and gives them no `lsp` list, so the language-server task's `enable_for` never touches them.

Left alone, each plugin starts its server from its own `ftplugin` the moment a file of its type opens. That is a race with the installer. rust-analyzer is a Mason package, so on a new Mac the plugin would look for it before Mason had finished, report it missing, and never look again. And because rustaceanvim finds a Cargo project's root asynchronously, a plugin start and an installer start could both be in flight at once. So every plugin's own start is switched off, and the installer starts each server once, after its program exists:

| Plugin | How it is started | Client name | Program it waits for | What else it is given |
| --- | --- | --- | --- | --- |
| rustaceanvim | `require("rustaceanvim.lsp").start(buf)` | `rust-analyzer` | `rust-analyzer` | Clippy as the check on save |
| haskell-tools.nvim | `require("haskell-tools").lsp.start(buf)`, with `buf` current | `haskell-tools.nvim` | `haskell-language-server-wrapper` or `haskell-language-server` | nothing |
| nvim-jdtls | `require("jdtls").start_or_attach(config, nil, { bufnr = buf })` | `jdtls` | `jdtls` | a data folder per project, Lombok, the debug and test bundles, the capabilities |
| nvim-metals | `require("metals").initialize_or_attach(config)`, with `buf` current | `metals` | the Metals program in the data folder | the program's path, the capabilities |
| lean.nvim | `vim.lsp.enable("leanls")` | `leanls` | `lean` | nothing |

rustaceanvim, haskell-tools and lean.nvim each merge `vim.lsp.config["*"]` into their own configuration, which is where `enable_for` puts the capabilities. That is why `ready` still calls `enable_for` first for a managed language: it has no servers of its own to enable, but the first call sets the capabilities those three then pick up. nvim-jdtls and nvim-metals read no such shared configuration, so they are passed the capabilities directly.

Two of the plugins attach to whichever buffer is current rather than to the one they are given. haskell-tools passes the buffer to its own setup but then calls `vim.lsp.start` without it, and nvim-metals reads the current buffer outright. A buffer that finishes installing is often not the current one, since the person has moved on while Mason worked, so both are started inside `nvim_buf_call`, which makes the buffer current for the length of the call and then puts the old one back. Every starter also skips a buffer that is not a file, the way Neovim's own `vim.lsp.enable` does, and a buffer that already has its client.

Metals is not a Mason package. nvim-metals can install it, but only through its own `:MetalsInstall` command, which it first asks for in a message, and which reads a configuration it caches during a successful start. So Coursier, which the language table already installs as Scala's runtime, installs Metals straight into the data folder, and nvim-metals is given that program's path. This departs from the spec's wording, which has nvim-metals install Metals itself; the result is the same program, installed without a command to type. The install runs once however many Scala files are open, and starts Metals in each of them when it finishes. If Coursier itself is missing, the starter stays quiet, because the installer's runtime check has already said how to install it. nvim-metals also refuses a file that is not yet on disk, so a new Scala file gets its server when it is first written. The health task reports `coursier update --install-dir` as the way to update Metals later.

lean.nvim loads when a `.lean` file is read or created, before its file type is set, which is how its README asks to be loaded. Loading it adds its `lsp/leanls.lua` to the runtime path and creates its commands, so by the time the installer enables `leanls` there is a configuration to enable. Inside a `FileType` hook, Neovim 0.12's `vim.lsp.enable` attaches the newly enabled server to every open buffer it applies to, so a Lean file named on the command line gets its server too. lean.nvim's own suggested keys are not used, because they carry its long descriptions and no icon. The same fifteen keys are set here with short descriptions, an icon each, and a which-key group for the four diff-pin keys under `\d`.

The two plugins with semantic-versioned releases follow their major version; the three without one are pinned to the commit whose source this task was checked against. nvim-jdtls's last tag is from 2022, nvim-metals tags only old release branches, and lean.nvim's latest release, v2026.4.1, predates the `lsp/leanls.lua` and `lsp.enable` switch this task relies on. `lazy-lock.json` records the exact commit of all five either way. None of the five needs plenary.nvim.

- [ ] **Write the failing tests**

`tests/test_managed.lua`:

```lua
-- Rust, Haskell, Java, Scala and Lean. Each plugin's own start is off; the
-- installer hands a buffer to ach.managed, which starts that plugin's server
-- once its program is there, in the right buffer. The plugins are stand-ins
-- in package.loaded, so no test loads one or starts a real server.
local opened = {}

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

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- A buffer called path, of file type ft, that is never read from disk, so it
-- fires no BufReadPre and loads no plugin.
local function named(path, ft)
  local buf = vim.api.nvim_create_buf(true, false)
  opened[#opened + 1] = buf
  vim.api.nvim_buf_set_name(buf, path)
  vim.bo[buf].filetype = ft
  return buf
end

-- A stand-in for vim.fn.executable that finds only the programs in found,
-- read at each call, so a test can install one partway through.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

local function entry(ft)
  return require("ach.lang").for_ft(ft)
end

return {
  ["each plugin's own start is off"] = function(t)
    local rust = vim.g.rustaceanvim or {}
    t.eq(vim.tbl_get(rust, "server", "auto_attach"), false, "rustaceanvim's own start")
    t.eq(
      vim.tbl_get(rust, "server", "default_settings", "rust-analyzer", "check", "command"),
      "clippy",
      "rust-analyzer checks with Clippy"
    )
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "hls", "auto_attach"), false, "haskell-tools' own start")
    t.eq(vim.tbl_get(vim.g.lean_config or {}, "lsp", "enable"), false, "lean.nvim's own start")
  end,

  ["the installer enables servers, then hands a managed language to its plugin"] = function(t)
    local M, L, install = require("ach.managed"), require("ach.lsp"), require("ach.install")
    local calls = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/main.rs", "rust")
      with({
        {
          L,
          "enable_for",
          function(ft)
            calls[#calls + 1] = "enable " .. ft
          end,
        },
        {
          M,
          "start",
          function(b, e)
            calls[#calls + 1] = "start " .. e.managed .. (b == buf and " here" or " elsewhere")
          end,
        },
      }, function()
        install.ready(buf, "rust", entry("rust"))
        install.ready(buf, "python", entry("python"))
      end)
      t.eq(calls, { "enable rust", "start rustaceanvim here", "enable python" })
    end)
  end,

  ["Rust and Haskell start in the buffer they were given"] = function(t)
    local M = require("ach.managed")
    local got = {}
    tidy(function()
      local rs = named(t.tmpdir() .. "/main.rs", "rust")
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      local here = vim.api.nvim_get_current_buf()
      with({
        { vim.fn, "executable", only({ ["rust-analyzer"] = true, ["haskell-language-server-wrapper"] = true }) },
        {
          package.loaded,
          "rustaceanvim.lsp",
          {
            start = function(b)
              got.rust = b
            end,
          },
        },
        {
          package.loaded,
          "haskell-tools",
          {
            lsp = {
              start = function(b)
                got.haskell = { b, vim.api.nvim_get_current_buf() }
              end,
            },
          },
        },
      }, function()
        M.start(rs, entry("rust"))
        M.start(hs, entry("haskell"))
      end)
      t.eq(got.rust, rs, "rust-analyzer's buffer")
      t.eq(got.haskell, { hs, hs }, "haskell-language-server's buffer, current while it starts")
      t.eq(vim.api.nvim_get_current_buf(), here, "the current buffer is put back")
    end)
  end,

  ["Java gets a data folder per project, Lombok, and the debug and test bundles"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local share, root = t.tmpdir(), t.tmpdir()
    for _, jar in ipairs({
      "jdtls/lombok.jar",
      "java-debug-adapter/com.microsoft.java.debug.plugin.jar",
      "java-test/com.microsoft.java.test.plugin-0.43.1.jar",
      "java-test/com.microsoft.java.test.runner-jar-with-dependencies.jar",
      "java-test/jacocoagent.jar",
      "java-test/junit-jupiter-api_5.11.0.jar",
    }) do
      vim.fn.mkdir(vim.fs.dirname(share .. "/" .. jar), "p")
      vim.fn.writefile({}, share .. "/" .. jar)
    end
    for _, dir in ipairs({ "a/app/.git", "a/app/src", "b/app/.git", "b/app/src" }) do
      vim.fn.mkdir(root .. "/" .. dir, "p")
    end
    local calls = {}
    tidy(function()
      local one = named(root .. "/a/app/src/Main.java", "java")
      local two = named(root .. "/b/app/src/Main.java", "java")
      with({
        { M, "share", share },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function()
            return { stand_in = true }
          end,
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function(config, opts, start_opts)
              calls[#calls + 1] = { config = config, opts = opts, start_opts = start_opts }
            end,
          },
        },
      }, function()
        M.start(one, entry("java"))
        M.start(two, entry("java"))
      end)
      t.eq(#calls, 2, "jdtls is asked once per buffer")
      local c = calls[1].config
      local data = c.cmd[#c.cmd]
      t.eq(c.cmd, { "jdtls", "--jvm-arg=-javaagent:" .. share .. "/jdtls/lombok.jar", "-data", data })
      t.eq(c.root_dir, root .. "/a/app", "the project's root")
      t.ok(vim.startswith(data, vim.fn.stdpath("cache") .. "/jdtls/app-"), "the data folder is in the cache: " .. data)
      t.ok(data ~= calls[2].config.cmd[#calls[2].config.cmd], "two projects called app keep two data folders")
      t.eq(c.init_options.bundles, {
        share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar",
        share .. "/java-test/com.microsoft.java.test.plugin-0.43.1.jar",
        share .. "/java-test/junit-jupiter-api_5.11.0.jar",
      }, "the bundles, without the test runner and the coverage agent")
      t.eq(c.capabilities, { stand_in = true })
      t.eq(calls[1].start_opts, { bufnr = one })
    end)
  end,

  ["a buffer that is not a file starts nothing"] = function(t)
    local M = require("ach.managed")
    local asked = 0
    tidy(function()
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.bo[scratch].filetype = "java"
      local gone = named(t.tmpdir() .. "/Gone.java", "java")
      vim.api.nvim_buf_delete(gone, { force = true })
      with({
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function()
              asked = asked + 1
            end,
          },
        },
      }, function()
        M.start(scratch, entry("java"))
        M.start(gone, entry("java"))
      end)
      t.eq(asked, 0)
    end)
  end,

  ["Scala starts Metals from the data folder"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local program = t.tmpdir() .. "/metals"
    local got
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only({ [program] = true }) },
        {
          L,
          "capabilities",
          function()
            return { stand_in = true }
          end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function()
              return { settings = {}, init_options = { statusBarProvider = "off" } }
            end,
            initialize_or_attach = function(config)
              got = { config = config, buf = vim.api.nvim_get_current_buf() }
            end,
          },
        },
      }, function()
        M.start(buf, entry("scala"))
      end)
      t.eq(got and got.buf, buf, "Metals attaches to the Scala buffer")
      t.eq(got.config.settings, { metalsBinaryPath = program })
      t.eq(got.config.capabilities, { stand_in = true })
      t.eq(got.config.init_options, { statusBarProvider = "off" }, "bare_config's other fields are kept")
    end)
  end,

  ["a missing Metals is installed once, then started in each Scala buffer"] = function(t)
    local M = require("ach.managed")
    local program = t.tmpdir() .. "/metals/metals"
    local found, runs, notes, started, finish = { coursier = true }, {}, {}, {}, nil
    tidy(function()
      local one = named(t.tmpdir() .. "/A.scala", "scala")
      local two = named(t.tmpdir() .. "/build.sbt", "sbt")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only(found) },
        {
          vim,
          "notify",
          function(msg, level)
            notes[#notes + 1] = { msg, level }
          end,
        },
        {
          vim,
          "system",
          function(cmd, _, on_exit)
            runs[#runs + 1] = cmd
            finish = on_exit
            return {}
          end,
        },
        {
          require("ach.lsp"),
          "capabilities",
          function()
            return {}
          end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function()
              return { settings = {} }
            end,
            initialize_or_attach = function()
              started[#started + 1] = vim.api.nvim_get_current_buf()
            end,
          },
        },
      }, function()
        M.start(one, entry("scala"))
        M.start(two, entry("sbt"))
        t.eq(runs, { { "coursier", "install", "--install-dir", vim.fs.dirname(program), "metals" } }, "one install for two buffers")
        t.eq(notes, { { "Installing Metals for Scala; it starts when the install finishes" } })
        t.eq(started, {}, "nothing starts before the install finishes")
        found[program] = true
        finish({ code = 0, stdout = "", stderr = "" })
        t.ok(
          vim.wait(1000, function()
            return #started == 2
          end),
          "both buffers start once Metals is there"
        )
      end)
      table.sort(started)
      local want = { one, two }
      table.sort(want)
      t.eq(started, want)
    end)
  end,

  ["a failed Metals install says why, and the next Scala buffer tries again"] = function(t)
    local M = require("ach.managed")
    local runs, notes, finish = 0, {}, nil
    tidy(function()
      local buf = named(t.tmpdir() .. "/A.scala", "scala")
      with({
        { M, "metals_program", t.tmpdir() .. "/metals/metals" },
        { vim.fn, "executable", only({ coursier = true }) },
        {
          vim,
          "notify",
          function(msg, level)
            notes[#notes + 1] = { msg, level }
          end,
        },
        {
          vim,
          "system",
          function(_, _, on_exit)
            runs = runs + 1
            finish = on_exit
            return {}
          end,
        },
      }, function()
        M.start(buf, entry("scala"))
        finish({ code = 1, stdout = "", stderr = "Resolving metals\nError: download failed\n" })
        t.ok(
          vim.wait(1000, function()
            return #notes == 2
          end),
          "a second message"
        )
        t.eq(notes[2], { "Metals did not install: Error: download failed", vim.log.levels.ERROR })
        M.start(buf, entry("scala"))
        t.eq(runs, 2, "the next Scala buffer tries again")
        finish({ code = 1, stdout = "", stderr = "" })
        vim.wait(1000, function()
          return #notes == 4
        end)
      end)
    end)
  end,

  ["a new Scala file gets Metals when it is first written"] = function(t)
    local M = require("ach.managed")
    local program = t.tmpdir() .. "/metals"
    local found, started, runs = { coursier = true }, 0, 0
    tidy(function()
      local buf = named(t.tmpdir() .. "/New.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only(found) },
        {
          vim,
          "system",
          function()
            runs = runs + 1
            return {}
          end,
        },
        { vim, "notify", function() end },
        {
          require("ach.lsp"),
          "capabilities",
          function()
            return {}
          end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function()
              return { settings = {} }
            end,
            initialize_or_attach = function()
              started = started + 1
            end,
          },
        },
      }, function()
        vim.api.nvim_exec_autocmds("BufWritePost", { group = "ach_managed", buffer = buf })
        t.eq({ started, runs }, { 0, 0 }, "a save does not install Metals")
        found[program] = true
        vim.api.nvim_exec_autocmds("BufWritePost", { group = "ach_managed", buffer = buf })
        t.eq(started, 1, "the first save once Metals is there starts it")
      end)
    end)
  end,

  ["Lean enables lean.nvim's server once lean is installed"] = function(t)
    local M = require("ach.managed")
    local enabled = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.lean", "lean")
      with({
        { vim.fn, "executable", only({ lean = true }) },
        { package.loaded, "lean", {} },
        {
          vim.lsp,
          "enable",
          function(name)
            enabled[#enabled + 1] = name
          end,
        },
      }, function()
        M.start(buf, entry("lean"))
      end)
      t.eq(enabled, { "leanls" })
    end)
  end,

  ["each starter waits quietly while its program is missing"] = function(t)
    local M = require("ach.managed")
    local asked, notes, runs = {}, 0, 0
    local function ask(name)
      return function()
        asked[#asked + 1] = name
      end
    end
    tidy(function()
      local bufs = {
        rust = named(t.tmpdir() .. "/main.rs", "rust"),
        haskell = named(t.tmpdir() .. "/Main.hs", "haskell"),
        java = named(t.tmpdir() .. "/Main.java", "java"),
        scala = named(t.tmpdir() .. "/Main.scala", "scala"),
        lean = named(t.tmpdir() .. "/Main.lean", "lean"),
      }
      with({
        { M, "metals_program", t.tmpdir() .. "/metals" },
        { vim.fn, "executable", only({}) },
        {
          vim,
          "notify",
          function()
            notes = notes + 1
          end,
        },
        {
          vim,
          "system",
          function()
            runs = runs + 1
            return {}
          end,
        },
        { vim.lsp, "enable", ask("leanls") },
        { package.loaded, "rustaceanvim.lsp", { start = ask("rust-analyzer") } },
        { package.loaded, "haskell-tools", { lsp = { start = ask("haskell-language-server") } } },
        { package.loaded, "jdtls", { start_or_attach = ask("jdtls") } },
        { package.loaded, "metals", { initialize_or_attach = ask("metals") } },
      }, function()
        for ft, buf in pairs(bufs) do
          M.start(buf, entry(ft))
        end
      end)
      t.eq({ asked, notes, runs }, { {}, 0, 0 })
    end)
  end,

  ["a Lean buffer gets lean.nvim's keys, each with an icon"] = function(t)
    local M, I = require("ach.managed"), require("ach.icons")
    local groups = {}
    tidy(function()
      local buf
      with({
        {
          package.loaded,
          "which-key",
          {
            add = function(spec)
              vim.list_extend(groups, spec)
            end,
          },
        },
      }, function()
        buf = named(t.tmpdir() .. "/Main.lean", "lean")
      end)
      local lua = named(t.tmpdir() .. "/main.lua", "lua")
      t.eq(#M.lean, 15, "lean.nvim's fifteen suggested keys")
      local bad = {}
      vim.api.nvim_buf_call(buf, function()
        for _, k in ipairs(M.lean) do
          local map = vim.fn.maparg(vim.g.maplocalleader .. k[1], "n", false, true)
          if map.buffer ~= 1 or map.desc ~= k[3] then
            bad[#bad + 1] = k[1] .. " is not set in the Lean buffer"
          end
          if not I.key(k[3]) then
            bad[#bad + 1] = k[3] .. " has no icon"
          end
        end
      end)
      t.eq(bad, {})
      vim.api.nvim_buf_call(lua, function()
        t.eq(vim.fn.maparg(vim.g.maplocalleader .. "i", "n"), "", "no Lean keys in a Lua buffer")
      end)
      t.ok(I.group("diff pins"), "the diff pins group has an icon")
      t.eq(groups, { { "<localleader>d", group = "diff pins", icon = I.group("diff pins"), buffer = buf } })
    end)
  end,
}
```

Every test opens its buffers with `named`, which sets a file type on a buffer that is never read, so lean.nvim, which loads on reading a `.lean` file, stays unloaded, and the installer's dry run leaves each buffer alone. rustaceanvim and haskell-tools are not lazy, so their own `ftplugin` files do run when a Rust or Haskell buffer opens; with their automatic start off, they create their commands and nothing more. The failed-install test finishes its second install too, so the module's one-install-at-a-time flag is clear before the next test.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_managed`
Expected: `0 passed, 12 failed, 0 need a person, 0 skipped`, exit 1. The first fails on `rustaceanvim's own start`, because nothing has set `vim.g.rustaceanvim` yet, and the other eleven on `module 'ach.managed' not found`.

- [ ] **Write the managed starters**

`lua/ach/managed.lua`:

```lua
-- Rust, Haskell, Java, Scala and Lean, whose servers are started by a plugin
-- of their own rather than by vim.lsp.enable. Each plugin's automatic start
-- is off, and the installer calls M.start once a buffer's packages are in
-- place, so each server starts after its program exists, and only once.
local M = {}

-- The name each plugin gives its client.
M.clients = {
  rustaceanvim = "rust-analyzer",
  ["haskell-tools.nvim"] = "haskell-tools.nvim",
  ["nvim-jdtls"] = "jdtls",
  ["nvim-metals"] = "metals",
  ["lean.nvim"] = "leanls",
}

-- Where Mason keeps the files its packages share with other programs, such
-- as the jars jdtls loads.
M.share = vim.fn.stdpath("data") .. "/mason/share"

-- Metals, installed by Coursier into the data folder.
M.metals_program = vim.fn.stdpath("data") .. "/metals/metals"

-- lean.nvim's suggested keys, after the local leader: key, command,
-- description.
M.lean = {
  { "i", "LeanInfoviewToggle", "Lean Infoview" },
  { "<Tab>", "LeanGotoInfoview", "Go to Infoview" },
  { "v", "LeanInfoviewViewOptions", "Infoview Options" },
  { "x", "LeanInfoviewAddPin", "Add Pin" },
  { "c", "LeanInfoviewClearPins", "Clear Pins" },
  { "p", "LeanInfoviewPinTogglePause", "Pause Pins" },
  { "dx", "LeanInfoviewSetDiffPin", "Set Diff Pin" },
  { "dc", "LeanInfoviewClearDiffPin", "Clear Diff Pins" },
  { "dd", "LeanInfoviewToggleAutoDiffPin", "Auto Diff" },
  { "dt", "LeanInfoviewToggleNoClearAutoDiffPin", "Auto Diff, Clearing Pins" },
  { "w", "LeanInfoviewEnableWidgets", "Enable Widgets" },
  { "W", "LeanInfoviewDisableWidgets", "Disable Widgets" },
  { "s", "LeanInfoviewAcceptSuggestion", "Accept Suggestion" },
  { "\\", "LeanAbbreviationsReverseLookup", "How to Type This Symbol" },
  { "r", "LeanRestartFile", "Restart Lean for This File" },
}

-- True when any of the programs is on the path.
local function executable(...)
  for _, name in ipairs({ ... }) do
    if vim.fn.executable(name) == 1 then
      return true
    end
  end
  return false
end

-- Runs fn with buf as the current buffer, for the plugins that attach to
-- whichever buffer is current, then puts the old one back.
local function in_buffer(buf, fn)
  vim.api.nvim_buf_call(buf, fn)
end

-- A Java project's root: the nearest folder holding a build wrapper or a
-- repository, so a multi-module build is one project; failing that, the
-- nearest build file; failing that, the file's own folder.
function M.jdtls_root(buf)
  return vim.fs.root(buf, { "gradlew", "mvnw", ".git" })
    or vim.fs.root(buf, { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" })
    or vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
end

-- The test runner jar and the coverage agent sit beside java-test's bundles
-- but are not bundles themselves; jdtls refuses to load them.
local not_bundles = {
  ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
  ["jacocoagent.jar"] = true,
}

-- The jars jdtls loads as plugins: the debug adapter's and java-test's, each
-- when Mason has installed it.
function M.jdtls_bundles()
  local bundles = {}
  local debug = M.share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
  if vim.uv.fs_stat(debug) then
    bundles[1] = debug
  end
  local jars = vim.fn.glob(M.share .. "/java-test/*.jar", true, true)
  table.sort(jars)
  for _, jar in ipairs(jars) do
    if not not_bundles[vim.fs.basename(jar)] then
      bundles[#bundles + 1] = jar
    end
  end
  return bundles
end

-- jdtls's configuration for buf. Its workspace data goes in the cache, in a
-- folder named for the project and a hash of its full path, so two projects
-- with the same folder name keep separate indexes. Lombok is loaded as an
-- agent when Mason has it, so its generated methods resolve.
function M.jdtls_config(buf)
  local root = M.jdtls_root(buf)
  local data = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
  local cmd = { "jdtls" }
  local lombok = M.share .. "/jdtls/lombok.jar"
  if vim.uv.fs_stat(lombok) then
    cmd[#cmd + 1] = "--jvm-arg=-javaagent:" .. lombok
  end
  vim.list_extend(cmd, { "-data", data })
  return {
    cmd = cmd,
    root_dir = root,
    capabilities = require("ach.lsp").capabilities(),
    init_options = { bundles = M.jdtls_bundles() },
  }
end

local installing = false

-- Installs Metals with Coursier, then starts it in every loaded Scala buffer.
-- One install at a time; a Scala buffer opened meanwhile waits for it. With
-- Coursier missing it does nothing, since the installer's runtime check has
-- already said how to install it.
local function install_metals()
  if installing or vim.fn.executable("coursier") ~= 1 then
    return
  end
  installing = true
  vim.notify("Installing Metals for Scala; it starts when the install finishes")
  local cmd = { "coursier", "install", "--install-dir", vim.fs.dirname(M.metals_program), "metals" }
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      installing = false
      if res.code ~= 0 then
        local lines = vim.split(vim.trim(res.stderr or ""), "\n")
        vim.notify("Metals did not install: " .. lines[#lines], vim.log.levels.ERROR)
        return
      end
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local e = vim.api.nvim_buf_is_loaded(b) and require("ach.lang").for_ft(vim.bo[b].filetype)
        if e and e.managed == "nvim-metals" then
          M.start(b, e, { install = false })
        end
      end
    end)
  end)
end

local starters = {
  rustaceanvim = function(buf)
    if executable("rust-analyzer") then
      require("rustaceanvim.lsp").start(buf)
    end
  end,

  ["haskell-tools.nvim"] = function(buf)
    if executable("haskell-language-server-wrapper", "haskell-language-server") then
      in_buffer(buf, function()
        require("haskell-tools").lsp.start(buf)
      end)
    end
  end,

  ["nvim-jdtls"] = function(buf)
    if executable("jdtls") then
      require("jdtls").start_or_attach(M.jdtls_config(buf), nil, { bufnr = buf })
    end
  end,

  ["nvim-metals"] = function(buf, opts)
    if vim.fn.executable(M.metals_program) == 1 then
      local metals = require("metals")
      local config = metals.bare_config()
      config.settings = { metalsBinaryPath = M.metals_program }
      config.capabilities = require("ach.lsp").capabilities()
      in_buffer(buf, function()
        metals.initialize_or_attach(config)
      end)
    elseif opts.install ~= false then
      install_metals()
    end
  end,

  -- Requiring lean loads lean.nvim, if a .lean file has not already, which
  -- puts its lsp/leanls.lua on the runtime path.
  ["lean.nvim"] = function()
    if executable("lean") then
      require("lean")
      vim.lsp.enable("leanls")
    end
  end,
}

-- Starts the server of buf's managed language, unless buf is not a file or
-- already has that client. A missing Metals is installed first, unless
-- opts.install is false.
function M.start(buf, entry, opts)
  local start = starters[entry.managed]
  if not start or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  if #vim.lsp.get_clients({ bufnr = buf, name = M.clients[entry.managed] }) > 0 then
    return
  end
  start(buf, opts or {})
end

-- Sets the Lean keys in buf, and names the diff-pin keys for which-key.
function M.lean_keys(buf)
  for _, k in ipairs(M.lean) do
    vim.keymap.set("n", "<localleader>" .. k[1], "<Cmd>" .. k[2] .. "<CR>", { buffer = buf, desc = k[3] })
  end
  require("which-key").add({
    { "<localleader>d", group = "diff pins", icon = require("ach.icons").group("diff pins"), buffer = buf },
  })
end

local did_setup = false

-- Turns off each plugin's own start before any of them loads, and creates
-- the hooks for Lean's keys and for a Scala file's first write.
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  vim.g.rustaceanvim = {
    server = {
      auto_attach = false,
      default_settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
    },
  }
  vim.g.haskell_tools = { hls = { auto_attach = false } }
  vim.g.lean_config = { lsp = { enable = false } }

  local group = vim.api.nvim_create_augroup("ach_managed", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "lean",
    callback = function(ev)
      M.lean_keys(ev.buf)
    end,
  })
  -- nvim-metals attaches only to a file that is on disk, so a new Scala file
  -- gets Metals when it is first written. A save never installs it; opening
  -- the file already tried.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local e = require("ach.lang").for_ft(vim.bo[ev.buf].filetype)
      if e and e.managed == "nvim-metals" then
        M.start(ev.buf, e, { install = false })
      end
    end,
  })
end

return M
```

Clippy runs every check that `cargo check` does and its lints besides, so it replaces rather than adds to the check rust-analyzer runs on save. Nothing else of rust-analyzer's is changed: LazyVim also turns on every Cargo feature, but a crate whose features exclude one another then fails to build at all, and a project that wants its features on can say so in its own `rust-analyzer.json`, which rustaceanvim reads.

- [ ] **Write the plugin specs**

`lua/ach/plugins/managed.lua`:

```lua
-- The plugins that start five languages' servers themselves. ach.managed
-- turns each one's own start off and starts it once the server's program is
-- installed.
return {
  -- Rust and Haskell. Neither may be lazy-loaded: each does its work from an
  -- ftplugin, which must be on the runtime path before the first file of its
  -- type opens, and each loads the rest of itself only when first used.
  { "mrcjkb/rustaceanvim", version = "^9", lazy = false },
  { "mrcjkb/haskell-tools.nvim", version = "^11", lazy = false },

  -- Java and Scala, loaded when ach.managed first requires them.
  { "mfussenegger/nvim-jdtls", commit = "6e9d953f0b82bccdb834cfde0e893f3119c22592" },
  { "scalameta/nvim-metals", commit = "a4b20656bf1014404dd63bf9fd5f22fcc50fee52" },

  -- Lean, loaded as a .lean file is read or created, before its file type is
  -- set, so its own ftplugin and commands are there when the type is.
  {
    "Julian/lean.nvim",
    commit = "42186878a385ab021296e8f8024521d11a661754",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
  },
}
```

The foundation's `defaults = { lazy = true, version = false }` covers nvim-jdtls and nvim-metals, so they need no `lazy` of their own, and `version` or `commit` on a spec overrides the default of following the main branch.

- [ ] **Hand managed languages to their plugins**

In `lua/ach/install.lua`, replace the `M.ready` written by the language-server task, with its comment:

```lua
-- Called once a buffer's packages are installed, or have failed: enables the
-- file type's servers whose programs are now on the path. The
-- managed-languages task adds the languages whose own plugin starts the
-- server.
function M.ready(buf, ft, entry)
  require("ach.lsp").enable_for(ft)
end
```

with:

```lua
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
```

- [ ] **Load it at startup**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added, Homebrew's Java,
-- Ruby and the toolchain folders put on the path, spelling and Harper's
-- settings put in place, the managed languages' plugins told not to start
-- their own servers, and the installer's hooks created before lazy.nvim
-- starts, so a file named on the command line is recognised, checked, and
-- gets its parsers, tools and server when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.runtimes").setup()
require("ach.grammar").setup()
require("ach.managed").setup()
require("ach.install").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

The three globals must be set before lazy.nvim loads rustaceanvim and haskell-tools, which are not lazy and read them as soon as their first file opens.

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add these lines to `M.keys`, directly above `-- Keys added by later tasks go above this line.`. Every glyph they name is already in the database. The infoview's own keys are blue, pins yellow, diff pins purple, and the rest take the colour of what they act on.

```lua
  ["Lean Infoview"] = { "windows.far_right", "blue" },
  ["Go to Infoview"] = { "windows.go_right", "blue" },
  ["Infoview Options"] = { "actions.tune", "blue" },
  ["Add Pin"] = { "actions.pin", "yellow" },
  ["Clear Pins"] = { "actions.unpin", "yellow" },
  ["Pause Pins"] = { "actions.pause", "yellow" },
  ["Set Diff Pin"] = { "git.diff", "purple" },
  ["Clear Diff Pins"] = { "actions.unpin", "purple" },
  ["Auto Diff"] = { "files.compare", "purple" },
  ["Auto Diff, Clearing Pins"] = { "files.compare", "purple" },
  ["Enable Widgets"] = { "dap.widgets", "cyan" },
  ["Disable Widgets"] = { "kinds.Component", "grey" },
  ["Accept Suggestion"] = { "code.action", "green" },
  ["How to Type This Symbol"] = { "search.keymaps", "cyan" },
  ["Restart Lean for This File"] = { "actions.restart", "red" },
```

Then add this line to `M.groups`, directly above `-- Groups added by later tasks go above this line.`:

```lua
  ["diff pins"] = { "git.diff", "purple" },
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones rustaceanvim at its newest 9.x release, haskell-tools.nvim at its newest 11.x release, and nvim-jdtls, nvim-metals and lean.nvim at the commits named, and adds all five to `lazy-lock.json`. No server is installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 12 `test_managed` tests pass, along with every earlier test, the foundation's icon tests included: each new key description is its own which-key rule. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/managed.lua lua/ach/plugins/managed.lua tests/test_managed.lua
git commit --only lua/ach/managed.lua lua/ach/plugins/managed.lua lua/ach/install.lua lua/ach/init.lua lua/ach/icons.lua tests/test_managed.lua lazy-lock.json -m "feat(managed): start Rust, Haskell, Java, Scala and Lean through their own plugins once their servers are installed"
```

---

### Task: Debugging

**Files:**
- Create: `lua/ach/dap.lua`, `lua/ach/plugins/dap.lua`
- Modify: `lua/ach/managed.lua` (the Java and Scala starters, and `M.setup`), `tests/test_managed.lua` (one stand-in), `lua/ach/icons.lua` (twenty-three keys), `lazy-lock.json`
- Test: `tests/test_dap.lua`

**Interfaces:**
- Consumes: `require("ach.icons")` (`get(ref)`, `key(desc)`); `require("ach.managed")` (`share`, `metals_program`, `start(buf, entry)`, and the starters and `M.setup` the managed-languages task wrote); `require("ach.lang").for_ft(ft)`; `require("ach.lsp").capabilities()`; the `mason-org/mason.nvim` spec from the Mason task; the foundation's `<leader>d` which-key group, named `debug`.
- Produces:
  - `require("ach.dap")`: `bin: string`, Mason's folder of programs; `signs: table<string, string[]>`; `define_signs()`; `skip: table<string, string>`, the Mason adapters something else sets up, each with what does; `handlers(): table`; `lldb: table`; `lldb_filetypes: string[]`; `c_configurations(): table[]`; `js_adapter(): table`; `node_adapter(callback, config)`; `js_filetypes: string[]`; `js_configurations(): table[]`; `scala_configurations(): table[]`; `hdb_missing: string`; `haskell_configs(bufnr): table[]`; `java()`; `ask_args(config): table`; `tests: table<ft, { method: fun(), class: fun() }>`; `debug_test(kind: "method"|"class")`; `keys: { [1]: string, [2]: fun(), [3]: string, [4]: string[]? }[]`, each debug key's left-hand side, action, description and modes; `ui()`; `setup()`.
  - The health task reports `xcrun lldb-dap` and `hdb`, and prints `hdb_missing` when hdb is not on the path.

nvim-dap is Neovim's client for the Debug Adapter Protocol, the protocol VS Code uses to talk to a debugger. A debugger for each language runs as a separate program, the adapter, and nvim-dap sends it the same few requests whatever the language: set a breakpoint here, start this program, step, show the variables. So one set of keys debugs every language that has an adapter, and the work of this task is deciding where each adapter comes from and who tells nvim-dap about it.

| Languages | Adapter | Where it comes from | Set up by |
| --- | --- | --- | --- |
| C, C++, Objective-C, Swift, Zig | `lldb-dap` | Xcode or its Command Line Tools, run as `xcrun lldb-dap` | this module |
| Rust | `codelldb` | Mason | rustaceanvim |
| Python | debugpy | Mason | nvim-dap-python |
| JavaScript, TypeScript | js-debug | Mason's `js-debug-adapter` | this module |
| Java | java-debug and java-test | Mason, loaded into jdtls as bundles | nvim-jdtls, with hot code replace from this module |
| Scala | Metals' own debug server | Metals | nvim-metals, when this module's `on_attach` asks |
| Haskell | `hdb` | a release on GitHub, installed by hand | haskell-tools.nvim, through a provider in this module |
| Go | delve | Mason | mason-nvim-dap |
| Kotlin | kotlin-debug-adapter | Mason | mason-nvim-dap |
| C#, F# | netcoredbg | Mason | mason-nvim-dap |
| PHP | php-debug-adapter | Mason | mason-nvim-dap |
| Elixir | elixir-ls's debugger | Mason, with the language server | mason-nvim-dap |

The C family goes to Apple's `lldb-dap` rather than to Mason's `codelldb`. `lldb-dap` is the LLDB that ships with the compiler Xcode builds with, it is signed by Apple, and it understands Swift, which the LLDB inside `codelldb` does not. Rust stays on `codelldb`, because rustaceanvim drives it and knows how to show Rust's own types through it. Zig is compiled by its own LLVM rather than Apple's, but it writes the same DWARF debug information, which is all LLDB reads.

mason-nvim-dap reads which debug packages Mason has installed and sets up an adapter and a couple of launch choices for each, now and whenever another installs. The language table already installs each language's adapter with its tools, so mason-nvim-dap is told to install nothing itself, and its handlers skip the six adapters something else sets up. Python's goes to nvim-dap-python, which adds launch choices that find the project's virtual environment and runs the test under the cursor. `codelldb` goes to rustaceanvim, Java's two to nvim-jdtls, and js-debug to this module, which writes the adapter with the loopback address spelled out rather than leaving `localhost` to resolve to IPv6 first. Haskell's Mason package, haskell-debug-adapter, builds with Cabal against an old GHC, so the language table no longer installs it, and the handler skips it in case it was installed by hand.

Haskell debugs through `hdb`, Well-Typed's debugger, which haskell-tools.nvim supports and Mason does not carry. It needs the GHC it was built with, 9.14 or later, on the path. haskell-tools searches the project for launch choices as each Haskell file opens, which would load nvim-dap with every Haskell file. That search is turned off, and this module gives nvim-dap a configuration provider instead, a function nvim-dap calls for launch choices each time a session starts. nvim-dap calls its providers in name order, so `ach.haskell` runs before `dap.global`, which reads `dap.configurations.haskell`; the provider runs haskell-tools' search, which fills that list, and returns nothing itself. Without `hdb` it says once where to get it.

nvim-jdtls registers Java's debugger by itself as jdtls attaches, from an `LspAttach` hook in its own plugin file. Neovim runs `LspAttach` hooks before a configuration's `on_attach`, and nvim-jdtls registers the debugger only once, so the hot code replace option passed through `start_or_attach` would arrive after the debugger was already registered without it. The Java starter therefore registers it first, with `hotcodereplace = "auto"`, whenever the debug jar is installed. Hot code replace loads a changed method into the running program each time the file is saved, so a fix can be tried without restarting the session.

Every key sits under `<leader>d`, where the foundation already names the `debug` group:

| Key | Description | What it does |
| --- | --- | --- |
| `Space d b` | Toggle Breakpoint | Sets or clears a breakpoint on the line |
| `Space d B` | Conditional Breakpoint | Asks for a condition, such as `i > 3`, and stops only when it holds |
| `Space d L` | Log Point | Asks for a message and prints it each time the line runs, without stopping |
| `Space d c` | Start or Continue | Starts a session, offering the launch choices, or runs on to the next breakpoint |
| `Space d a` | Start with Arguments | Starts a session after asking for the program's command-line arguments |
| `Space d C` | Run to Cursor | Runs on to the cursor's line |
| `Space d g` | Jump to Line Without Running | Moves the next statement to the cursor's line, skipping what lies between |
| `Space d i` | Step Into | Runs one step, entering a function it calls |
| `Space d O` | Step Over | Runs one step, treating a call as one step |
| `Space d o` | Step Out | Runs to the end of the current function |
| `Space d k` | Frame Up | Shows the function that called this one |
| `Space d j` | Frame Down | Shows the function this one called |
| `Space d l` | Rerun Last Debug | Starts the last session again with the same choices |
| `Space d R` | Restart Debugging | Restarts the running session |
| `Space d P` | Pause Debugging | Stops the running program where it is |
| `Space d t` | Stop Debugging | Ends the session |
| `Space d r` | Debug Console | Opens or closes the console, where an expression is typed and evaluated |
| `Space d s` | Debug Sessions | Lists the running sessions, to switch between them |
| `Space d w` | Inspect Value | Shows the value under the cursor in a floating window |
| `Space d e` | Evaluate Expression | Evaluates the word under the cursor, or the selection |
| `Space d u` | Debug Interface | Opens or closes the panes of variables, watches, the call stack and breakpoints |
| `Space d m` | Debug Nearest Test | Debugs the test at the cursor, in Python, Java and Rust |
| `Space d M` | Debug Test Class | Debugs every test in the class, or picks from everything Rust can debug |

LazyVim's debug keys are the starting point. Four are added: the log point, restart, and the two test keys, which LazyVim scatters over each language's own extra and which here mean the same thing in every language that can debug a test. A condition or log message prompt that is cancelled, with Escape or Ctrl-C, sets nothing, where a bare `vim.fn.input` would set a breakpoint with an empty condition.

- [ ] **Write the failing tests**

`tests/test_dap.lua`:

```lua
-- The debugger. Every plugin it talks to is a stand-in in package.loaded,
-- so no test loads nvim-dap, its interface or a language's plugin, and no
-- test starts a debug adapter.
local opened = {}

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

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- A buffer called path, of file type ft, that is never read from disk, so it
-- fires no BufReadPre and loads no plugin.
local function named(path, ft)
  local buf = vim.api.nvim_create_buf(true, false)
  opened[#opened + 1] = buf
  vim.api.nvim_buf_set_name(buf, path)
  vim.bo[buf].filetype = ft
  return buf
end

-- A stand-in for vim.fn.executable that finds only the programs in found,
-- read at each call, so a test can install one partway through.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

local function entry(ft)
  return require("ach.lang").for_ft(ft)
end

-- A stand-in for nvim-dap, holding the tables setup() writes into.
local function fake_dap()
  return {
    adapters = {},
    configurations = {},
    providers = { configs = {} },
    listeners = { before = { attach = {}, launch = {}, event_terminated = {}, event_exited = {} } },
  }
end

-- The stand-ins setup() needs, each noting in got what it was given.
local function stand_ins(dap, got)
  return {
    { package.loaded, "dap", dap },
    {
      package.loaded,
      "mason-nvim-dap",
      {
        setup = function(opts)
          got.mason = opts
          got.c_before_mason = dap.configurations.c
        end,
        default_setup = function() end,
      },
    },
    {
      package.loaded,
      "dap-python",
      {
        setup = function(path)
          got.python = path
        end,
      },
    },
    {
      package.loaded,
      "dapui",
      {
        setup = function(opts)
          got.ui = opts
        end,
        open = function()
          got.opened = (got.opened or 0) + 1
        end,
        close = function()
          got.closed = (got.closed or 0) + 1
        end,
      },
    },
    {
      package.loaded,
      "nvim-dap-virtual-text",
      {
        setup = function(opts)
          got.virtual_text = opts
        end,
      },
    },
  }
end

local function names(configurations)
  return vim.tbl_map(function(c)
    return c.name
  end, configurations or {})
end

-- The action of the debug key whose left-hand side is lhs.
local function action(lhs)
  for _, k in ipairs(require("ach.dap").keys) do
    if k[1] == lhs then
      return k[2]
    end
  end
  error("no debug key " .. lhs)
end

return {
  ["the breakpoint signs draw their icons"] = function(t)
    local D, I = require("ach.dap"), require("ach.icons")
    D.define_signs()
    t.eq(vim.tbl_count(D.signs), 5, "every sign nvim-dap draws")
    for name, s in pairs(D.signs) do
      local def = vim.fn.sign_getdefined(name)[1]
      t.ok(def ~= nil, name .. " is defined")
      t.eq(vim.trim(def.text), I.get(s[1]), name .. "'s icon")
      t.eq(def.texthl, s[2], name .. "'s colour")
    end
    t.eq(vim.fn.sign_getdefined("DapStopped")[1].linehl, "DapStoppedLine", "the stopped line is marked across")
    t.ok(next(vim.api.nvim_get_hl(0, { name = "DapStoppedLine" })) ~= nil, "the stopped line has a colour")
  end,

  ["Mason's adapters are set up, except those something else sets up"] = function(t)
    local D = require("ach.dap")
    local given = {}
    with({
      {
        package.loaded,
        "mason-nvim-dap",
        {
          default_setup = function(config)
            given[#given + 1] = config.name
          end,
        },
      },
    }, function()
      local handlers = D.handlers()
      -- mason-nvim-dap calls an adapter's own handler, or the default when it has none.
      for _, name in ipairs({ "delve", "python", "kotlin", "codelldb", "javadbg", "coreclr", "javatest", "php", "haskell", "js" }) do
        local handler = handlers[name] or handlers[1]
        handler({ name = name })
      end
    end)
    t.eq(given, { "delve", "kotlin", "coreclr", "php" })
    local skipped = vim.tbl_keys(D.skip)
    table.sort(skipped)
    t.eq(skipped, { "codelldb", "haskell", "javadbg", "javatest", "js", "python" })
  end,

  ["setup writes the adapters and launch choices this module owns"] = function(t)
    local D = require("ach.dap")
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function()
      D.setup()
    end)
    t.eq(dap.adapters.lldb, { type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb" })
    for _, ft in ipairs({ "c", "cpp", "objc", "objcpp", "swift", "zig" }) do
      t.eq(names(dap.configurations[ft]), { "Launch a Program", "Attach to a Running Program" }, ft)
      t.eq(dap.configurations[ft][1].type, "lldb", ft .. " debugs through lldb-dap")
    end
    local js = dap.adapters["pwa-node"]
    t.eq(js.executable, { command = D.bin .. "/js-debug-adapter", args = { "${port}", "127.0.0.1" } })
    t.eq(js.host, "127.0.0.1", "the adapter and the editor meet on the loopback address")
    for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
      t.eq(names(dap.configurations[ft]), { "Launch This File", "Attach to a Running Node" }, ft)
    end
    t.eq(got.python, D.bin .. "/debugpy-adapter", "nvim-dap-python runs Mason's debugpy")
    t.eq(
      vim.tbl_map(function(c)
        return c.metals.runType
      end, dap.configurations.scala),
      { "runOrTestFile", "testTarget" }
    )
    t.eq(dap.providers.configs["ach.haskell"], D.haskell_configs)
    t.ok("ach.haskell" < "dap.global", "nvim-dap asks the Haskell provider before it reads dap.configurations")
    t.eq(got.mason.automatic_installation, false, "mason-nvim-dap installs nothing itself")
    t.eq(got.mason.ensure_installed, {})
    t.eq(type(got.mason.handlers[1]), "function")
    t.ok(got.virtual_text ~= nil, "values are drawn beside the code")
  end,

  ["a launch.json that names node reaches js-debug as pwa-node"] = function(t)
    local dap, got = fake_dap(), {}
    local reached, config = nil, { type = "node", request = "launch", name = "From launch.json" }
    with(stand_ins(dap, got), function()
      require("ach.dap").setup()
      dap.adapters.node(function(adapter)
        reached = adapter
      end, config)
    end)
    t.eq(reached, dap.adapters["pwa-node"])
    t.eq(config.type, "pwa-node")
  end,

  ["Mason's launch choices are added to these, not replaced by them"] = function(t)
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function()
      require("ach.dap").setup()
    end)
    t.ok(got.c_before_mason ~= nil, "the C launch choices exist before mason-nvim-dap extends them")
  end,

  ["the debug interface opens as a session starts and closes as it ends"] = function(t)
    local I = require("ach.icons")
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function()
      require("ach.dap").setup()
      dap.listeners.before.launch.ach()
      dap.listeners.before.attach.ach()
      dap.listeners.before.event_terminated.ach()
      dap.listeners.before.event_exited.ach()
    end)
    t.eq({ got.opened, got.closed }, { 2, 2 })
    t.eq(got.ui.controls.icons.play, I.get("dap.continue"), "the interface's buttons come from the icon database")
    t.eq(got.ui.controls.icons.terminate, I.get("dap.terminate"))
  end,

  ["the Haskell provider leaves other files alone, and says once how to get hdb"] = function(t)
    local D = require("ach.dap")
    local notes, searched = {}, 0
    tidy(function()
      local lua = named(t.tmpdir() .. "/init.lua", "lua")
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      with({
        { vim.fn, "executable", only({}) },
        {
          vim,
          "notify_once",
          function(msg, level)
            notes[#notes + 1] = { msg, level }
          end,
        },
        {
          package.loaded,
          "haskell-tools",
          {
            dap = {
              discover_configurations = function()
                searched = searched + 1
              end,
            },
          },
        },
      }, function()
        t.eq(D.haskell_configs(lua), {}, "a Lua file")
        t.eq(D.haskell_configs(hs), {}, "a Haskell file without hdb")
      end)
    end)
    t.eq(notes, { { D.hdb_missing, vim.log.levels.WARN } })
    t.eq(searched, 0)
    t.ok(D.hdb_missing:find("well-typed/haskell-debugger", 1, true) ~= nil, "the message says where hdb comes from")
  end,

  ["with hdb, the Haskell provider fills in the project's launch choices"] = function(t)
    local D = require("ach.dap")
    local asked = {}
    tidy(function()
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      with({
        { vim.fn, "executable", only({ hdb = true }) },
        {
          package.loaded,
          "haskell-tools",
          {
            dap = {
              discover_configurations = function(buf)
                asked[#asked + 1] = buf
              end,
            },
          },
        },
      }, function()
        t.eq(D.haskell_configs(hs), {}, "the search fills dap.configurations.haskell, which dap.global reads")
      end)
      t.eq(asked, { hs })
    end)
  end,

  ["haskell-tools does not search for launch choices as a file opens"] = function(t)
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "dap", "auto_discover"), false)
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "hls", "auto_attach"), false, "its own start stays off")
  end,

  ["Java's debugger is registered, with hot code replace, before jdtls starts"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local share = t.tmpdir()
    local jar = share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
    vim.fn.mkdir(vim.fs.dirname(jar), "p")
    vim.fn.writefile({}, jar)
    local order, opts = {}, nil
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.java", "java")
      with({
        { M, "share", share },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function()
            return {}
          end,
        },
        {
          package.loaded,
          "jdtls.dap",
          {
            setup_dap = function(o)
              order[#order + 1] = "debugger"
              opts = o
            end,
          },
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function()
              order[#order + 1] = "jdtls"
            end,
          },
        },
      }, function()
        M.start(buf, entry("java"))
      end)
    end)
    t.eq(order, { "debugger", "jdtls" })
    t.eq(opts, { hotcodereplace = "auto" })
  end,

  ["without the debug jar, jdtls starts with no debugger registered"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local order = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.java", "java")
      with({
        { M, "share", t.tmpdir() },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function()
            return {}
          end,
        },
        {
          package.loaded,
          "jdtls.dap",
          {
            setup_dap = function()
              order[#order + 1] = "debugger"
            end,
          },
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function()
              order[#order + 1] = "jdtls"
            end,
          },
        },
      }, function()
        M.start(buf, entry("java"))
      end)
    end)
    t.eq(order, { "jdtls" })
  end,

  ["Metals registers Scala's debugger as it attaches"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local program = t.tmpdir() .. "/metals"
    local config, registered = nil, 0
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only({ [program] = true }) },
        {
          L,
          "capabilities",
          function()
            return {}
          end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function()
              return {}
            end,
            initialize_or_attach = function(c)
              config = c
            end,
            setup_dap = function()
              registered = registered + 1
            end,
          },
        },
      }, function()
        M.start(buf, entry("scala"))
        t.eq(type(config and config.on_attach), "function", "the Metals configuration has an on_attach")
        config.on_attach({}, buf)
      end)
    end)
    t.eq(registered, 1)
  end,

  ["starting with arguments asks for them, offering the current ones"] = function(t)
    local D = require("ach.dap")
    local asked
    local original = { type = "python", request = "launch", name = "File", args = { "--fast", "in.txt" } }
    with({
      {
        vim.fn,
        "input",
        function(prompt, default)
          asked = { prompt, default }
          return "--slow out.txt"
        end,
      },
      {
        package.loaded,
        "dap.utils",
        {
          splitstr = function(s)
            return vim.split(s, " ")
          end,
        },
      },
    }, function()
      local config = D.ask_args(original)
      t.eq(original.args, { "--fast", "in.txt" }, "the configuration itself is left alone")
      t.eq(config.args(), { "--slow", "out.txt" })
    end)
    t.eq(asked, { "Run with arguments: ", "--fast in.txt" })
  end,

  ["Java's arguments stay one string"] = function(t)
    local D = require("ach.dap")
    local offered
    with({
      {
        vim.fn,
        "input",
        function(_, default)
          offered = default
          return "a b"
        end,
      },
    }, function()
      local config = D.ask_args({
        type = "java",
        args = function()
          return "x y"
        end,
      })
      t.eq(config.args(), "a b")
    end)
    t.eq(offered, "x y", "a configuration's arguments may be a function")
  end,

  ["debugging a test goes to the language's own runner"] = function(t)
    local D = require("ach.dap")
    local ran = {}
    local function note(what)
      return function(arg)
        ran[#ran + 1] = arg and (what .. " " .. arg) or what
      end
    end
    tidy(function()
      local files = {
        { "python", named(t.tmpdir() .. "/test_app.py", "python") },
        { "java", named(t.tmpdir() .. "/AppTest.java", "java") },
        { "rust", named(t.tmpdir() .. "/lib.rs", "rust") },
      }
      with({
        { package.loaded, "dap-python", { test_method = note("python method"), test_class = note("python class") } },
        { package.loaded, "jdtls.dap", { test_nearest_method = note("java method"), test_class = note("java class") } },
        { vim.cmd, "RustLsp", note("RustLsp") },
      }, function()
        for _, f in ipairs(files) do
          vim.api.nvim_buf_call(f[2], function()
            D.debug_test("method")
            D.debug_test("class")
          end)
        end
      end)
    end)
    t.eq(ran, { "python method", "python class", "java method", "java class", "RustLsp debug", "RustLsp debuggables" })
  end,

  ["a file type with no test debugging says so"] = function(t)
    local D = require("ach.dap")
    local notes = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/main.go", "go")
      with({
        {
          vim,
          "notify",
          function(msg, level)
            notes[#notes + 1] = { msg, level }
          end,
        },
      }, function()
        vim.api.nvim_buf_call(buf, function()
          D.debug_test("method")
        end)
      end)
    end)
    t.eq(#notes, 1)
    t.eq(notes[1][2], vim.log.levels.WARN)
    t.ok(notes[1][1]:find("go", 1, true) ~= nil, "the message names the file type: " .. tostring(notes[1][1]))
  end,

  ["a cancelled prompt sets no breakpoint"] = function(t)
    local set = {}
    ---@type string?
    local answer = ""
    with({
      {
        vim.fn,
        "input",
        function()
          if answer == nil then
            error("Keyboard interrupt")
          end
          return answer
        end,
      },
      {
        package.loaded,
        "dap",
        {
          set_breakpoint = function(...)
            set[#set + 1] = { ... }
          end,
        },
      },
    }, function()
      action("<leader>dB")()
      action("<leader>dL")()
      answer = nil
      action("<leader>dB")()
      action("<leader>dL")()
      answer = "i > 3"
      action("<leader>dB")()
      action("<leader>dL")()
    end)
    t.eq(set, { { "i > 3" }, { nil, nil, "i > 3" } }, "only the answered prompts set a breakpoint")
  end,

  ["every debug key is under <leader>d, once, with its own icon"] = function(t)
    local D, I = require("ach.dap"), require("ach.icons")
    local seen, bad = {}, {}
    for _, k in ipairs(D.keys) do
      if not vim.startswith(k[1], "<leader>d") then
        bad[#bad + 1] = k[1] .. " is outside <leader>d"
      end
      if seen[k[1]] then
        bad[#bad + 1] = k[1] .. " is set twice"
      end
      seen[k[1]] = true
      local icon = I.key(k[3])
      if not (icon and icon.icon) then
        bad[#bad + 1] = k[3] .. " has no icon"
      end
    end
    t.eq(bad, {})
    t.eq(#D.keys, 23)
    local spec = require("ach.plugins.dap")[1]
    t.eq(#spec.keys(), #D.keys, "each key loads nvim-dap")
  end,

  ["every debugger plugin is pinned"] = function(t)
    local spec = require("ach.plugins.dap")[1]
    local loose = {}
    for _, p in ipairs(vim.list_extend({ spec }, spec.dependencies)) do
      if not (p.commit or p.version) then
        loose[#loose + 1] = p[1]
      end
    end
    t.eq(loose, {})
    t.eq(#spec.dependencies, 5)
  end,
}
```

Every buffer is opened with `named`, as in the managed-languages tests. The Java, Rust and Haskell buffers fire their file types, so rustaceanvim's and haskell-tools' own `ftplugin` files run, and with their automatic start off they create their commands and nothing more. The installer's dry run never calls `install.ready`, so no server starts. `vim.cmd` builds a function for a command the first time it is indexed and keeps it, so standing in for `vim.cmd.RustLsp` and putting back what was there is safe.

- [ ] **Give the Java bundle test a stand-in**

The managed-languages test `Java gets a data folder per project, Lombok, and the debug and test bundles` writes the debug jar into its folder, so once the Java starter registers the debugger, that test would load the real nvim-jdtls and, through it, nvim-dap. In `tests/test_managed.lua`, in that test's `with` list, replace:

```lua
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function(config, opts, start_opts)
              calls[#calls + 1] = { config = config, opts = opts, start_opts = start_opts }
            end,
          },
        },
      }, function()
        M.start(one, entry("java"))
```

with:

```lua
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function(config, opts, start_opts)
              calls[#calls + 1] = { config = config, opts = opts, start_opts = start_opts }
            end,
          },
        },
        { package.loaded, "jdtls.dap", { setup_dap = function() end } },
      }, function()
        M.start(one, entry("java"))
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_dap`
Expected: `1 passed, 18 failed, 0 need a person, 0 skipped`, exit 1. The jar-less Java test passes already, since nothing registers a debugger yet; it is there to keep the registration tied to the jar. The `auto_discover` test fails on its first assertion, the Java registration test on `order`, the Metals test on its `on_attach`, the pinning test on `module 'ach.plugins.dap' not found`, and the other fourteen on `module 'ach.dap' not found`.

- [ ] **Write the debugger module**

`lua/ach/dap.lua`:

```lua
-- The debugger: the signs nvim-dap draws, which adapter each language debugs
-- through and who sets it up, the launch choices this configuration writes
-- itself, and the keys under <leader>d. nvim-dap's config calls setup(); the
-- Java starter in ach.managed calls java().
local I = require("ach.icons")

local M = {}

-- Where Mason links the programs it installs.
M.bin = vim.fn.stdpath("data") .. "/mason/bin"

-- nvim-dap's signs: the icon each draws, its colour, and, for the line the
-- program is stopped on, a highlight across the whole line.
M.signs = {
  DapBreakpoint = { "dap.Breakpoint", "DiagnosticError" },
  DapBreakpointCondition = { "dap.BreakpointCondition", "DiagnosticWarn" },
  DapBreakpointRejected = { "dap.BreakpointRejected", "DiagnosticError" },
  DapLogPoint = { "dap.LogPoint", "DiagnosticInfo" },
  DapStopped = { "dap.Stopped", "DiagnosticWarn", "DapStoppedLine" },
}

-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/dap/core.lua.
-- The stopped line borrows the selection's colour unless the colour scheme
-- gives it one of its own.
function M.define_signs()
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
  for name, s in pairs(M.signs) do
    vim.fn.sign_define(name, { text = I.get(s[1]) .. " ", texthl = s[2], linehl = s[3], numhl = s[3] })
  end
end

-- Mason's debug adapters that something else sets up, and what does. Every
-- other one installed, such as Go's delve, Kotlin's, .NET's netcoredbg and
-- PHP's, gets mason-nvim-dap's own adapter and launch choices.
M.skip = {
  python = "nvim-dap-python",
  codelldb = "rustaceanvim",
  javadbg = "nvim-jdtls",
  javatest = "nvim-jdtls",
  haskell = "haskell-tools.nvim, through hdb",
  js = "this module",
}

-- mason-nvim-dap's handlers: its default setup, and a handler that does
-- nothing for each adapter in M.skip.
function M.handlers()
  local handlers = {
    function(config)
      require("mason-nvim-dap").default_setup(config)
    end,
  }
  for name in pairs(M.skip) do
    handlers[name] = function() end
  end
  return handlers
end

-- Apple's lldb-dap, from Xcode or its Command Line Tools, for the languages
-- that write the DWARF debug information LLDB reads.
M.lldb = { type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb" }
M.lldb_filetypes = { "c", "cpp", "objc", "objcpp", "swift", "zig" }

-- Start a program picked from the files under the working folder that can be
-- run, or attach to one already running.
function M.c_configurations()
  return {
    {
      type = "lldb",
      request = "launch",
      name = "Launch a Program",
      program = function()
        return require("dap.utils").pick_file()
      end,
      cwd = "${workspaceFolder}",
      args = {},
      stopOnEntry = false,
    },
    {
      type = "lldb",
      request = "attach",
      name = "Attach to a Running Program",
      pid = function()
        return require("dap.utils").pick_process()
      end,
    },
  }
end

-- js-debug, Microsoft's debugger for Node, from Mason. It listens on a port
-- nvim-dap picks, on the loopback address only.
function M.js_adapter()
  return {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = { command = M.bin .. "/js-debug-adapter", args = { "${port}", "127.0.0.1" } },
  }
end

-- A launch.json written for VS Code often names the older "node" type, which
-- js-debug answers as "pwa-node".
function M.node_adapter(callback, config)
  config.type = "pwa-node"
  callback(require("dap").adapters["pwa-node"])
end

M.js_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

-- Run the current file under Node, or attach to a Node already running.
-- Node 23.6 and later run a TypeScript file directly.
function M.js_configurations()
  return {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch This File",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to a Running Node",
      processId = function()
        return require("dap.utils").pick_process()
      end,
      cwd = "${workspaceFolder}",
    },
  }
end

-- Metals' two ways to start: the file at the cursor, run or tested as Metals
-- sees fit, and every test in the build target.
function M.scala_configurations()
  return {
    { type = "scala", request = "launch", name = "Run or Test This File", metals = { runType = "runOrTestFile" } },
    { type = "scala", request = "launch", name = "Test This Build Target", metals = { runType = "testTarget" } },
  }
end

M.hdb_missing = "Debugging Haskell needs hdb, which Mason does not carry. Download it from "
  .. "https://github.com/well-typed/haskell-debugger/releases, put the top-level hdb on the path rather "
  .. "than bin/hdb, and install the GHC it was built with, 9.14 or later, with ghcup."

local haskell_filetypes = { haskell = true, lhaskell = true }

-- A configuration provider for nvim-dap. nvim-dap asks its providers in name
-- order, so this one runs before "dap.global" reads dap.configurations.haskell,
-- which haskell-tools' search fills from the project's executables and any
-- launch.json. It returns nothing itself.
function M.haskell_configs(bufnr)
  if not haskell_filetypes[vim.bo[bufnr].filetype] then
    return {}
  end
  if vim.fn.executable("hdb") ~= 1 then
    vim.notify_once(M.hdb_missing, vim.log.levels.WARN)
    return {}
  end
  require("haskell-tools").dap.discover_configurations(bufnr)
  return {}
end

-- Registers Java's debugger with hot code replace, which loads a changed
-- method into the running program each time its file is saved. nvim-jdtls
-- registers the debugger itself as jdtls attaches, without hot code replace,
-- and registers it only once, so this runs before jdtls starts. Without the
-- debug jar there is no debugger to register.
function M.java()
  local jar = require("ach.managed").share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
  if vim.uv.fs_stat(jar) then
    require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
  end
end

-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/dap/core.lua.
-- A copy of config that asks for the program's arguments as it starts,
-- offering its own. java-debug takes them as one string, every other adapter
-- as a list.
function M.ask_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local current = type(args) == "table" and table.concat(args, " ") or args
  config = vim.deepcopy(config)
  config.args = function()
    local answer = vim.fn.expand(vim.fn.input("Run with arguments: ", current))
    if config.type == "java" then
      return answer
    end
    return require("dap.utils").splitstr(answer)
  end
  return config
end

-- How to debug the test at the cursor ("method") and every test in its class
-- ("class"), in each language that can. Rust has no classes, so its second
-- key lists everything rustaceanvim can debug.
M.tests = {
  python = {
    method = function()
      require("dap-python").test_method()
    end,
    class = function()
      require("dap-python").test_class()
    end,
  },
  java = {
    method = function()
      require("jdtls.dap").test_nearest_method()
    end,
    class = function()
      require("jdtls.dap").test_class()
    end,
  },
  rust = {
    method = function()
      vim.cmd.RustLsp("debug")
    end,
    class = function()
      vim.cmd.RustLsp("debuggables")
    end,
  },
}

function M.debug_test(kind)
  local ft = vim.bo.filetype
  local run = M.tests[ft] and M.tests[ft][kind]
  if run then
    return run()
  end
  local what = kind == "method" and "the nearest test" or "a test class"
  vim.notify(
    ("Debugging %s works in Python, Java and Rust files, not in %s"):format(what, ft == "" and "this buffer" or ft),
    vim.log.levels.WARN
  )
end

-- The answer to prompt, or nil when it is empty or was cancelled with Escape
-- or Ctrl-C.
local function ask(prompt)
  local ok, answer = pcall(vim.fn.input, prompt)
  if ok and answer ~= "" then
    return answer
  end
end

-- The debug keys: left-hand side, action, description, and the modes when
-- not just normal mode.
M.keys = {
  {
    "<leader>db",
    function()
      require("dap").toggle_breakpoint()
    end,
    "Toggle Breakpoint",
  },
  {
    "<leader>dB",
    function()
      local condition = ask("Breakpoint condition: ")
      if condition then
        require("dap").set_breakpoint(condition)
      end
    end,
    "Conditional Breakpoint",
  },
  {
    "<leader>dL",
    function()
      local message = ask("Log message: ")
      if message then
        require("dap").set_breakpoint(nil, nil, message)
      end
    end,
    "Log Point",
  },
  {
    "<leader>dc",
    function()
      require("dap").continue()
    end,
    "Start or Continue",
  },
  {
    "<leader>da",
    function()
      require("dap").continue({ before = M.ask_args })
    end,
    "Start with Arguments",
  },
  {
    "<leader>dC",
    function()
      require("dap").run_to_cursor()
    end,
    "Run to Cursor",
  },
  {
    "<leader>dg",
    function()
      require("dap").goto_()
    end,
    "Jump to Line Without Running",
  },
  {
    "<leader>di",
    function()
      require("dap").step_into()
    end,
    "Step Into",
  },
  {
    "<leader>dO",
    function()
      require("dap").step_over()
    end,
    "Step Over",
  },
  {
    "<leader>do",
    function()
      require("dap").step_out()
    end,
    "Step Out",
  },
  {
    "<leader>dk",
    function()
      require("dap").up()
    end,
    "Frame Up",
  },
  {
    "<leader>dj",
    function()
      require("dap").down()
    end,
    "Frame Down",
  },
  {
    "<leader>dl",
    function()
      require("dap").run_last()
    end,
    "Rerun Last Debug",
  },
  {
    "<leader>dR",
    function()
      require("dap").restart()
    end,
    "Restart Debugging",
  },
  {
    "<leader>dP",
    function()
      require("dap").pause()
    end,
    "Pause Debugging",
  },
  {
    "<leader>dt",
    function()
      require("dap").terminate()
    end,
    "Stop Debugging",
  },
  {
    "<leader>dr",
    function()
      require("dap.repl").toggle()
    end,
    "Debug Console",
  },
  {
    "<leader>ds",
    function()
      local widgets = require("dap.ui.widgets")
      widgets.centered_float(widgets.sessions)
    end,
    "Debug Sessions",
  },
  {
    "<leader>dw",
    function()
      require("dap.ui.widgets").hover()
    end,
    "Inspect Value",
  },
  {
    "<leader>de",
    function()
      require("dapui").eval()
    end,
    "Evaluate Expression",
    { "n", "x" },
  },
  {
    "<leader>du",
    function()
      require("dapui").toggle({})
    end,
    "Debug Interface",
  },
  {
    "<leader>dm",
    function()
      M.debug_test("method")
    end,
    "Debug Nearest Test",
  },
  {
    "<leader>dM",
    function()
      M.debug_test("class")
    end,
    "Debug Test Class",
  },
}

-- nvim-dap-ui, its buttons drawn from the icon database, opening as a session
-- starts and closing as it ends.
function M.ui()
  local dap, dapui = require("dap"), require("dapui")
  dapui.setup({
    controls = {
      icons = {
        pause = I.get("dap.pause"),
        play = I.get("dap.continue"),
        step_into = I.get("dap.step_into"),
        step_over = I.get("dap.step_over"),
        step_out = I.get("dap.step_out"),
        run_last = I.get("dap.run_last"),
        terminate = I.get("dap.terminate"),
      },
    },
  })
  dap.listeners.before.attach.ach = function()
    dapui.open()
  end
  dap.listeners.before.launch.ach = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.ach = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.ach = function()
    dapui.close()
  end
end

-- Called once, as nvim-dap loads. This module's launch choices are written
-- before mason-nvim-dap runs, because mason-nvim-dap adds its own to each
-- file type's list rather than replacing it.
function M.setup()
  local dap = require("dap")
  M.define_signs()
  dap.adapters.lldb = M.lldb
  for _, ft in ipairs(M.lldb_filetypes) do
    dap.configurations[ft] = M.c_configurations()
  end
  dap.adapters["pwa-node"] = M.js_adapter()
  dap.adapters.node = M.node_adapter
  for _, ft in ipairs(M.js_filetypes) do
    dap.configurations[ft] = M.js_configurations()
  end
  dap.configurations.scala = M.scala_configurations()
  dap.providers.configs["ach.haskell"] = M.haskell_configs
  require("dap-python").setup(M.bin .. "/debugpy-adapter")
  require("mason-nvim-dap").setup({ automatic_installation = false, ensure_installed = {}, handlers = M.handlers() })
  M.ui()
  require("nvim-dap-virtual-text").setup({})
end

return M
```

nvim-dap-ui merges the options it is given into its defaults, so the two buttons left out, step back and disconnect, keep dap-ui's own icons. The database has no glyph for either, and neither appears unless an adapter supports it.

- [ ] **Write the plugin spec**

`lua/ach/plugins/dap.lua`:

```lua
-- The debugger: nvim-dap, its interface, values drawn beside the code, and
-- the adapters from Mason and for Python. All of them load with nvim-dap, on
-- its first key or command, or when a language's plugin asks for it; ach.dap
-- sets them up. nvim-dap's last release is from March 2025 and dap-ui's from
-- March 2024, and neither nvim-dap-virtual-text nor nvim-dap-python releases
-- at all, so each is pinned to the commit whose source was read. mason-nvim-dap
-- releases, and follows its 2.x line.
return {
  {
    "mfussenegger/nvim-dap",
    commit = "cfa2d58f4537aca6ca83e2de1a0d9f1491121264",
    dependencies = {
      { "rcarriga/nvim-dap-ui", commit = "cc9dd33aade7f20bae414d0cba163bc60d4d4b43" },
      { "nvim-neotest/nvim-nio", commit = "edcc181a875301dd21840189aa2f2f9ad69fc172" },
      { "theHamsta/nvim-dap-virtual-text", commit = "fbdb48c2ed45f4a8293d0d483f7730d24467ccb6" },
      { "jay-babu/mason-nvim-dap.nvim", version = "^2", dependencies = { "mason-org/mason.nvim" } },
      { "mfussenegger/nvim-dap-python", commit = "1808458eba2b18f178f990e01376941a42c7f93b" },
    },
    cmd = {
      "DapContinue",
      "DapToggleBreakpoint",
      "DapClearBreakpoints",
      "DapToggleRepl",
      "DapStepOver",
      "DapStepInto",
      "DapStepOut",
      "DapPause",
      "DapTerminate",
      "DapDisconnect",
      "DapRestartFrame",
      "DapNew",
      "DapEval",
      "DapSetLogLevel",
      "DapShowLog",
    },
    keys = function()
      local keys = {}
      for _, k in ipairs(require("ach.dap").keys) do
        keys[#keys + 1] = { k[1], k[2], desc = k[3], mode = k[4] }
      end
      return keys
    end,
    config = function()
      require("ach.dap").setup()
    end,
  },
}
```

The command list is every command nvim-dap's `plugin/dap.lua` creates at the pinned commit, so typing any of them loads nvim-dap first. nvim-nio is dap-ui's own dependency, the library it runs its asynchronous work on. Naming `mason-org/mason.nvim` again joins the Mason task's spec rather than adding a second one, so mason.nvim is set up before mason-nvim-dap reads its registry.

- [ ] **Hook up Java, Scala and Haskell**

In `lua/ach/managed.lua`, replace the Java starter:

```lua
  ["nvim-jdtls"] = function(buf)
    if executable("jdtls") then
      require("jdtls").start_or_attach(M.jdtls_config(buf), nil, { bufnr = buf })
    end
  end,
```

with:

```lua
  -- The debugger is registered first, so it keeps hot code replace; see
  -- ach.dap.java.
  ["nvim-jdtls"] = function(buf)
    if executable("jdtls") then
      require("ach.dap").java()
      require("jdtls").start_or_attach(M.jdtls_config(buf), nil, { bufnr = buf })
    end
  end,
```

Then replace these lines in the Scala starter:

```lua
      config.settings = { metalsBinaryPath = M.metals_program }
      config.capabilities = require("ach.lsp").capabilities()
```

with:

```lua
      config.settings = { metalsBinaryPath = M.metals_program }
      config.capabilities = require("ach.lsp").capabilities()
      config.on_attach = function()
        metals.setup_dap()
      end
```

Then, in `M.setup`, replace:

```lua
  vim.g.haskell_tools = { hls = { auto_attach = false } }
```

with:

```lua
  -- haskell-tools' search for launch choices runs when debugging starts,
  -- through ach.dap's provider, rather than as each file opens.
  vim.g.haskell_tools = { hls = { auto_attach = false }, dap = { auto_discover = false } }
```

`metals.setup_dap()` registers Scala's adapter, which asks the running Metals for a debug server each time a session starts, so it is registered once Metals has attached. It loads nvim-dap if nothing has yet.

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add these lines to `M.keys`, directly above `-- Keys added by later tasks go above this line.`. Every glyph they name is already in the database. Breakpoints and stopping are red, conditions and pauses yellow, starting and running green, stepping blue, moving between frames azure, looking at values cyan, the console and the interface purple, and a restart orange.

```lua
  ["Toggle Breakpoint"] = { "dap.Breakpoint", "red" },
  ["Conditional Breakpoint"] = { "dap.BreakpointCondition", "yellow" },
  ["Log Point"] = { "dap.LogPoint", "cyan" },
  ["Start or Continue"] = { "dap.continue", "green" },
  ["Start with Arguments"] = { "dap.continue", "green" },
  ["Run to Cursor"] = { "dap.run_to_cursor", "green" },
  ["Jump to Line Without Running"] = { "dap.Stopped", "yellow" },
  ["Step Into"] = { "dap.step_into", "blue" },
  ["Step Over"] = { "dap.step_over", "blue" },
  ["Step Out"] = { "dap.step_out", "blue" },
  ["Frame Up"] = { "dap.frame_up", "azure" },
  ["Frame Down"] = { "dap.frame_down", "azure" },
  ["Rerun Last Debug"] = { "dap.run_last", "green" },
  ["Restart Debugging"] = { "dap.restart", "orange" },
  ["Pause Debugging"] = { "dap.pause", "yellow" },
  ["Stop Debugging"] = { "dap.terminate", "red" },
  ["Debug Console"] = { "dap.repl", "purple" },
  ["Debug Sessions"] = { "dap.debug", "red" },
  ["Inspect Value"] = { "dap.widgets", "cyan" },
  ["Evaluate Expression"] = { "dap.eval", "cyan" },
  ["Debug Interface"] = { "dap.ui", "purple" },
  ["Debug Nearest Test"] = { "dap.debug", "red" },
  ["Debug Test Class"] = { "dap.debug", "red" },
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones nvim-dap, nvim-dap-ui, nvim-nio, nvim-dap-virtual-text and nvim-dap-python at the commits named, and mason-nvim-dap.nvim at its newest 2.x release, and adds all six to `lazy-lock.json`. No adapter is installed.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 19 `test_dap` tests pass, along with every earlier test: the managed-languages tests with the new stand-in, and the foundation's icon tests, where each new key description is its own which-key rule. Exit 0.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/dap.lua lua/ach/plugins/dap.lua tests/test_dap.lua
git commit --only lua/ach/dap.lua lua/ach/plugins/dap.lua lua/ach/managed.lua lua/ach/icons.lua tests/test_dap.lua tests/test_managed.lua lazy-lock.json -m "feat(dap): debug every language that has an adapter, through nvim-dap and its interface"
```

---

### Task: Health

**Files:**
- Create: `lua/ach/health.lua`
- Test: `tests/test_health.lua`

**Interfaces:**
- Consumes: `require("ach.install")` (`installed_parsers()`, `injected_parsers(langs)`, `package_installed(name)`, `has_package(name)`, `server_packages()`); `require("ach.lang")` (`entries()`, each entry carrying `name`, `ft`, `ts`, `runtime` and `system`, whose values are requirements; `packages_for_ft(ft, map)`; `command(req)`; and, in the tests, `get(name)`); `require("ach.masonlock").read()`; `require("ach.managed").metals_program`; `require("ach.dap")` (`lldb_filetypes`, `hdb_missing`); and mason-registry's `get_installed_packages()`, with each package's `name` and `get_installed_version()`.
- Produces:
  - `require("ach.health")`: `run(argv: string[]): boolean, string|nil`, which runs a program and returns whether it exited 0 and the first line it printed; `in_use(map: table<string, string>): table<string, true>, table<string, true>`, the languages in use and the languages that can be judged at all; `sections: { [1]: string, [2]: fun(s: table) }[]`, each section's title and the function that writes it; and `check()`, which `:checkhealth ach` calls.
  - The report the spec promises: `:checkhealth ach` names, language by language, what is installed, what is missing, and the command that installs each missing piece. The full-mode task reads it after its run.

`:checkhealth` is Neovim's own report. `:checkhealth ach` finds `lua/ach/health.lua` and calls its `check()`, which writes lines through `vim.health`: each is marked OK, WARNING, ERROR or plain information, and a warning or error can carry advice underneath. This task writes that report. It installs nothing and changes nothing; it only looks.

The report has eight sections, in this order.

| Section | What it looks at | How a gap is reported |
| --- | --- | --- |
| Neovim | the running version, which must be 0.12 or later | an error, with `brew upgrade neovim` |
| Build tools | Homebrew, the Command Line Tools, and the `tree-sitter` program | an error, with the command for each |
| Runtimes | each language runtime the table names, once, through the table's own check command | a warning when a language in use needs it, information otherwise |
| Programs Mason does not carry | each program the table installs from Homebrew or Xcode, such as `gleam` and `sourcekit-lsp` | the same |
| Languages | the parsers and Mason packages of each language in use | a warning naming what is missing and how to get it |
| Metals | the program Coursier installs for Scala | information, with the command that updates it |
| Debugging | `lldb-dap` through `xcrun`; `hdb` and the GHC it needs | a warning |
| Mason | every installed package against `mason-lock.json` | a warning, with the command that settles it |

Errors are kept for what stops every language: an old Neovim, no Homebrew, no Command Line Tools, or no `tree-sitter` program, without which no parser can be built. A missing runtime or program is a warning only when a language that needs it is in use, because that language is then not getting what it should. For a language never opened, the same gap is information, still with its command, since nothing installs until a file of that language opens, and a report full of warnings about languages never used would hide the one that matters. Harper, which checks the grammar of comments and prose in nearly every file, is a Mason package, so it is reported under Languages with the rest of each language's packages, and a missing `harper-ls` warns only for a language in use, like any other package.

Neovim keeps no record of which languages have been opened, so the check infers it from what is installed. A language counts as in use once a parser or a Mason package that only it lists is installed. Two kinds of item are left out of that judgement, because they say nothing about which language was opened. One is an item two languages list: in today's table, the `yaml` parser, which YAML, Docker Compose and Ansible share, and the `prettier` package, which ten languages share. The other is a parser that another installed parser brought in. A file can hold a second language inside it, which Tree-sitter calls an injection: a Lua file can carry Vim script in a `vim.cmd` string and C in an `ffi.cdef` string, so opening one installs the `vim`, `c` and `query` parsers along with Lua's own, and an installed `vim` parser then does not show that a Vim script was opened. The check asks the installer's `injected_parsers` which parsers each installed parser's injection query names, and leaves those out. Leaving a parser out can only make the check miss a language, never invent one, and a language whose parser is left out this way still counts through a Mason package only it lists, such as Lua's `stylua`. Lean and plain text list nothing of their own. The check cannot judge those, so it leaves them out of the list of languages not opened yet rather than name them there wrongly. Their runtime and program lines still appear.

The Command Line Tools are checked with `xcode-select -p` rather than by looking for `cc` or `git`. macOS ships `/usr/bin/cc` and `/usr/bin/git` whether or not the tools are installed, as stand-ins that only offer to install them, so finding them proves nothing.

Each runtime is checked with the command the installer uses, taken from the language table, and only once per report however many sections ask. Its version is the first line that command prints. `java -version` prints to standard error, so `run` reads standard error when standard output is empty. A missing runtime is reported with `command` of its requirement, the one line that installs it by hand, such as `brew install ghcup && ghcup install ghc --set recommended` for GHC. Opening a file of that language also offers to install it, once a session, but an owner who answered no, or who would rather type the command, finds it here.

Metals is not a Mason package, so this report is the one place its update command is written down. `hdb` comes from a release on GitHub and needs GHC 9.14 or later, so once `hdb` is on the path the check reads `ghc --numeric-version`. The advice for an older GHC is `ghcup install ghc --set latest`. That command was checked against ghcup's source, not run, since ghcup is not on this Mac: `latest` is one of the tags `ghcup install ghc` accepts, and for GHC, `--set` makes the new version the active one.

A section that fails, say because mason.nvim cannot be loaded, is reported as an error under its own heading, and the sections after it still run.

- [ ] **Write the failing tests**

`tests/test_health.lua`:

```lua
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
  return function(name)
    return found[name] and 1 or 0
  end
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
    return function(msg, advice)
      out[#out + 1] = { kind = kind, msg = msg, advice = advice }
    end
  end
  local registry = o.registry
    or {
      get_installed_packages = function()
        local list = {}
        for name, version in pairs(o.installed or {}) do
          list[#list + 1] = {
            name = name,
            get_installed_version = function(_)
              return version
            end,
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
      function()
        return set(o.parsers)
      end,
    },
    {
      install,
      "injected_parsers",
      function(langs)
        return (o.injected or {})[langs[1]] or {}
      end,
    },
    {
      install,
      "package_installed",
      function(name)
        return vim.list_contains(o.packages or {}, name)
      end,
    },
    {
      install,
      "has_package",
      function()
        return true
      end,
    },
    {
      install,
      "server_packages",
      function()
        return o.servers or {}
      end,
    },
    {
      require("ach.masonlock"),
      "read",
      function()
        return o.lock or {}
      end,
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
    t.eq({ H.run({ "sh", "-c", "printf 'openjdk 21\\n' >&2" }) }, { true, "openjdk 21" }, "standard error, where java -version prints")
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
    local r = section(
      report({ run = { cargo = "cargo 1.90.0 (840b83a10 2025-07-30)" }, parsers = { "haskell" } }),
      "Runtimes"
    )
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
    t.ok(find(r, "info", "fish is not installed").msg:find("brew install fish", 1, true) ~= nil, "fish, with no fish file opened")
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
        function()
          return set({ "yaml", "dockerfile", "rust" })
        end,
      },
      {
        install,
        "injected_parsers",
        function()
          return {}
        end,
      },
      {
        install,
        "package_installed",
        function(name)
          return name == "prettier"
        end,
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
        function()
          return set({ "lua", "luadoc", "luap", "c", "query", "vim" })
        end,
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
        function()
          return false
        end,
      },
    }, function()
      used = H.in_use({})
    end)
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
    t.ok(has(section(report({ parsers = { "haskell" } }), "Debugging"), "warn", D.hdb_missing), "no hdb, with Haskell in use")
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
    t.eq(fine, { { kind = "ok", msg = "2 packages installed, each at the version mason-lock.json pins" } }, "all pinned")
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
        function()
          error("boom")
        end,
      },
    }, function()
      out = report({})
    end)
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
    }, "every section, in order")
    local neovim = section(out, "Neovim")
    t.eq(#neovim, 1, "one report")
    t.eq(neovim[1].kind, "error", "reported as an error")
    t.ok(neovim[1].msg:find("boom", 1, true) ~= nil, "with what went wrong")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_health`
Expected: `0 passed, 16 failed, 0 need a person, 0 skipped`, exit 1. Every test fails on `module 'ach.health' not found`, since each one reaches `require("ach.health")`.

- [ ] **Write the health module**

`lua/ach/health.lua`:

```lua
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
  local ok, result = pcall(function()
    return vim.system(argv, { text = true, timeout = 10000 }):wait()
  end)
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

local function list(names)
  return table.concat(names, ", ")
end

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
  table.sort(names, function(a, b)
    return a:lower() < b:lower()
  end)
  for _, name in ipairs(names) do
    local n = needs[name]
    local r = probe(s, n.runtime)
    if r.ok then
      vim.health.ok(found(name, r.line))
    else
      missing(
        n.used,
        ("%s is not installed, so %s files get no language server and no Mason tools."):format(
          name,
          list(n.languages)
        ),
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
        local how = (
          "Restart Neovim and open a %s file, since an install that failed is not tried again in the same session."
        ):format(e.name)
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
    vim.health.info("Mason has installed nothing yet. A language's packages install the first time one of its files opens.")
    return
  end
  table.sort(packages, function(a, b)
    return a.name < b.name
  end)
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
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all 16 `test_health` tests pass, along with every earlier test. Exit 0.

- [ ] **Read the report once**

Run: `nvim -u init.lua "+checkhealth ach"`
Expected: eight headings under `ach:`, in the order of the table above. On a Mac with Homebrew, the Command Line Tools and `tree-sitter-cli`, nothing under Neovim or Build tools is an error. Every warning carries advice naming a command, and every information line about a missing tool names one in its text. Close the report with `:qa`.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/health.lua tests/test_health.lua
git commit --only lua/ach/health.lua tests/test_health.lua -m "feat(health): name every missing tool with the command that installs it"
```

---

### Task: Full mode

**Files:**
- Create: `tests/helpers/languages_doc.lua`, `tests/helpers/probe.lua`, `tests/test_full_languages.lua`, and `docs/languages.md`, which the run writes and nobody edits by hand
- Modify: `mason-lock.json`, which gains a line for every package the run installs; `lua/ach/languages.lua` and `tests/fixtures/samples.lua` only where the run shows a tool or a sample that does not work
- Test: `tests/test_languages_doc.lua`, which the regular suite runs, and `tests/test_full_languages.lua`, which only `scripts/check --full` runs

**Interfaces:**
- Consumes: `require("ach.lang")` (`entries()`, each entry carrying `name`, `ft`, `ts`, `lsp`, `mason`, `system`, `runtime` and `managed`; `get(name)`; `command(req)`; `system_for_ft(ft)`; `formatters_by_ft()`; `linters_by_ft()`; `is_harper_ft(ft)`); `require("ach.languages").grammar` (`server`, `program`); `require("ach.install")` (`ready(buf, ft, entry)` and `ask(question, cb)`, each looked up each time it is called; `ensure_parsers(names, done)`; `with_registry(cb)`; `server_packages()`; `has_package(name)`); `require("ach.runtimes").check(runtime, cb)`; `require("ach.lsp").program(name)`; `require("ach.lint")` (`linters_for(buf)`, `run(buf, all)`, `commands`); `require("ach.managed").clients`; `require("ach.health").check()`; conform's `format(opts)` and `get_formatter_info(name, buf)`; nvim-lint's `get_namespace(name)`; `tests/fixtures/samples.lua` (`write(dir, name)`); `tests/helpers/child.lua` (`run(t, body, opts)`, whose `env` option overrides its `ACH_DRY_INSTALL=1`).
- Produces:
  - `tests/helpers/languages_doc.lua`, loaded with `dofile`: `layers: { key: string, title: string }[]`; `cell(layer?, failed?: boolean): string`; `render(results, stamp: string): string`, which lists under the table each install a language is waiting on; `parse(text: string): table<language, table<layer key, string[]>>`, the tools a rendered document records as working; `compare(before, results): string[]`, one message for each thing that got worse; and `needs(results): string[]`, each missing install command with the languages waiting on it. A result is `{ name, layers }`, where `layers` maps each layer key to `{ want: string[], works: string[], needs: table<tool, string> }`, or `{ name, error }` when the language's check did not finish.
  - `tests/helpers/probe.lua`, loaded with `dofile` inside a child Neovim: it returns `fun(name: string, path: string): result`.
  - `docs/languages.md`: one row per language, naming the tool behind each layer or saying none exists.

The full mode is the only place the configuration meets real tools. The regular suite runs every language dry, so it proves the table is consistent with the plugins that read it, and nothing more. This task proves, on this Mac, that each language's parser highlights, its servers attach, its formatters change the line planted for them, its linters report the warning planted for them, and Harper flags the repeated "the". What it finds goes into `docs/languages.md`, so that the README's promise of a language is never larger than what was measured.

Each language runs in its own child Neovim, started by the helper from the tree-sitter task with `ACH_DRY_INSTALL=0`, so the installer is live there. The child opens the language's sample, which `write()` puts in a fresh folder that is also the child's working folder, so a server looking for a project root finds the sample's `go.mod` or `Cargo.toml` and nothing of this repository. Opening the file is the whole install: the FileType hook installs the parsers and the Mason packages exactly as it would on a first open, which is the path a person takes. A child per language also means each one starts from a clean editor, and a server that hangs dies with its child at the thirty-minute limit rather than stalling every language after it.

The probe has to know when the installer is finished, and the installer offers no callback for that. It does not need one. `ensure_tools` calls `M.ready(buf, ft, entry)` through the module table each time, so the probe wraps `install.ready` before it opens the file, and the wrapper marks the moment the buffer's packages have installed or failed. For the parsers, the probe calls `ensure_parsers` with the same names the hook asked for. Two calls for one parser share one install, so the probe's callback runs straight after the hook's, once highlighting has started.

The full run installs nothing from Homebrew. When a file opens whose runtime or program is missing, the installer asks whether to install it, and in a child Neovim that question would wait for an answer nobody can give. So before it opens the file, the probe replaces `install.ask`, which the installer also looks up each time, with one that answers no. A Homebrew runtime runs to gigabytes, and installing one is the owner's decision, made in the editor or a terminal, not a test's. Parsers and Mason packages still install, since they are what the run measures. A language whose runtime is missing therefore gets its parsers and nothing more, as it would for an owner who answered no, and the document records the rest as waiting.

| Layer | Works when |
| --- | --- |
| Tree-sitter | the parser of the sample's own file type is highlighting the buffer |
| Server | a client of that name is attached to the buffer, for each server whose configuration takes the sample's file type, and for the client a managed language's own plugin starts |
| Formatter | run alone through conform, on the sample as written, it changes the text |
| Linter | its nvim-lint namespace holds at least one diagnostic for the buffer |
| Grammar | Harper is attached and, in the two samples that plant "the the", has a diagnostic on that line |

The order inside the probe matters in one place. Linting and Harper run on the sample as written, before any formatter touches it, because ktlint's planted semicolon is both a lint warning and a format fix, and formatting first would remove the evidence. Each formatter then runs alone, with the buffer put back to the sample between runs, so a language with two formatters credits each one only for a change it made itself. A server that cannot start, because its program is missing, is not waited for; waiting would cost three minutes and prove nothing.

A tool that did not work is one of two kinds, and the document keeps them apart. **Waiting** means the reason is outside this configuration's reach: the language's runtime is missing, which stops everything but the parser, or the tool's program is one the table installs from Homebrew or Xcode and it is not on the path. The full run never installs those, so a tool waiting on one is not a failure, and the document lists each such install under its table, with the languages waiting on it. **Not working** means the tool was there and failed its check. Only the first kind needs a person, and `scripts/check` exits 2 for it, as the spec says it does for a missing runtime, with every install command and the languages waiting on it.

The test compares what it measured with the copy of `docs/languages.md` in the last commit, read with `git show HEAD:docs/languages.md`, not the copy on disk. The run rewrites the copy on disk, so comparing with it would let a second run quietly accept whatever the first one broke. What was committed is what was accepted. A tool that the committed copy records as working and that does not work now fails the run, unless it is now only waiting, or the table no longer names it. A language whose check did not finish always fails. A tool that has never worked does not fail the run, which is what the spec asks for. It does show in the table as `not working`, and the step after the first run settles every one of those by hand.

Three smaller checks share the file. The registry check confirms that every Mason package the table names exists in Mason's registry, and that every server either comes from a Mason package or has its program in its entry's `system` map, because `packages_for_ft` drops a server with no package without a word, so a misspelt server name would otherwise never install and never fail. The health check reads `:checkhealth ach` once everything is installed, as the health task promised, and fails on any error it reports. An error there means something that stops every language, such as no `tree-sitter` program. And the needs check is the exit-2 report described above.

The Formatter column names the formatters conform runs from the table. A language with none listed may still be formatted by its server, through conform's `lsp_format = "fallback"`, and the column says `none` for it because this test does not measure that. The column header paragraph in the document says so, so the table does not understate it silently either.

Neovim ships no Bluespec syntax file. Its `runtime/syntax` folder was checked on 2026-10-10 and holds `bsdl.vim` and `bst.vim`, neither of which is Bluespec. So if `tree-sitter-bsv` fails its check and is dropped, Bluespec opens with no colour at all, not with the classic syntax colouring the spec describes. The table's row for it will then say `none` in every column, which is the truth.

- [ ] **Write the failing tests**

`tests/test_languages_doc.lua`:

```lua
-- The full test's document: how each layer's cell reads, the table it renders,
-- reading the committed copy back, and what counts as getting worse. Pure
-- functions over made-up results, so nothing here installs anything.
local function load(t)
  return dofile(t.root .. "/tests/helpers/languages_doc.lua")
end

local function layer(want, works, needs)
  return { want = want, works = works or {}, needs = needs or {} }
end

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
    local rows = vim.tbl_filter(function(line)
      return line:sub(1, 2) == "| "
    end, lines)
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
      python = { treesitter = { "python" }, server = { "basedpyright", "ruff" }, formatter = {}, linter = {}, grammar = {} },
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
      go = { treesitter = { "go" }, server = { "gopls" }, formatter = { "goimports", "gofumpt" }, linter = {}, grammar = {} },
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
```

The second `go` result in the compare test is the table dropping a tool: `goimports` worked before, and the entry now lists only `gofumpt`, so its absence is a decision, not a breakage. `zig` is a language the committed copy has never seen, so nothing it lacks can have got worse.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_languages_doc`
Expected: `0 passed, 10 failed, 0 need a person, 0 skipped`, exit 1. Every test fails at its first line, where `dofile` cannot open `tests/helpers/languages_doc.lua`.

- [ ] **Write the document helper**

`tests/helpers/languages_doc.lua`:

```lua
-- Builds docs/languages.md from what the full test measured, reads a copy of
-- it back, and says what got worse between the two. Pure functions, so the
-- regular suite tests them without installing anything.
--
-- A result is { name, layers }, where layers maps each layer key to
-- { want, works, needs }: the tools the table names, those that worked, and,
-- for a tool that did not, the install command it is waiting on when the
-- reason is a missing runtime or Homebrew program. A language whose check did
-- not finish is { name, error } instead.
local M = {}

M.layers = {
  { key = "treesitter", title = "Tree-sitter" },
  { key = "server", title = "Server" },
  { key = "formatter", title = "Formatter" },
  { key = "linter", title = "Linter" },
  { key = "grammar", title = "Grammar" },
}

local INTRO = table.concat({
  "Written by `scripts/check --full`, which installs what each language needs, short of anything from Homebrew",
  "or Xcode, and tries each layer on that language's sample in `tests/fixtures/samples.lua`.",
  "A cell names the tools that worked.",
  "`none` means the configuration names no tool for that layer,",
  "`not working` names a tool that was installed and failed its check,",
  "`waiting` names one waiting on a runtime or a Homebrew or Xcode program that is missing on this Mac,",
  "and `check failed` means the language's check did not finish.",
  "Server covers the servers that take the sample's file type, and Grammar is Harper.",
  "A language with no formatter listed may still be formatted by its server, which this table does not measure.",
}, " ")

local WAITING = table.concat({
  "The full run never installs from Homebrew or Xcode, so each command below stays waiting until it is run by hand,",
  "or, for a Homebrew command, until a file of one of its languages is opened in Neovim and the offer to install",
  "it is accepted. A tool waiting on one of them is not a failure.",
}, " ")

-- Each install command the run found missing, with the languages waiting on
-- it, both sorted.
local function waiting(results)
  local by_how = {}
  for _, r in ipairs(results) do
    for _, layer in pairs(r.layers or {}) do
      for _, how in pairs(layer.needs) do
        by_how[how] = by_how[how] or {}
        if not vim.list_contains(by_how[how], r.name) then
          table.insert(by_how[how], r.name)
        end
      end
    end
  end
  local out = {}
  for how, names in pairs(by_how) do
    table.sort(names)
    out[#out + 1] = { how = how, names = names }
  end
  table.sort(out, function(a, b)
    return a.how < b.how
  end)
  return out
end

function M.cell(layer, failed)
  if failed then
    return "check failed"
  end
  if not layer or #layer.want == 0 then
    return "none"
  end
  local works, broken, blocked = {}, {}, {}
  for _, tool in ipairs(layer.want) do
    if vim.list_contains(layer.works, tool) then
      works[#works + 1] = tool
    elseif layer.needs[tool] then
      blocked[#blocked + 1] = tool
    else
      broken[#broken + 1] = tool
    end
  end
  local parts = {}
  if #works > 0 then
    parts[#parts + 1] = table.concat(works, ", ")
  end
  if #broken > 0 then
    parts[#parts + 1] = "not working: " .. table.concat(broken, ", ")
  end
  if #blocked > 0 then
    parts[#parts + 1] = "waiting: " .. table.concat(blocked, ", ")
  end
  return table.concat(parts, "; ")
end

function M.render(results, stamp)
  local header, rule = { "Language" }, { "---" }
  for _, l in ipairs(M.layers) do
    header[#header + 1] = l.title
    rule[#rule + 1] = "---"
  end
  local lines = {
    "# Languages",
    "",
    INTRO,
    "",
    stamp,
    "",
    "| " .. table.concat(header, " | ") .. " |",
    "| " .. table.concat(rule, " | ") .. " |",
  }
  local sorted = vim.list_extend({}, results)
  table.sort(sorted, function(a, b)
    return a.name < b.name
  end)
  for _, r in ipairs(sorted) do
    local row = { r.name }
    for _, l in ipairs(M.layers) do
      row[#row + 1] = M.cell(r.layers and r.layers[l.key], r.error ~= nil)
    end
    lines[#lines + 1] = "| " .. table.concat(row, " | ") .. " |"
  end
  local blocked = waiting(results)
  if #blocked > 0 then
    vim.list_extend(lines, { "", "## Waiting on an install", "", WAITING, "" })
    for _, w in ipairs(blocked) do
      lines[#lines + 1] = ("- `%s`, for %s"):format(w.how, table.concat(w.names, ", "))
    end
  end
  return table.concat(lines, "\n") .. "\n"
end

-- The tools each language had working, read from a document render wrote.
-- Lines that are not one of its rows are skipped, the list of installs under
-- the table among them, so "" gives {}.
function M.parse(text)
  local out = {}
  for line in vim.gsplit(text, "\n", { plain = true }) do
    -- A row splits into an empty piece either side of its cells.
    local cells = vim.split(line, "|", { plain = true })
    local name = cells[2] and vim.trim(cells[2]) or ""
    if line:sub(1, 2) == "| " and #cells == #M.layers + 3 and name ~= "Language" and name ~= "---" then
      local row = {}
      for i, l in ipairs(M.layers) do
        local works = {}
        for _, part in ipairs(vim.split(vim.trim(cells[i + 2]), "; ", { plain = true })) do
          local listed = part ~= "" and part ~= "none" and part ~= "check failed"
          if listed and not part:find("^not working: ") and not part:find("^waiting: ") then
            vim.list_extend(works, vim.split(part, ", ", { plain = true }))
          end
        end
        row[l.key] = works
      end
      out[name] = row
    end
  end
  return out
end

-- What got worse since before, one message each. A tool counts only while the
-- table still names it, and one that is merely waiting on an install is left
-- to needs(). A check that did not finish always counts.
function M.compare(before, results)
  local out = {}
  for _, r in ipairs(results) do
    if r.error then
      out[#out + 1] = ("%s: the check did not finish: %s"):format(r.name, r.error)
    else
      local was = before[r.name] or {}
      for _, l in ipairs(M.layers) do
        local layer = r.layers[l.key]
        for _, tool in ipairs(was[l.key] or {}) do
          local wanted, works = vim.list_contains(layer.want, tool), vim.list_contains(layer.works, tool)
          if wanted and not works and not layer.needs[tool] then
            out[#out + 1] = ("%s: %s worked before and does not now (%s)"):format(r.name, tool, l.title)
          end
        end
      end
    end
  end
  table.sort(out)
  return out
end

-- Each install command the run found missing, with the languages waiting on
-- it, sorted, for the line scripts/check prints when a person is needed.
function M.needs(results)
  local out = {}
  for _, w in ipairs(waiting(results)) do
    out[#out + 1] = ("%s (for %s)"):format(w.how, table.concat(w.names, ", "))
  end
  return out
end

return M
```

`parse` reads only what `render` writes, so it can be strict about the shape: a line is a row when it starts with `| ` and splits into exactly as many pieces as the layers plus three, the language and the empty piece at either end. The header and the rule under it have that shape too, which is why it skips the two by their first cell.

- [ ] **Run them and see them pass**

Run: `scripts/check --only test_languages_doc`
Expected: `10 passed, 0 failed, 0 need a person, 0 skipped`, exit 0.

- [ ] **Write the probe**

`tests/helpers/probe.lua`:

```lua
-- Runs inside a child Neovim that the full test starts with the installer
-- live. It opens one language's sample, lets the installer do what it does on
-- a first open, then tries each layer and returns the language's result: for
-- each layer, the tools the table names for the sample's file type, those
-- that worked, and, for each that did not, the install command it is waiting
-- on when the reason is a missing runtime or Homebrew program.
local INSTALL_MS = 900000 -- a first install of the largest servers, such as jdtls
local ATTACH_MS = 180000
local REPORT_MS = 60000

return function(name, path)
  local lang = require("ach.lang")
  local install = require("ach.install")
  local grammar = require("ach.languages").grammar
  local entry = assert(lang.get(name), "no language named " .. name)

  -- ensure_tools calls install.ready through the module table, so this
  -- wrapper marks the moment the buffer's packages have installed or failed.
  local ready = false
  local inner = install.ready
  install.ready = function(...)
    inner(...)
    ready = true
  end

  -- The full run installs nothing from Homebrew, so every offer to install is
  -- answered no here, where nobody could answer it.
  install.ask = function(_, cb)
    cb(false)
  end

  -- With the runtime missing, ready is never called and only parsers install.
  local runtime_ok = true
  if entry.runtime then
    local answer
    require("ach.runtimes").check(entry.runtime, function(ok)
      answer = ok
    end)
    vim.wait(REPORT_MS, function()
      return answer ~= nil
    end, 50)
    runtime_ok = answer == true
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local system = lang.system_for_ft(ft)

  local function waiting_on(programs, uses_runtime)
    if uses_runtime and not runtime_ok then
      return lang.command(entry.runtime)
    end
    for _, program in ipairs(programs or {}) do
      if system[program] and vim.fn.executable(program) ~= 1 then
        return system[program]
      end
    end
  end

  local function layer(want, works, programs, uses_runtime)
    local out = { want = want, works = {}, needs = {} }
    for _, tool in ipairs(want) do
      if works[tool] then
        out.works[#out.works + 1] = tool
      else
        out.needs[tool] = waiting_on(programs[tool], uses_runtime)
      end
    end
    return out
  end

  -- Tree-sitter. The hook asked for these same parsers, so this call shares
  -- its install and its callback runs after the hook has started highlighting.
  local own = vim.treesitter.language.get_lang(ft) or ft
  local parsed = false
  install.ensure_parsers(vim.list_extend(vim.deepcopy(entry.ts or {}), { own }), function()
    parsed = true
  end)
  vim.wait(INSTALL_MS, function()
    return parsed
  end, 200)
  local ts_want = #(entry.ts or {}) > 0 and { own } or {}
  local treesitter = layer(ts_want, { [own] = vim.treesitter.highlighter.active[buf] ~= nil }, {}, false)

  vim.wait(INSTALL_MS, function()
    return ready or not runtime_ok
  end, 200)

  -- Servers: each one whose configuration takes this file type, and the
  -- client a managed language's own plugin starts. Harper is the grammar layer.
  local lsp = require("ach.lsp")
  local server_want, server_programs = {}, {}
  for _, server in ipairs(entry.lsp or {}) do
    local fts = (vim.lsp.config[server] or {}).filetypes
    if not fts or vim.list_contains(fts, ft) then
      server_want[#server_want + 1] = server
      server_programs[server] = { lsp.program(server) }
    end
  end
  local managed_client = entry.managed and require("ach.managed").clients[entry.managed]
  if managed_client then
    server_want[#server_want + 1] = managed_client
  end
  local grammar_want = lang.is_harper_ft(ft) and { grammar.server } or {}

  local function attached()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      names[client.name] = true
    end
    return names
  end
  -- A server whose program is missing is never enabled, so waiting for it
  -- would cost the whole wait and prove nothing.
  local function can_start(server)
    if server == managed_client then
      return true
    end
    local program = server == grammar.server and grammar.program or lsp.program(server)
    return program ~= nil and vim.fn.executable(program) == 1
  end
  local expected = {}
  if runtime_ok then
    for _, server in ipairs(vim.list_extend(vim.deepcopy(server_want), grammar_want)) do
      if can_start(server) then
        expected[#expected + 1] = server
      end
    end
  end
  vim.wait(ATTACH_MS, function()
    local now = attached()
    for _, server in ipairs(expected) do
      if not now[server] then
        return false
      end
    end
    return true
  end, 200)
  local server = layer(server_want, attached(), server_programs, true)

  -- Linters, on the sample as written, before any formatter changes it.
  local lint = require("ach.lint")
  local nvim_lint = require("lint")
  local lint_want = lang.linters_by_ft()[ft] or {}
  local runnable = {}
  for _, linter in ipairs(lint.linters_for(buf)) do
    runnable[linter] = true
  end
  local function reported(linter)
    return runnable[linter] == true and #vim.diagnostic.get(buf, { namespace = nvim_lint.get_namespace(linter) }) > 0
  end
  lint.run(buf, true)
  vim.wait(REPORT_MS, function()
    for _, linter in ipairs(lint_want) do
      if runnable[linter] and not reported(linter) then
        return false
      end
    end
    return true
  end, 200)
  local lint_works = {}
  for _, linter in ipairs(lint_want) do
    lint_works[linter] = reported(linter)
  end
  local linter = layer(lint_want, lint_works, lint.commands, true)

  -- Harper, attached and, where the sample plants "the the", flagging that
  -- line. Push and pull diagnostics live in different namespaces, so both
  -- are read.
  local function flags_planted_line()
    local row
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      if line:find("the the", 1, true) then
        row = i - 1
      end
    end
    if not row then
      return true
    end
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = grammar.server })) do
      for _, pull in ipairs({ false, true }) do
        local ns = vim.lsp.diagnostic.get_namespace(client.id, pull)
        if #vim.diagnostic.get(buf, { namespace = ns, lnum = row }) > 0 then
          return true
        end
      end
    end
    return false
  end
  local harper_works = {}
  if #grammar_want > 0 and attached()[grammar.server] then
    harper_works[grammar.server] = vim.wait(REPORT_MS, flags_planted_line, 200)
  end
  -- harper-ls is a Mason package, so only a missing runtime leaves it waiting.
  local grammar_layer = layer(grammar_want, harper_works, {}, true)

  -- Formatters, each alone on the sample as written, which it must change.
  local conform = require("conform")
  local fmt_want = lang.formatters_by_ft()[ft] or {}
  local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local fmt_works, fmt_programs = {}, {}
  for _, formatter in ipairs(fmt_want) do
    local info = conform.get_formatter_info(formatter, buf)
    fmt_programs[formatter] = info.command and { vim.fs.basename(info.command) } or {}
    if info.available then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
      local opts = { bufnr = buf, formatters = { formatter }, lsp_format = "never", timeout_ms = REPORT_MS }
      local ok = pcall(conform.format, opts)
      fmt_works[formatter] = ok and not vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), original)
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
  local formatter = layer(fmt_want, fmt_works, fmt_programs, true)

  return {
    name = name,
    layers = {
      treesitter = treesitter,
      server = server,
      formatter = formatter,
      linter = linter,
      grammar = grammar_layer,
    },
  }
end
```

`lsp_format = "never"` keeps a server from formatting in place of a missing formatter. Without it, conform's fallback would let `lua_ls` change the Lua sample and credit `stylua` with the change.

- [ ] **Write the full-mode test**

`tests/test_full_languages.lua`:

```lua
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

local function doc(t)
  return dofile(t.root .. "/tests/helpers/languages_doc.lua")
end

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
    local opts = { env = { ACH_DRY_INSTALL = "0" }, cwd = dir, timeout = CHILD_MS }
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
  require("ach.install").with_registry(function()
    loaded = true
  end)
  t.ok(vim.wait(300000, function()
    return loaded
  end, 100), "Mason's registry never loaded")
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
        function(msg)
          errors[#errors + 1] = msg
        end,
      },
    }, function()
      require("ach.health").check()
    end)
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
```

The runner sorts a file's tests by name, so the health test runs first and is the one that triggers the measuring. Each test calls `measure`, and the first call does the work, so the order does not matter for correctness, only for which test's time the run is counted under.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the ten `test_languages_doc` tests among them, exit 0. `tests/test_full_languages.lua` is not run, because the runner skips every `test_full*` file outside full mode, so its four tests appear nowhere in the count.

- [ ] **Run the full mode**

Run: `scripts/check --full`
Expected: a `checked <language>, <n> of <total>` line after each language, one per entry in the table, then the summary. The first run downloads every language's parsers and tools, which takes far longer than any later run, since later runs find them installed. The run writes `docs/languages.md` and adds a line to `mason-lock.json` for every package it installs. No Homebrew question appears, because the probe answers no to each. Exit 0, or exit 2 with one `HUMAN` line that lists each missing install command and the languages waiting on it; `docs/languages.md` lists the same commands under its table, and a tool waiting on one is not a failure. Before `docs/languages.md` has been committed, no tool can have stopped working, so an exit of 1 can only come from the registry test, the health test, or a language whose check did not finish, and the `FAIL` line names which. Fix that cause and run it again before going on.

- [ ] **Commit the record**

```bash
git add tests/helpers/languages_doc.lua tests/helpers/probe.lua tests/test_languages_doc.lua tests/test_full_languages.lua docs/languages.md
git commit --only tests/helpers/languages_doc.lua tests/helpers/probe.lua tests/test_languages_doc.lua tests/test_full_languages.lua docs/languages.md mason-lock.json -m "test(full): install every language, check each layer on its sample and record it in docs/languages.md"
```

This commit is the record as measured, `not working` cells included. From here on, the full mode compares against it.

- [ ] **Settle Bluespec's grammar**

Read the `bsv` row of `docs/languages.md`. If its Tree-sitter cell says `bsv`, the grammar passed and stays; go to the next step.

If it says `not working: bsv`, the grammar is dropped, as the spec requires. In `lua/ach/languages.lua`, delete the whole `bsv = { url = …, revision = …, queries = … },` block from `M.parsers`, and change the `bsv` entry to:

```lua
  bsv = { ft = { "bsv" } },
```

Bluespec files still get their file type, from `lua/ach/filetypes.lua`, and nothing else, since Neovim ships no Bluespec syntax file.

- [ ] **Settle every other cell that says not working**

For each `not working` tool left in `docs/languages.md`, find which side is at fault. When the sample is at fault, because it plants nothing that tool reports or changes, add a line to that language's sample in `tests/fixtures/samples.lua` that the tool does change or report, and name it in the comment above the sample, the way the other samples do. When the tool itself fails on this Mac, remove it from its entry in `lua/ach/languages.lua`, its Mason package with it, so the configuration stops installing something that does not work. Then run `scripts/check`, and where a test in `tests/test_lang.lua` or another test file names a tool you removed, change that test in the same way.

Then run `scripts/check --full` again. Expected: exit 0 or 2, as before, and no `not working` cell left in `docs/languages.md` that you have not settled.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit what was settled**

Skip this step when the two settling steps changed nothing. Otherwise commit the files they changed, with `docs/languages.md` and `mason-lock.json` as the second run left them, and a body naming each tool dropped or sample fixed and why:

```bash
git commit --only lua/ach/languages.lua tests/fixtures/samples.lua docs/languages.md mason-lock.json -m "fix(lang): drop the tools the full run shows not working, and fix the samples that tested nothing" -m "<one line per tool dropped or sample fixed, with the reason>"
```

Add to the `--only` list any test file the settling step changed. When the only change is Bluespec's grammar, the subject is `fix(lang): drop tree-sitter-bsv, which fails its check` and the files are `lua/ach/languages.lua` and `docs/languages.md`.
