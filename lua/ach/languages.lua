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
  lua = {
    ft = { "lua" },
    ts = { "lua", "luadoc", "luap" },
    lsp = { "lua_ls" },
    fmt = { "stylua" },
    mason = { "stylua" },
    harper = true,
  },
  vim = { ft = { "vim" }, ts = { "vim", "vimdoc" }, lsp = { "vimls" } },
  sh = {
    ft = { "sh", "bash", "zsh" },
    ts = { "bash", "zsh" },
    lsp = { "bashls" },
    fmt = { sh = { "shfmt" }, bash = { "shfmt" } },
    mason = { "shfmt", "shellcheck" },
    harper = { "sh" },
  },
  fish = {
    ft = { "fish" },
    ts = { "fish" },
    lsp = { "fish_lsp" },
    fmt = { "fish_indent" },
    -- fish_indent ships with the shell, and fish-lsp runs it.
    runtime = { name = "fish", check = { "fish", "--version" }, brew = { "fish" }, size = "about 20 MB" },
  },
  nushell = {
    ft = { "nu" },
    ts = { "nu" },
    lsp = { "nushell" },
    system = { nu = { name = "nushell", brew = { "nushell" }, size = "about 60 MB" } },
  },
  powershell = {
    ft = { "ps1" },
    ts = { "powershell" },
    lsp = { "powershell_es" },
    runtime = { name = "PowerShell", check = { "pwsh", "-Version" }, brew = { "powershell" }, size = "about 900 MB" },
  },
  perl = { ft = { "perl" }, ts = { "perl" }, lsp = { "perlnavigator" } },
  awk = { ft = { "awk" }, ts = { "awk" }, lsp = { "awk_ls" } },
  jq = { ft = { "jq" }, ts = { "jq" } },

  -- Systems ----------------------------------------------------------------
  c = {
    ft = { "c", "cpp", "objc", "objcpp", "cuda" },
    ts = { "c", "cpp", "cuda", "objc" },
    lsp = { "clangd" },
    fmt = { "clang_format" },
    mason = { "clang-format" },
    harper = { "c", "cpp" },
  },
  rust = {
    ft = { "rust" },
    ts = { "rust", "ron" },
    managed = "rustaceanvim",
    mason = { "rust-analyzer", "codelldb" },
    harper = true,
    runtime = {
      name = "Rust",
      check = { "cargo", "--version" },
      brew = { "rustup" },
      after = { { "rustup", "default", "stable" } },
      size = "about 1.5 GB",
    },
  },
  go = {
    ft = { "go", "gomod", "gowork", "gotmpl" },
    ts = { "go", "gomod", "gowork", "gosum", "gotmpl" },
    lsp = { "gopls" },
    fmt = { go = { "goimports", "gofumpt" } },
    lint = { go = { "golangcilint" } },
    mason = { "goimports", "gofumpt", "gomodifytags", "impl", "golangci-lint", "delve" },
    harper = { "go" },
    runtime = { name = "Go", check = { "go", "version" }, brew = { "go" }, size = "about 250 MB" },
  },
  zig = {
    ft = { "zig" },
    ts = { "zig" },
    lsp = { "zls" },
    harper = true,
    runtime = { name = "Zig", check = { "zig", "version" }, brew = { "zig" }, size = "about 2 GB" },
  },
  swift = {
    ft = { "swift" },
    ts = { "swift" },
    lsp = { "sourcekit" },
    harper = true,
    system = { ["sourcekit-lsp"] = xcode },
  },
  fortran = { ft = { "fortran" }, ts = { "fortran" }, lsp = { "fortls" } },
  asm = { ft = { "asm", "nasm" }, ts = { "asm", "nasm" }, lsp = { "asm_lsp" } },
  llvm = { ft = { "llvm" }, ts = { "llvm" } },
  mlir = { ft = { "mlir" }, ts = { "mlir" }, lsp = { "mlir_lsp_server" }, system = { ["mlir-lsp-server"] = llvm } },
  tablegen = {
    ft = { "tablegen" },
    ts = { "tablegen" },
    lsp = { "tblgen_lsp_server" },
    system = { ["tblgen-lsp-server"] = llvm },
  },
  linker = { ft = { "ld" }, ts = { "linkerscript" } },
  devicetree = { ft = { "dts" }, ts = { "devicetree" } },
  kconfig = { ft = { "kconfig" }, ts = { "kconfig" } },

  -- Hardware description --------------------------------------------------
  systemverilog = {
    ft = { "verilog", "systemverilog" },
    ts = { "systemverilog" },
    lsp = { "verible" },
    fmt = { "verible" },
    mason = { "verible" },
  },
  vhdl = { ft = { "vhdl" }, ts = { "vhdl" }, lsp = { "vhdl_ls" } },
  veryl = { ft = { "veryl" }, ts = { "veryl" }, lsp = { "veryl_ls" } },
  bsv = { ft = { "bsv" }, ts = { "bsv" } },
  firrtl = { ft = { "firrtl" }, ts = { "firrtl" } },
  tcl = { ft = { "tcl", "sdc", "xdc" }, ts = { "tcl" }, lsp = { "tclsp" }, lint = { "tclint" } },

  -- Build systems ------------------------------------------------------------
  cmake = {
    ft = { "cmake" },
    ts = { "cmake" },
    lsp = { "neocmake" },
    -- cmake-format, from cmakelang, no longer runs on current Python.
    fmt = { "gersemi" },
    lint = { "cmakelint" },
    mason = { "gersemi", "cmakelint" },
    harper = true,
  },
  make = { ft = { "make", "automake" }, ts = { "make" }, lsp = { "autotools_ls" } },
  meson = { ft = { "meson" }, ts = { "meson" }, lsp = { "mesonlsp" } },
  ninja = { ft = { "ninja" }, ts = { "ninja" } },
  just = { ft = { "just" }, ts = { "just" }, lsp = { "just" } },
  starlark = {
    ft = { "bzl", "starlark" },
    ts = { "starlark" },
    lsp = { "starpls" },
    fmt = { "buildifier" },
    mason = { "buildifier" },
  },

  -- Python, JVM, .NET ---------------------------------------------------------
  python = {
    ft = { "python" },
    ts = { "python", "rst", "requirements" },
    lsp = { "basedpyright", "ruff" },
    fmt = { "ruff_format" },
    mason = { "debugpy" },
    harper = true,
  },
  java = {
    ft = { "java" },
    ts = { "java" },
    managed = "nvim-jdtls",
    mason = { "jdtls", "java-debug-adapter", "java-test" },
    harper = true,
    runtime = java,
  },
  kotlin = {
    ft = { "kotlin" },
    ts = { "kotlin" },
    lsp = { "kotlin_language_server" },
    fmt = { "ktlint" },
    lint = { "ktlint" },
    mason = { "ktlint", "kotlin-debug-adapter" },
    harper = true,
    runtime = java,
  },
  scala = {
    ft = { "scala", "sbt" },
    ts = { "scala" },
    managed = "nvim-metals",
    harper = { "scala" },
    runtime = {
      name = "Coursier",
      check = { "coursier", "list" },
      brew = { "coursier", "openjdk@21" },
      size = "about 700 MB",
    },
  },
  groovy = { ft = { "groovy" }, ts = { "groovy" }, lsp = { "groovyls" }, harper = true, runtime = java },
  clojure = { ft = { "clojure", "edn" }, ts = { "clojure" }, lsp = { "clojure_lsp" }, harper = { "clojure" } },
  dotnet = {
    ft = { "cs", "fsharp" },
    ts = { "c_sharp", "fsharp" },
    lsp = { "csharp_ls", "fsautocomplete" },
    fmt = { cs = { "csharpier" }, fsharp = { "fantomas" } },
    mason = { "csharpier", "fantomas", "netcoredbg" },
    harper = { "cs" },
    runtime = { name = ".NET SDK", check = { "dotnet", "--version" }, brew = { "dotnet" }, size = "about 800 MB" },
  },

  -- Functional ------------------------------------------------------------------
  haskell = {
    ft = { "haskell", "lhaskell", "cabal" },
    ts = { "haskell" },
    managed = "haskell-tools.nvim",
    fmt = { haskell = { "fourmolu" }, cabal = { "cabal_fmt" } },
    lint = { haskell = { "hlint" } },
    mason = { "haskell-language-server", "fourmolu", "hlint" },
    harper = { "haskell", "lhaskell" },
    runtime = {
      name = "GHC",
      check = { "ghc", "--version" },
      brew = { "ghcup" },
      after = { { "ghcup", "install", "ghc", "--set", "recommended" } },
      size = "about 3 GB",
    },
  },
  ocaml = {
    ft = { "ocaml", "ocamlinterface" },
    ts = { "ocaml", "ocaml_interface" },
    lsp = { "ocamllsp" },
    fmt = { "ocamlformat" },
    mason = { "ocamlformat" },
    runtime = {
      name = "OCaml",
      check = { "ocaml", "-version" },
      brew = { "opam" },
      after = { { "opam", "init", "-n", "-y" } },
      size = "about 600 MB",
    },
  },
  elixir = {
    ft = { "elixir", "eelixir", "heex" },
    ts = { "elixir", "heex", "eex" },
    lsp = { "elixirls" },
    harper = { "elixir" },
    runtime = { name = "Elixir", check = { "elixir", "--version" }, brew = { "elixir" }, size = "about 400 MB" },
  },
  erlang = {
    ft = { "erlang" },
    ts = { "erlang" },
    lsp = { "elp" },
    runtime = { name = "Erlang", check = { "erl", "-version" }, brew = { "erlang" }, size = "about 350 MB" },
  },
  gleam = {
    ft = { "gleam" },
    ts = { "gleam" },
    lsp = { "gleam" },
    fmt = { "gleam" },
    harper = true,
    system = { gleam = { name = "Gleam", brew = { "gleam" }, size = "about 400 MB" } },
  },
  elm = { ft = { "elm" }, ts = { "elm" }, lsp = { "elmls" }, fmt = { "elm_format" }, mason = { "elm-format" } },
  lean = {
    ft = { "lean" },
    managed = "lean.nvim",
    runtime = {
      name = "elan",
      check = { "elan", "--version" },
      brew = { "elan-init" },
      after = { { "elan", "default", "stable" } },
      size = "about 1.5 GB",
    },
  },
  julia = {
    ft = { "julia" },
    ts = { "julia" },
    lsp = { "julials" },
    runtime = { name = "Julia", check = { "julia", "--version" }, brew = { "julia" }, size = "about 1.5 GB" },
  },
  r = {
    ft = { "r", "rmd", "quarto", "rnoweb" },
    ts = { "r", "rnoweb", "markdown" },
    lsp = { "r_language_server" },
    harper = { "quarto" },
    runtime = { name = "R", check = { "R", "--version" }, brew = { "r" }, size = "about 1.5 GB" },
  },
  nix = {
    ft = { "nix" },
    ts = { "nix" },
    lsp = { "nil_ls" },
    fmt = { "nixfmt" },
    lint = { "statix" },
    mason = { "statix" },
    -- nil asks Nix for its builtins as it builds, and Homebrew does not carry Nix.
    runtime = {
      name = "Nix",
      check = { "nix", "--version" },
      command = "curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh",
    },
    -- Mason's nixfmt is built for Linux only.
    system = { nixfmt = { name = "nixfmt", brew = { "nixfmt" }, size = "about 30 MB" } },
    harper = true,
  },

  -- Web --------------------------------------------------------------------------
  typescript = {
    ft = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    ts = { "javascript", "jsdoc", "typescript", "tsx" },
    lsp = { "vtsls", "eslint", "tailwindcss" },
    fmt = { "prettier" },
    mason = { "prettier", "js-debug-adapter" },
    harper = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
  html = {
    ft = { "html" },
    ts = { "html" },
    lsp = { "html", "emmet_language_server", "tailwindcss" },
    fmt = { "prettier" },
    mason = { "prettier" },
    harper = true,
  },
  css = {
    ft = { "css", "scss", "less" },
    ts = { "css", "scss" },
    lsp = { "cssls", "tailwindcss" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  vue = {
    ft = { "vue" },
    ts = { "vue" },
    lsp = { "vue_ls", "vtsls", "tailwindcss" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  svelte = { ft = { "svelte" }, ts = { "svelte" }, lsp = { "svelte", "tailwindcss" } },
  astro = { ft = { "astro" }, ts = { "astro" }, lsp = { "astro", "tailwindcss" } },
  angular = {
    ft = { "htmlangular" },
    ts = { "angular" },
    lsp = { "angularls", "tailwindcss" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  ember = {
    ft = { "handlebars", "javascript.glimmer", "typescript.glimmer" },
    ts = { "glimmer", "glimmer_javascript", "glimmer_typescript" },
    lsp = { "ember" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  graphql = {
    ft = { "graphql" },
    ts = { "graphql" },
    lsp = { "graphql" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  php = {
    ft = { "php" },
    ts = { "php", "phpdoc" },
    lsp = { "intelephense" },
    fmt = { "php_cs_fixer" },
    lint = { "phpcs" },
    mason = { "php-cs-fixer", "phpcs", "php-debug-adapter" },
    harper = true,
    runtime = { name = "PHP", check = { "php", "--version" }, brew = { "php" }, size = "about 500 MB" },
  },
  twig = { ft = { "twig" }, ts = { "twig" }, lsp = { "twiggy_language_server" } },
  ruby = {
    ft = { "ruby", "eruby" },
    ts = { "ruby", "embedded_template" },
    lsp = { "ruby_lsp", "rubocop" },
    fmt = { ruby = { "rubocop" }, eruby = { "erb_format" } },
    mason = { "erb-formatter" },
    harper = { "ruby" },
    runtime = {
      name = "Ruby 3",
      check = { "ruby", "-e", "exit(RUBY_VERSION >= '3.0' ? 0 : 1)" },
      brew = { "ruby" },
      size = "about 100 MB",
    },
  },
  dart = {
    ft = { "dart" },
    ts = { "dart" },
    lsp = { "dartls" },
    fmt = { "dart_format" },
    harper = true,
    system = { dart = { name = "the Dart SDK", brew = { "dart-sdk" }, size = "about 600 MB" } },
  },
  prisma = { ft = { "prisma" }, ts = { "prisma" }, lsp = { "prismals" } },
  solidity = { ft = { "solidity" }, ts = { "solidity" }, lsp = { "solidity_ls" }, harper = true },

  -- Data, config and infrastructure -----------------------------------------------
  json = {
    ft = { "json", "jsonc", "json5" },
    ts = { "json", "json5" },
    lsp = { "jsonls" },
    fmt = { "prettier" },
    mason = { "prettier" },
  },
  yaml = { ft = { "yaml" }, ts = { "yaml" }, lsp = { "yamlls" }, fmt = { "prettier" }, mason = { "prettier" } },
  toml = { ft = { "toml" }, ts = { "toml" }, lsp = { "taplo" }, fmt = { "taplo" }, harper = true },
  xml = { ft = { "xml", "xsd", "xslt", "svg" }, ts = { "xml" }, lsp = { "lemminx" } },
  ini = { ft = { "dosini", "editorconfig" }, ts = { "ini", "editorconfig" } },
  csv = { ft = { "csv", "tsv" }, ts = { "csv", "tsv" } },
  sql = {
    ft = { "sql", "mysql", "plsql" },
    ts = { "sql" },
    fmt = { "sqlfluff" },
    lint = { "sqlfluff" },
    mason = { "sqlfluff" },
  },
  proto = { ft = { "proto" }, ts = { "proto" }, lsp = { "buf_ls" }, fmt = { "buf" } },
  thrift = { ft = { "thrift" }, ts = { "thrift" }, lsp = { "thriftls" } },
  docker = {
    ft = { "dockerfile", "yaml.docker-compose" },
    ts = { "dockerfile", "yaml" },
    lsp = { "dockerls", "docker_compose_language_service" },
    lint = { dockerfile = { "hadolint" } },
    mason = { "hadolint" },
  },
  terraform = {
    ft = { "terraform", "terraform-vars", "hcl" },
    ts = { "terraform", "hcl" },
    lsp = { "terraformls" },
    lint = { terraform = { "tflint" } },
    mason = { "tflint" },
  },
  helm = { ft = { "helm" }, ts = { "helm" }, lsp = { "helm_ls" } },
  ansible = { ft = { "yaml.ansible" }, ts = { "yaml" }, lsp = { "ansiblels" }, mason = { "ansible-lint" } },
  rego = { ft = { "rego" }, ts = { "rego" }, lsp = { "regols", "regal" } },
  dot = { ft = { "dot" }, ts = { "dot" }, lsp = { "dotls" } },
  git = {
    ft = { "gitcommit", "gitconfig", "gitrebase", "gitignore", "gitattributes" },
    ts = { "git_config", "gitcommit", "git_rebase", "gitignore", "gitattributes" },
    harper = { "gitcommit" },
  },

  -- Shaders ------------------------------------------------------------------------
  glsl = { ft = { "glsl" }, ts = { "glsl" }, lsp = { "glsl_analyzer" } },
  hlsl = { ft = { "hlsl" }, ts = { "hlsl" }, lsp = { "slangd" } },
  wgsl = { ft = { "wgsl" }, ts = { "wgsl" }, lsp = { "wgsl_analyzer" } },

  -- Prose ------------------------------------------------------------------------
  markdown = {
    ft = { "markdown", "markdown.mdx" },
    ts = { "markdown", "markdown_inline" },
    lsp = { "marksman" },
    fmt = { "prettier", "markdownlint-cli2" },
    lint = { "markdownlint-cli2" },
    mason = { "prettier", "markdownlint-cli2" },
    harper = { "markdown" },
    manual = true,
  },
  tex = {
    ft = { "tex", "plaintex", "bib" },
    ts = { "latex", "bibtex" },
    lsp = { "texlab" },
    harper = { "tex", "plaintex" },
    manual = true,
  },
  typst = {
    ft = { "typst" },
    ts = { "typst" },
    lsp = { "tinymist" },
    fmt = { "typstyle" },
    mason = { "typstyle" },
    harper = true,
    manual = true,
  },
  text = { ft = { "text" }, harper = true, manual = true },
}

return M
