-- LSP: native vim.lsp client + mason for package management.
--
-- Servers install purely on demand: opening a file of a new filetype triggers
-- an async install of its LSP server via mason, then enables the server and
-- attaches it to the current buffer. Nothing is ensured up front -- every
-- server arrives the moment it is first needed, mirroring the treesitter
-- auto_install flow.
--
-- Architecture (follows :h lsp):
--   * vim.lsp.config("<name>", {...}) registers per-server overrides which
--     merge over nvim-lspconfig's defaults (shipped as lsp/<name>.lua on the
--     runtimepath).
--   * vim.lsp.enable("<name>") is only called once the mason package is
--     present; this installs the FileType autocmd that actually starts the
--     client. On-demand installer fires FileType for already-loaded buffers
--     after enable so the currently-open file attaches immediately.
--   * LspAttach runs buffer-local keymaps + feature toggles (inlay hints).

local icons = require("config.icons")

-- Server table. Each entry carries:
--   mason      -- mason package name (omit + set system=true for system binaries)
--   system     -- true if provided outside mason (sourcekit-lsp, R)
--   filetypes  -- filetypes that trigger install/enable
--   config     -- (optional) vim.lsp.config overrides (settings, cmd, ...)
local servers = {
  -- Lua
  lua_ls = {
    mason = "lua-language-server",
    filetypes = { "lua" },
    config = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library = vim.api.nvim_get_runtime_file("", true),
          },
          telemetry = { enable = false },
          hint = { enable = true },
          diagnostics = { globals = { "vim", "Snacks" } },
        },
      },
    },
  },

  -- Python
  pyright = {
    mason = "pyright",
    filetypes = { "python" },
    config = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "openFilesOnly",
          },
        },
      },
    },
  },
  ruff = {
    mason = "ruff",
    filetypes = { "python" },
  },

  -- JS / TS
  --
  -- ts_ls (typescript-language-server) settings borrowed from LazyVim's
  -- extras/lang/typescript/vtsls.lua. The same `settings.typescript.*`
  -- keys work for both vtsls and ts_ls because both servers wrap the
  -- same upstream tsserver and forward these keys verbatim.
  --
  -- The four blocks below give:
  --   - inlayHints: parameter names (literals only -- the full set is
  --     too noisy on call sites that already pass named props), parameter
  --     types, return types, enum member values, and property declaration
  --     types. variableTypes is intentionally off because it duplicates
  --     what hover already shows on the LHS identifier.
  --   - updateImportsOnFileMove = "always": when a TS file is renamed via
  --     `<leader>cR` (Snacks.rename.rename_file) the LSP rewrites every
  --     import path that pointed to the old name. Without this the LSP
  --     prompts on every rename which is a papercut.
  --   - suggest.completeFunctionCalls: when accepting a function from
  --     completion, ts_ls inserts the full signature with parameter
  --     placeholders (mirrors blink.cmp's auto_brackets but with real
  --     parameter names from the type signature).
  --   - The same settings table is reused for `javascript` so JS files
  --     get the same hints + behavior; ts_ls reads both keys.
  --
  -- The two `<leader>cM` / `<leader>cD` keymaps are bound buffer-locally
  -- inside LspAttach (gated on `client.name == "ts_ls"`) since they fire
  -- TS-specific code action commands that no other LSP exposes.
  ts_ls = {
    mason = "typescript-language-server",
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    config = {
      settings = {
        typescript = {
          updateImportsOnFileMove = { enabled = "always" },
          suggest = {
            completeFunctionCalls = true,
          },
          inlayHints = {
            enumMemberValues = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            variableTypes = { enabled = false },
          },
        },
        javascript = {
          updateImportsOnFileMove = { enabled = "always" },
          suggest = {
            completeFunctionCalls = true,
          },
          inlayHints = {
            enumMemberValues = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            variableTypes = { enabled = false },
          },
        },
      },
    },
  },

  -- ESLint via vscode-eslint-language-server. Replaces the old eslint_d
  -- linter that used to live in linting.lua: the LSP gives real-time
  -- diagnostics + code actions instead of save-only feedback, and the
  -- `format = true` setting enables eslint's `source.fixAll.eslint`
  -- code action which conform's format_on_save calls before prettier
  -- runs (see formatting.lua's format_on_save callback for the wiring).
  --
  -- `workingDirectories = { mode = "auto" }` is a monorepo papercut
  -- fix borrowed from LazyVim's extras/linting/eslint.lua: it lets the
  -- eslint LSP find the nearest .eslintrc when it's in a subfolder
  -- instead of always looking at the project root.
  eslint = {
    mason = "eslint-lsp",
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
      "vue",
      "svelte",
      "astro",
    },
    config = {
      settings = {
        workingDirectories = { mode = "auto" },
        format = true,
      },
    },
  },

  -- Web
  html = {
    mason = "html-lsp",
    filetypes = { "html", "templ" },
  },
  cssls = {
    mason = "css-lsp",
    filetypes = { "css", "scss", "less" },
  },
  emmet_ls = {
    mason = "emmet-ls",
    filetypes = {
      "html",
      "css",
      "scss",
      "sass",
      "less",
      "javascriptreact",
      "typescriptreact",
      "vue",
      "svelte",
    },
  },

  -- Data formats
  --
  -- jsonls + yamlls both pull every schema in the SchemaStore catalog via
  -- b0o/SchemaStore.nvim. The before_init hook injects the schemas just
  -- before the server starts so SchemaStore stays lazy-loaded until the
  -- first json/yaml file is actually opened. This adds completion +
  -- validation for package.json, tsconfig.json, GitHub Actions workflows,
  -- GitLab CI, Kubernetes manifests, docker-compose, etc. for free.
  jsonls = {
    mason = "json-lsp",
    filetypes = { "json", "jsonc" },
    config = {
      before_init = function(_, new_config)
        new_config.settings = new_config.settings or {}
        new_config.settings.json = new_config.settings.json or {}
        new_config.settings.json.schemas = new_config.settings.json.schemas or {}
        local ok, schemastore = pcall(require, "schemastore")
        if ok then
          vim.list_extend(new_config.settings.json.schemas, schemastore.json.schemas())
        end
      end,
      settings = {
        json = {
          format = { enable = true },
          validate = { enable = true },
        },
      },
    },
  },
  yamlls = {
    mason = "yaml-language-server",
    filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
    config = {
      -- yamlls doesn't advertise line folding capability on its own;
      -- we have to inject it client-side or you get no folding at all.
      capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },
      before_init = function(_, new_config)
        new_config.settings = new_config.settings or {}
        new_config.settings.yaml = new_config.settings.yaml or {}
        local ok, schemastore = pcall(require, "schemastore")
        if ok then
          new_config.settings.yaml.schemas =
            vim.tbl_deep_extend("force", new_config.settings.yaml.schemas or {}, schemastore.yaml.schemas())
        end
      end,
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          keyOrdering = false,
          format = { enable = true },
          validate = true,
          schemaStore = {
            -- Disable yamlls's bundled schemaStore; SchemaStore.nvim is
            -- always more up-to-date.
            enable = false,
            url = "",
          },
        },
      },
    },
  },

  -- Markdown
  marksman = {
    mason = "marksman",
    filetypes = { "markdown", "markdown.mdx" },
  },

  -- Shell
  bashls = {
    mason = "bash-language-server",
    filetypes = { "sh", "bash", "zsh" },
  },

  -- C / C++
  --
  -- Borrowed from LazyVim's extras/lang/clangd.lua. Custom cmd flags
  -- enable background indexing, integrated clang-tidy, IWYU header
  -- insertion, detailed completion (with function arg placeholders),
  -- and the LLVM fallback style. offsetEncoding = utf-16 prevents
  -- a known mismatch with other servers attached to the same buffer.
  -- The clangd_extensions.nvim plugin (declared further below) layers
  -- inlay hints and an AST viewer on top.
  clangd = {
    mason = "clangd",
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    config = {
      capabilities = {
        offsetEncoding = { "utf-16" },
      },
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
      root_markers = {
        ".clangd",
        ".clang-tidy",
        ".clang-format",
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac",
        "Makefile",
        "meson.build",
        "meson_options.txt",
        "build.ninja",
        ".git",
      },
    },
  },

  -- Go
  --
  -- Borrowed from LazyVim's extras/lang/go.lua. The big additions over the
  -- vanilla gopls defaults are: gofumpt-on-save, the full code lens set
  -- (gc_details, generate, regenerate_cgo, run_govulncheck, test, tidy,
  -- upgrade_dependency, vendor), inlay hints for composite literal types
  -- and range variable types, the unused* analyses, useany, usePlaceholders
  -- for completion, completeUnimported, and staticcheck. directoryFilters
  -- speeds up workspace scans by skipping vendored deps and editor metadata.
  --
  -- The on_attach workaround patches a known gopls regression where the
  -- server forgets to advertise semanticTokensProvider on registration even
  -- though it actually supports semantic tokens; without this, treesitter +
  -- semantic-token highlighting in the same buffer get out of sync.
  -- See golang/go#54531.
  gopls = {
    mason = "gopls",
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    config = {
      settings = {
        gopls = {
          gofumpt = true,
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
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
          analyses = {
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
          semanticTokens = true,
        },
      },
      on_attach = function(client, _)
        -- gopls semanticTokensProvider workaround (golang/go#54531).
        if not client.server_capabilities.semanticTokensProvider then
          local semantic = client.config.capabilities.textDocument.semanticTokens
          if semantic then
            client.server_capabilities.semanticTokensProvider = {
              full = true,
              legend = {
                tokenTypes = semantic.tokenTypes,
                tokenModifiers = semantic.tokenModifiers,
              },
              range = true,
            }
          end
        end
      end,
    },
  },

  -- LaTeX / BibTeX
  texlab = {
    mason = "texlab",
    filetypes = { "tex", "plaintex", "bib" },
  },

  -- Ruby
  ruby_lsp = {
    mason = "ruby-lsp",
    filetypes = { "ruby", "eruby" },
  },

  -- Perl
  perlnavigator = {
    mason = "perlnavigator",
    filetypes = { "perl" },
  },

  -- Swift: system binary via xcrun. Not in mason. Enabled if xcrun is on
  -- PATH; otherwise we silently skip so non-Xcode users aren't spammed.
  sourcekit = {
    system = true,
    filetypes = { "swift" },
    config = {
      cmd = { "xcrun", "sourcekit-lsp" },
      root_markers = { "Package.swift", ".git" },
    },
  },

  -- R: installed inside R itself via install.packages("languageserver"),
  -- not in mason. Probe for the R binary before enabling.
  r_language_server = {
    system = true,
    filetypes = { "r", "rmd", "quarto" },
    config = {
      cmd = { "R", "--slave", "-e", "languageserver::run()" },
    },
  },

  -- ==================================================================
  --  Additional language servers (mason-installed unless system=true).
  --  Each one only fires its mason install on the first FileType event,
  --  so adding an entry here costs zero startup time -- the server
  --  arrives the moment the user opens a file in that language.
  -- ==================================================================

  -- ── Web ─────────────────────────────────────────────────────────────
  angularls = {
    mason = "angular-language-server",
    filetypes = { "typescript", "html", "htmlangular", "typescriptreact" },
  },
  astro = {
    mason = "astro-language-server",
    filetypes = { "astro" },
  },
  svelte = {
    mason = "svelte-language-server",
    filetypes = { "svelte" },
  },
  tailwindcss = {
    mason = "tailwindcss-language-server",
    filetypes = {
      "html",
      "css",
      "scss",
      "sass",
      "postcss",
      "less",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
      "astro",
      "angular",
      "htmlangular",
    },
  },
  -- Volar / vue-language-server. Standalone setup -- the modern
  -- ts_ls + @vue/typescript-plugin combo needs project-local plugin
  -- wiring that's out of scope for a global config.
  vue_ls = {
    mason = "vue-language-server",
    filetypes = { "vue" },
  },
  ember = {
    mason = "ember-language-server",
    filetypes = { "handlebars", "html.handlebars", "javascript", "typescript" },
  },
  prismals = {
    mason = "prisma-language-server",
    filetypes = { "prisma" },
  },
  twiggy_language_server = {
    mason = "twiggy-language-server",
    filetypes = { "twig" },
  },

  -- ── Systems ─────────────────────────────────────────────────────────
  rust_analyzer = {
    mason = "rust-analyzer",
    filetypes = { "rust" },
    config = {
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
          checkOnSave = { command = "clippy", extraArgs = { "--no-deps" } },
          procMacro = { enable = true },
        },
      },
    },
  },
  zls = {
    mason = "zls",
    filetypes = { "zig", "zir" },
  },
  -- nil_ls is the lighter-weight Nix LSP. mason package name is "nil".
  nil_ls = {
    mason = "nil",
    filetypes = { "nix" },
  },
  hls = {
    mason = "haskell-language-server",
    filetypes = { "haskell", "lhaskell" },
  },
  ocamllsp = {
    mason = "ocaml-lsp",
    filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex", "reason", "dune" },
  },
  clojure_lsp = {
    mason = "clojure-lsp",
    filetypes = { "clojure", "edn" },
  },
  erlangls = {
    mason = "erlang-ls",
    filetypes = { "erlang" },
  },
  elixirls = {
    mason = "elixir-ls",
    filetypes = { "elixir", "eelixir", "heex", "surface" },
  },
  -- Gleam ships its LSP inside the `gleam` binary -- not in mason.
  gleam = {
    system = true,
    filetypes = { "gleam" },
    config = {
      cmd = { "gleam", "lsp" },
      root_markers = { "gleam.toml", ".git" },
    },
  },
  -- Dart's LSP comes with the Dart SDK; not in mason.
  dartls = {
    system = true,
    filetypes = { "dart" },
    config = {
      cmd = { "dart", "language-server", "--protocol=lsp" },
      root_markers = { "pubspec.yaml", ".git" },
    },
  },
  omnisharp = {
    mason = "omnisharp",
    filetypes = { "cs", "vb" },
  },
  kotlin_language_server = {
    mason = "kotlin-language-server",
    filetypes = { "kotlin" },
  },
  metals = {
    mason = "metals",
    filetypes = { "scala", "sbt" },
  },
  -- jdtls is functional via lspconfig defaults but advanced features
  -- (test runner, debug, refactor) really want nvim-jdtls + per-project
  -- workspace setup. Out of scope here -- the basic install gets you
  -- diagnostics, completion, hover, and goto.
  jdtls = {
    mason = "jdtls",
    filetypes = { "java" },
  },
  intelephense = {
    mason = "intelephense",
    filetypes = { "php" },
  },

  -- ── Infra / Data ────────────────────────────────────────────────────
  ansiblels = {
    mason = "ansible-language-server",
    filetypes = { "yaml.ansible" },
  },
  cmake = {
    mason = "cmake-language-server",
    filetypes = { "cmake" },
  },
  helm_ls = {
    mason = "helm-ls",
    filetypes = { "helm" },
  },
  terraformls = {
    mason = "terraform-ls",
    filetypes = { "terraform", "terraform-vars" },
  },
  taplo = {
    mason = "taplo",
    filetypes = { "toml" },
  },
  sqlls = {
    mason = "sqls",
    filetypes = { "sql", "mysql" },
  },
  solidity_ls_nomicfoundation = {
    mason = "nomicfoundation-solidity-language-server",
    filetypes = { "solidity" },
  },
  regal = {
    mason = "regal",
    filetypes = { "rego" },
  },
  -- thrift: no production-grade LSP. Treesitter parser handles syntax;
  -- everything else is left to the user.

  -- ── Niche ───────────────────────────────────────────────────────────
  -- Lean's LSP is bundled with the lean toolchain (elan). Not in mason.
  leanls = {
    system = true,
    filetypes = { "lean" },
    config = {
      cmd = { "lean", "--server" },
      root_markers = { "lakefile.lean", "lean-toolchain", ".git" },
    },
  },
  -- Julia: LSP runs inside julia itself. The cmd is the standard
  -- LanguageServer.jl boot incantation. First-run is slow (compiles
  -- the language server image).
  julials = {
    system = true,
    filetypes = { "julia" },
    config = {
      cmd = {
        "julia",
        "--startup-file=no",
        "--history-file=no",
        "-e",
        [[
          using Pkg
          Pkg.instantiate()
          using LanguageServer
          runserver()
        ]],
      },
      root_markers = { "Project.toml", ".git" },
    },
  },
  -- nushell: no LSP shipped with nu. Filetype detected via vim.filetype.add.
  elmls = {
    mason = "elm-language-server",
    filetypes = { "elm" },
  },
  tinymist = {
    mason = "tinymist",
    filetypes = { "typst" },
  },

  -- ── Hardware / HDL ──────────────────────────────────────────────────
  --
  -- Two LSPs attach to every SystemVerilog / Verilog buffer:
  --
  --   * verible        -- diagnostics (verible-verilog-lint with project
  --                       `.rules.verible_lint` auto-pickup), document
  --                       symbols (outline), and semantic tokens.
  --   * svlangserver   -- cross-file goto-definition, references,
  --                       hover, completion, workspace symbols, and
  --                       project-wide indexing via includeIndexing
  --                       globs.
  --
  -- Why both: verible-verilog-ls advertises definitionProvider but its
  -- cross-file symbol resolution is broken in v0.0-3946-g851d3ff4
  -- (current Homebrew stable, verified empirically -- even with a
  -- minimal 2-file pkg/module project and an absolute --file_list_path,
  -- both `textDocument/definition` and `workspace/symbol` return empty).
  -- svlangserver fills the navigation gap. Verible still owns lint +
  -- formatting (the latter via conform.nvim, separate path).
  --
  -- The LspAttach handler below disables verible's
  -- definitionProvider / referencesProvider / renameProvider once it
  -- attaches so svlangserver wins those requests cleanly.
  --
  -- ── verible (lint + outline + format binary) ────────────────────────
  --
  -- `--rules_config_search` makes verible walk upward from each analyzed
  -- file looking for `.rules.verible_lint`, picking up project-level rule
  -- overrides automatically.
  verible = {
    system = true,
    filetypes = { "systemverilog", "verilog" },
    config = {
      cmd = { "verible-verilog-ls", "--rules_config_search" },
      root_markers = {
        "verible.filelist",
        ".rules.verible_lint",
        ".git",
      },
    },
  },

  -- ── svlangserver (navigation: gd / gr / K / completion) ─────────────
  --
  -- Mason-installed via npm (`@imc-trading/svlangserver`). The on-demand
  -- installer below pulls it on first SV file open.
  --
  -- includeIndexing tells svlangserver which files to read into its
  -- symbol table at workspace startup. The default LazyVim/lspconfig
  -- glob of `**/*.{v,vh,sv,svh}` covers any layout (flat, distributed,
  -- or rtl/tb subfolders). excludeIndexing skips the
  -- `build/` output directory so verilator's intermediate `.sv` files
  -- don't pollute the symbol table.
  --
  -- linter = "none" disables svlangserver's bundled verilator runner --
  -- nvim-lint already runs verilator with project-aware args (see
  -- linting.lua's filelist resolver), and double-linting would surface
  -- every diagnostic twice. The `formatCommand` setting is left at its
  -- default because conform.nvim handles all SV formatting via the
  -- standalone `verible-verilog-format` binary, bypassing the LSP
  -- formatting path entirely.
  svlangserver = {
    mason = "svlangserver",
    filetypes = { "systemverilog", "verilog" },
    config = {
      root_markers = { ".svlangserver", ".git" },
      settings = {
        systemverilog = {
          includeIndexing = { "**/*.{v,vh,sv,svh}" },
          excludeIndexing = { "build/**" },
          linter = "none",
        },
      },
      -- svlangserver does NOT auto-index the workspace on startup --
      -- it only builds its symbol table when the
      -- `systemverilog.build_index` workspace command is invoked.
      -- Without this hook, every cross-file `gd` / `gr` / `K` request
      -- silently returns empty until the user manually runs
      -- `:LspSvlangserverBuildIndex` (the user command the lspconfig
      -- default registers in on_attach). Firing it from on_attach
      -- (gated to once per client.id since LspAttach runs per buffer)
      -- triggers indexing the moment the LSP attaches to the first SV
      -- buffer in a project.
      on_attach = function(client, _)
        if not client._sv_indexed then
          client._sv_indexed = true
          pcall(function()
            client:exec_cmd({
              title = "Build Index",
              command = "systemverilog.build_index",
            })
          end)
        end
      end,
    },
  },
}

return {
  -- Mason: package manager for LSPs (and later formatters/linters).
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    keys = {
      { "<leader>mm", "<cmd>Mason<cr>", desc = "Mason Home" },
      { "<leader>mu", "<cmd>MasonUpdate<cr>", desc = "Mason Update" },
    },
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "",
          package_pending = "",
          package_uninstalled = "",
        },
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },

  -- nvim-lspconfig: ships default configs (lsp/<name>.lua) for every server
  -- on the runtimepath. We layer per-server overrides via vim.lsp.config()
  -- and defer vim.lsp.enable() until the mason package is actually installed.
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "saghen/blink.cmp",
      -- SchemaStore.nvim is loaded lazily by jsonls / yamlls before_init
      -- hooks and never via require() at top level, so it stays out of
      -- the startup path entirely.
      { "b0o/SchemaStore.nvim", lazy = true, version = false },
      -- neoconf.nvim auto-merges per-project LSP overrides from
      -- `.neoconf.json` and `.vscode/settings.json` into the LSP
      -- config when a server attaches. Critical: neoconf.setup()
      -- MUST run before any vim.lsp.config() calls so its before_init
      -- hooks are installed first. We do that at the top of the
      -- config function below. lazy = true keeps it off the startup
      -- path; lspconfig pulls it in as a dep when an LSP attaches.
      { "folke/neoconf.nvim", lazy = true, cmd = "Neoconf", opts = {} },
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Filetype detection for languages whose extensions Neovim doesn't
      -- ship with built-in mappings for, or where the LSP / treesitter
      -- parser expects a specific filetype name. Adding a redundant
      -- mapping here is harmless -- ft.add only sets the value if no
      -- existing rule matches first.
      vim.filetype.add({
        extension = {
          astro = "astro",
          gleam = "gleam",
          mdx = "markdown.mdx",
          nu = "nu",
          prisma = "prisma",
          rego = "rego",
          sol = "solidity",
          svelte = "svelte",
          thrift = "thrift",
          typ = "typst",
          twig = "twig",
          ["html.twig"] = "twig",
          tf = "terraform",
          tfvars = "terraform",
          hcl = "hcl",
          tpl = "helm",
        },
        filename = {
          [".envrc"] = "direnv",
          ["Tiltfile"] = "bzl",
          ["WORKSPACE"] = "bzl",
          ["BUILD.bazel"] = "bzl",
        },
        pattern = {
          [".*/templates/.*%.tpl"] = "helm",
          [".*/templates/.*%.ya?ml"] = "helm",
          ["helmfile.*%.ya?ml"] = "helm",
        },
      })

      -- neoconf.nvim: per-project LSP overrides via `.neoconf.json`
      -- and `.vscode/settings.json` in the project root. Must be
      -- set up BEFORE any vim.lsp.config() calls below so neoconf's
      -- before_init / on_new_config hooks are installed first;
      -- otherwise per-server overrides registered via vim.lsp.config()
      -- run before neoconf gets a chance to merge in the file-based
      -- settings, and the project overrides silently lose the race.
      -- pcall'd so a missing neoconf module degrades to vanilla LSP
      -- instead of crashing.
      pcall(function()
        require("neoconf").setup({})
      end)

      -- Global defaults: root markers + client capabilities. blink.cmp is a
      -- dependency so it's loaded before we run; merging its capabilities
      -- lets every LSP server know we support snippets, resolve, and the
      -- rest of the completion niceties blink provides.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local has_blink, blink = pcall(require, "blink.cmp")
      if has_blink and type(blink.get_lsp_capabilities) == "function" then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end
      vim.lsp.config("*", {
        root_markers = { ".git" },
        capabilities = capabilities,
      })

      -- Register per-server overrides. This does NOT start the server --
      -- only vim.lsp.enable() does, and we defer that until the mason
      -- package is actually installed.
      for name, entry in pairs(servers) do
        if entry.config then
          vim.lsp.config(name, entry.config)
        end
      end

      -- Diagnostic UI: nerd font signs, inline virtual text, sorted floats.
      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          prefix = "●",
          source = "if_many",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
          },
        },
        float = {
          border = "rounded",
          source = "if_many",
          header = "",
          prefix = "",
        },
      })

      -- LspAttach: buffer-local keymaps and opt-in feature enablement. Runs
      -- once per (client, buffer) pair so inlay hints and keymaps kick in
      -- for each server that attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ACHLspAttach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end
          local bufnr = ev.buf

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          -- Navigation
          map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "gI", vim.lsp.buf.implementation, "Go to Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Go to Type Definition")

          -- Info
          map("n", "K", vim.lsp.buf.hover, "Hover Docs")
          map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
          map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

          -- Code actions (format-on-save + manual <leader>cf is owned by
          -- conform.nvim in formatting.lua). <leader>cr (Rename) is owned
          -- by inc-rename.nvim below for live in-buffer preview,
          -- <leader>cR (Rename File) is owned by Snacks.rename via the
          -- snacks keys spec below, and <leader>cs (Outline) is owned by
          -- outline.nvim in editor.lua -- the vanilla
          -- vim.lsp.buf.document_symbol dumps to quickfix which is much
          -- worse UX than a sidebar tree.
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostic")
          map("n", "<leader>cl", "<cmd>LspInfo<cr>", "LSP Info")
          map("n", "<leader>cS", vim.lsp.buf.workspace_symbol, "Workspace Symbols")

          -- Organize Imports: directly fires the `source.organizeImports`
          -- code action so the user doesn't have to go through the
          -- <leader>ca menu. For TS this removes unused imports + sorts
          -- them; for Python (via pyright) it sorts imports; etc. Wrapped
          -- in pcall so a buffer where the LSP doesn't expose this action
          -- silently no-ops instead of erroring. Borrowed from LazyVim's
          -- main lsp/init.lua <leader>co binding.
          map("n", "<leader>co", function()
            pcall(vim.lsp.buf.code_action, {
              context = { only = { "source.organizeImports" }, diagnostics = {} },
              apply = true,
            })
          end, "Organize Imports")

          -- Diagnostic navigation (uses the 0.11+ jump API)
          map("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, "Next Diagnostic")
          map("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, "Prev Diagnostic")

          -- Inlay hints: enable when the server supports them, EXCEPT
          -- on vue buffers. vue_ls (Volar) emits inlay hints on every
          -- prop binding which is noisy and slows down rendering --
          -- LazyVim's main lsp/init.lua excludes vue from the inlay
          -- hints filetype list for the same reason. Can be toggled
          -- globally later via <leader>uh in keymaps.lua.
          if client:supports_method("textDocument/inlayHint") and vim.bo[bufnr].filetype ~= "vue" then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          end

          -- Code lenses: bind run + activate codelens for this buffer.
          -- Gated on the server supporting textDocument/codeLens. The
          -- user's gopls config enables the full codelens set
          -- (gc_details, generate, regenerate_cgo, run_govulncheck,
          -- test, tidy, upgrade_dependency, vendor) so this binding
          -- is what makes those lenses actually invokable.
          --
          -- `vim.lsp.codelens.enable(true, { bufnr })` is the 0.12+
          -- API: it's stateful (enables codelens handling for the
          -- buffer once) and Neovim manages the refresh lifecycle
          -- internally via the codelens decoration provider. The old
          -- pattern (manual `refresh()` calls from BufEnter /
          -- CursorHold / InsertLeave autocmds) is now deprecated and
          -- not needed -- the decoration provider handles re-fetching
          -- automatically when the buffer changes or the cursor moves.
          if client:supports_method("textDocument/codeLens") then
            map({ "n", "v" }, "<leader>cc", vim.lsp.codelens.run, "Run Codelens")
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end

          -- Ruff serves textDocument/hover on Python files but its hover
          -- payload is one-line and inferior to pyright's. With both
          -- attached we get pyright's docs only if ruff doesn't preempt
          -- the request, so we disable hover on ruff entirely. Pyright
          -- still owns hover/definition/references; ruff still owns
          -- diagnostics + the formatter via conform.
          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          -- Verible LSP advertises definitionProvider/referencesProvider/
          -- renameProvider but its cross-file symbol resolution is broken
          -- in v0.0-3946-g851d3ff4 (verified empirically -- even with a
          -- minimal 2-file pkg/module project and an absolute
          -- --file_list_path, both `textDocument/definition` and
          -- `workspace/symbol` return empty). Disable those capabilities
          -- on the verible client so the same requests fall through to
          -- svlangserver, which handles cross-file SV navigation
          -- correctly. Verible keeps providing diagnostics (lint),
          -- document symbols (outline), and is invoked by conform.nvim
          -- as the formatter via a separate non-LSP path.
          if client.name == "verible" then
            client.server_capabilities.definitionProvider = false
            client.server_capabilities.referencesProvider = false
            client.server_capabilities.renameProvider = false
          end

          -- ts_ls TS-specific code action shortcuts. Borrowed from
          -- LazyVim's extras/lang/typescript/vtsls.lua -- the same
          -- `source.addMissingImports.ts` / `source.fixAll.ts`
          -- commands work for both vtsls and ts_ls because both
          -- wrap the same upstream tsserver. Each binding fires
          -- the matching code action with `apply = true` so the
          -- fix runs without the user picking from a menu, and
          -- the call is `pcall`-wrapped so a buffer where the
          -- action isn't available silently no-ops.
          --
          -- Bound buffer-locally only when ts_ls is the attaching
          -- client so they don't pollute non-TS buffers.
          if client.name == "ts_ls" then
            map("n", "<leader>cM", function()
              pcall(vim.lsp.buf.code_action, {
                context = { only = { "source.addMissingImports.ts" }, diagnostics = {} },
                apply = true,
              })
            end, "Add Missing Imports (TS)")
            map("n", "<leader>cD", function()
              pcall(vim.lsp.buf.code_action, {
                context = { only = { "source.fixAll.ts" }, diagnostics = {} },
                apply = true,
              })
            end, "Fix All Diagnostics (TS)")
          end
        end,
      })

      -- ----------------------------------------------------------------
      -- On-demand installer
      -- ----------------------------------------------------------------
      -- Build a filetype -> { server, server, ... } index so a single
      -- FileType autocmd can find everything that should attach to the
      -- current buffer's filetype.
      local ft_index = {}
      for name, entry in pairs(servers) do
        for _, ft in ipairs(entry.filetypes) do
          ft_index[ft] = ft_index[ft] or {}
          table.insert(ft_index[ft], name)
        end
      end

      local enabled = {} -- server -> true once vim.lsp.enable has been called
      local installing = {} -- server -> true while an install is in flight

      -- After vim.lsp.enable, fire FileType for any already-loaded buffers
      -- whose filetype matches so the newly-registered enable autocmd picks
      -- them up. Scheduled so we don't re-fire FileType while still inside
      -- the current FileType handler.
      local function attach_to_loaded_buffers(filetypes)
        local fts = {}
        for _, ft in ipairs(filetypes) do
          fts[ft] = true
        end
        vim.schedule(function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) and fts[vim.bo[bufnr].filetype] then
              vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
            end
          end
        end)
      end

      local function enable_server(name)
        enabled[name] = true
        vim.lsp.enable(name)
        attach_to_loaded_buffers(servers[name].filetypes)
      end

      local function ensure_server(name)
        if enabled[name] or installing[name] then
          return
        end
        local entry = servers[name]

        -- System binaries (sourcekit-lsp, R): enable directly if the root
        -- command exists on PATH; otherwise skip silently.
        if entry.system then
          local cmd = entry.config and entry.config.cmd and entry.config.cmd[1]
          if cmd and vim.fn.executable(cmd) == 1 then
            enable_server(name)
          end
          return
        end

        local ok, mr = pcall(require, "mason-registry")
        if not ok then
          return
        end

        -- mason-registry is lazy-loaded: on a cold-start nvim the package
        -- index hasn't been fetched yet and has_package() silently returns
        -- false. mr.refresh(cb) guarantees cb runs after the registry is
        -- populated (fires immediately on subsequent calls since the refresh
        -- result is cached).
        mr.refresh(vim.schedule_wrap(function()
          if enabled[name] or installing[name] then
            return
          end
          if not mr.has_package(entry.mason) then
            return
          end

          local pkg = mr.get_package(entry.mason)
          if pkg:is_installed() then
            enable_server(name)
            return
          end

          installing[name] = true

          local function on_done()
            installing[name] = nil
            if pkg:is_installed() then
              vim.notify(
                ("LSP installed: %s"):format(entry.mason),
                vim.log.levels.INFO,
                { title = "LSP", icon = icons.plugins.lsp }
              )
              enable_server(name)
            else
              vim.notify(
                ("LSP install failed: %s"):format(entry.mason),
                vim.log.levels.WARN,
                { title = "LSP", icon = icons.plugins.lsp }
              )
            end
          end

          -- Cross-installer race guard. mason-registry returns the
          -- SAME `pkg` object instance for a given mason package
          -- across every caller (the registry caches), and
          -- `pkg:install()` asserts internally that the package
          -- isn't already installing. So if formatting.lua or
          -- linting.lua started an install for this same mason
          -- package (e.g. `ruff` is both an LSP and a formatter)
          -- before this callback fired, we must NOT call install()
          -- ourselves -- attach a `closed` listener to the
          -- existing handle instead. The on_done callback fires
          -- exactly once per closer, regardless of which installer
          -- kicked it off, and re-checks pkg:is_installed() to
          -- decide success vs failure.
          if pkg:is_installing() then
            pkg:get_install_handle():if_present(function(handle)
              handle:once("closed", vim.schedule_wrap(on_done))
            end)
            return
          end

          vim.notify(
            ("Installing LSP: %s"):format(entry.mason),
            vim.log.levels.INFO,
            { title = "LSP", icon = icons.plugins.lsp }
          )
          pkg:install():once("closed", vim.schedule_wrap(on_done))
        end))
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHLspInstall", { clear = true }),
        callback = function(args)
          local list = ft_index[args.match]
          if not list then
            return
          end
          for _, name in ipairs(list) do
            ensure_server(name)
          end
        end,
      })

      -- Cover the buffer that lazy-loaded this plugin: its FileType event
      -- already fired before our autocmd existed, so we re-fire it manually.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
        end
      end
    end,
  },

  -- clangd_extensions.nvim: AST viewer + extra inlay hints + clangd
  -- memory usage panel on top of the base clangd LSP. Lazy-loaded on
  -- C/C++/Obj-C/Obj-C++ filetypes so it doesn't touch startup unless
  -- you actually open a C/C++ file. Borrowed from LazyVim's
  -- extras/lang/clangd.lua. Sets `<leader>ch` for source/header
  -- switching, which is the canonical clangd command this binding
  -- has lived under in every LazyVim/AstroNvim/LunarVim distro.
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp", "objc", "objcpp" },
    keys = {
      { "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
    },
    opts = {
      inlay_hints = {
        inline = false,
      },
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          specifier = "",
          statement = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
  },

  -- inc-rename.nvim: live LSP rename with in-buffer preview. Replaces the
  -- old vim.ui.input -> vim.lsp.buf.rename flow with `:IncRename newname`,
  -- where every keystroke previews the rename across every reference in
  -- the current buffer (and adjacent buffers if the LSP server reports
  -- workspace edits). Bound to <leader>cr below as an expr keymap so the
  -- cmdline pre-fills with `IncRename <cword>` and the user just edits
  -- the existing token instead of typing it from scratch.
  --
  -- Pairs with the noice cmdline preset that's set in ui.lua via the
  -- `inc_rename = true` preset toggle so the live preview floats look
  -- consistent with the rest of the UI.
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      {
        "<leader>cr",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename Symbol (inc-rename)",
      },
    },
    opts = {},
  },

  -- noice.nvim: enable the inc-rename preset so noice's cmdline popup
  -- formats the IncRename live preview correctly. The base noice config
  -- lives in ui.lua; this is a keys-only / opts-only extension that
  -- lazy.nvim will deep-merge.
  {
    "folke/noice.nvim",
    optional = true,
    opts = {
      presets = { inc_rename = true },
    },
  },

  -- snacks rename file: workspace-aware file rename via the
  -- `Snacks.rename.rename_file()` utility. Prompts for the new name,
  -- sends `workspace/willRenameFiles` to the LSP (so it can update
  -- imports BEFORE the file moves), renames the file on disk, then
  -- sends `workspace/didRenameFiles` to finalize. For TS this means
  -- renaming `Foo.tsx` -> `Bar.tsx` automatically updates every
  -- `import Foo from "./Foo"` across the workspace. Borrowed from
  -- LazyVim's main lsp/init.lua <leader>cR binding.
  --
  -- Bound as a top-level snacks keys spec (not in LspAttach) so it
  -- works in any buffer regardless of LSP attachment status -- when
  -- no LSP is attached the file still gets renamed, just without
  -- import propagation.
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>cR",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename File",
      },
    },
  },

  -- which-key: extend spec with code / LSP / mason keymap icons.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Code group
        { "<leader>c", group = "Code", icon = { icon = icons.ui.code, color = "yellow" } },
        {
          "<leader>ca",
          desc = "Code Action",
          icon = { icon = icons.lsp.code_action, color = "yellow" },
        },
        {
          "<leader>cr",
          desc = "Rename Symbol",
          icon = { icon = icons.lsp.rename, color = "orange" },
        },
        {
          "<leader>cR",
          desc = "Rename File",
          icon = { icon = icons.ui.pencil, color = "orange" },
        },
        {
          "<leader>cc",
          desc = "Run Codelens",
          icon = { icon = icons.lsp.code_lens, color = "green" },
        },
        {
          "<leader>co",
          desc = "Organize Imports",
          icon = { icon = icons.ui.sort, color = "blue" },
        },
        -- ts_ls-only: declared inside LspAttach above (gated on
        -- client.name == "ts_ls"). Lives in this which-key block so
        -- the icons register globally; which-key handles filtering
        -- by checking whether the buffer-local keymap is bound.
        {
          "<leader>cM",
          desc = "Add Missing Imports (TS)",
          icon = { icon = icons.ui.download, color = "green" },
        },
        {
          "<leader>cD",
          desc = "Fix All Diagnostics (TS)",
          icon = { icon = icons.ui.wand, color = "purple" },
        },
        {
          "<leader>cd",
          desc = "Line Diagnostic",
          icon = { icon = icons.lsp.diagnostic, color = "red" },
        },
        {
          "<leader>cl",
          desc = "LSP Info",
          icon = { icon = icons.ui.info, color = "cyan" },
        },
        -- clangd-only: declared by clangd_extensions.nvim above. Lives
        -- in this which-key block so the icon registers globally
        -- (which-key does its own filetype filtering at render time).
        {
          "<leader>ch",
          desc = "Switch Source/Header",
          icon = { icon = icons.ui.split_h, color = "blue" },
        },
        -- <leader>cs (Outline) lives in editor.lua's which-key spec since
        -- outline.nvim owns it. Keeping the icon registration there
        -- adjacent to the keymap definition.
        {
          "<leader>cS",
          desc = "Workspace Symbols",
          icon = { icon = icons.lsp.workspace_symbol, color = "green" },
        },

        -- Mason group
        { "<leader>m", group = "Mason", icon = { icon = icons.plugins.mason, color = "purple" } },
        { "<leader>mm", desc = "Mason Home", icon = { icon = icons.plugins.mason, color = "purple" } },
        { "<leader>mu", desc = "Mason Update", icon = { icon = icons.plugins.mason, color = "purple" } },
      },
    },
  },
}
