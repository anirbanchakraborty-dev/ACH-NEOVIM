-- The language table and the engine that reads it. Every test requires its
-- modules inside its own body, so a missing module fails each test by name.

-- The language ids harper-ls reads, from harper-ls/src/backend.rs and
-- harper-comments/src/comment_parser.rs as of 2026-10-10. Neovim sends a
-- buffer's file type as its language id. "sh" and "cs" are not on Harper's
-- list, but its comment parser falls back on the file's extension, which
-- reaches the shell and C# grammars.
local HARPER_KNOWS = {
  "asciidoc",
  "c",
  "clojure",
  "cmake",
  "cpp",
  "cs",
  "csharp",
  "daml",
  "dart",
  "elixir",
  "gitcommit",
  "git-commit",
  "gleam",
  "go",
  "groovy",
  "haskell",
  "html",
  "ink",
  "java",
  "javascript",
  "javascriptreact",
  "kotlin",
  "latex",
  "lhaskell",
  "literate haskell",
  "lua",
  "mail",
  "markdown",
  "nix",
  "octo",
  "org",
  "php",
  "plaintex",
  "plaintext",
  "powershell",
  "python",
  "quarto",
  "ruby",
  "rust",
  "scala",
  "scminput",
  "sh",
  "shellscript",
  "solidity",
  "swift",
  "tex",
  "text",
  "toml",
  "typescript",
  "typescriptreact",
  "typst",
  "zig",
}

local FIELDS = {
  ft = true,
  ts = true,
  lsp = true,
  fmt = true,
  lint = true,
  mason = true,
  system = true,
  runtime = true,
  harper = true,
  manual = true,
  managed = true,
}

local MANAGED = {
  rustaceanvim = true,
  ["haskell-tools.nvim"] = true,
  ["nvim-jdtls"] = true,
  ["nvim-metals"] = true,
  ["lean.nvim"] = true,
}

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

  ["fish's tools wait on the fish shell, which fish_indent ships in and fish-lsp runs"] = function(t)
    local lang = require("ach.lang")
    local fish = lang.get("fish").runtime
    t.eq(fish and fish.check, { "fish", "--version" }, "the check for fish")
    t.eq(fish and lang.command(fish), "brew install fish", "fish's command")
  end,

  ["R's server waits on R's languageserver package, which installs after R"] = function(t)
    local lang = require("ach.lang")
    local r = lang.get("r").runtime
    t.eq(r.check, { "Rscript", "-e", "library(languageserver)" }, "the check for R")
    t.eq(lang.steps(r), {
      { "brew", "install", "r" },
      { "Rscript", "-e", "install.packages('languageserver', repos = 'https://cloud.r-project.org')" },
    }, "R's steps, Homebrew first")
    t.eq(
      lang.command(r),
      [[brew install r && Rscript -e "install.packages('languageserver', repos = 'https://cloud.r-project.org')"]],
      "R's command, with the R code quoted so a shell runs it as typed"
    )
  end,

  ["Nix's formatter comes from Homebrew, and its server waits on Nix"] = function(t)
    local lang = require("ach.lang")
    local nix = lang.get("nix")
    -- Mason's nixfmt is built for Linux only, and nil's build asks nix for its builtins.
    t.eq(lang.system_for_ft("nix").nixfmt, "brew install nixfmt", "nixfmt's command")
    t.ok(not vim.list_contains(nix.mason or {}, "nixfmt"), "Mason is not asked for nixfmt")
    t.eq(nix.runtime and nix.runtime.check, { "nix", "--version" }, "the check for Nix")
    t.eq(
      nix.runtime and lang.command(nix.runtime),
      "curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh",
      "Nix's own installer, which Homebrew does not carry"
    )
  end,

  ["CMake formats with gersemi, since cmake-format no longer runs on current Python"] = function(t)
    local cmake = require("ach.lang").get("cmake")
    t.eq(cmake.fmt, { "gersemi" }, "the formatter")
    t.ok(vim.list_contains(cmake.mason, "gersemi"), "Mason installs gersemi")
    t.ok(not vim.list_contains(cmake.mason, "cmakelang"), "Mason is not asked for cmakelang")
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
      "verilog",
      "systemverilog",
      "vhdl",
      "veryl",
      "bsv",
      "firrtl",
      "tcl",
      "sdc",
      "xdc",
      "dts",
      "ld",
      "llvm",
      "mlir",
      "tablegen",
      "asm",
      "nasm",
      "cuda",
      "scala",
      "python",
      "haskell",
      "sh",
      "perl",
      "swift",
      "html",
      "css",
      "make",
      "proto",
      "graphql",
      "glsl",
      "hlsl",
      "wgsl",
      "bzl",
      "just",
      "meson",
      "ninja",
      "kconfig",
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
      angular = "htmlangular",
      ansible = "yaml.ansible",
      astro = "astro",
      clangd = "c",
      clojure = "clojure",
      cmake = "cmake",
      dart = "dart",
      docker = "dockerfile",
      dotnet = "cs",
      elixir = "elixir",
      elm = "elm",
      ember = "handlebars",
      erlang = "erlang",
      git = "gitcommit",
      gleam = "gleam",
      go = "go",
      haskell = "haskell",
      helm = "helm",
      java = "java",
      json = "json",
      julia = "julia",
      kotlin = "kotlin",
      lean = "lean",
      markdown = "markdown",
      nix = "nix",
      nushell = "nu",
      ocaml = "ocaml",
      php = "php",
      prisma = "prisma",
      python = "python",
      r = "r",
      rego = "rego",
      ruby = "ruby",
      rust = "rust",
      scala = "scala",
      solidity = "solidity",
      sql = "sql",
      svelte = "svelte",
      terraform = "terraform",
      tex = "tex",
      thrift = "thrift",
      toml = "toml",
      twig = "twig",
      typescript = "typescript",
      typst = "typst",
      vue = "vue",
      yaml = "yaml",
      zig = "zig",
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
    t.eq(
      require("ach.lang").manual_filetypes(),
      { "bib", "markdown", "markdown.mdx", "plaintex", "tex", "text", "typst" }
    )
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
    t.eq(lang.system_for_ft("lilypond"), { lilypond = "brew install lilypond" }, "Swara needs LilyPond itself")
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
      "coursier",
      "dart-sdk",
      "dotnet",
      "elan-init",
      "elixir",
      "erlang",
      "fish",
      "ghcup",
      "gleam",
      "go",
      "julia",
      "lilypond",
      "llvm",
      "nixfmt",
      "nushell",
      "opam",
      "openjdk@21",
      "php",
      "powershell",
      "r",
      "ruby",
      "rustup",
      "zig",
    })
  end,

  ["scripts/on-demand prints the same formulae, one per line"] = function(t)
    local r = vim.system({ t.root .. "/scripts/on-demand" }, { cwd = t.root, text = true }):wait()
    t.eq(r.code, 0, "exit code, with stderr: " .. (r.stderr or ""))
    t.eq(vim.split(r.stdout, "\n", { trimempty = true }), require("ach.lang").formulae())
  end,
}
