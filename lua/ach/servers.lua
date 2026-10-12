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
    on_init = function(client) client.server_capabilities.hoverProvider = false end,
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

  -- astro-ls will not start without a path to TypeScript's library. A project
  -- with TypeScript installed gives its own; a file outside one, or a project
  -- whose packages are not installed yet, gets the copy Mason installed with
  -- the server.
  astro = {
    before_init = function(_, config)
      local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
      if tsdk == "" then
        tsdk = mason .. "/astro-language-server/node_modules/typescript/lib"
      end
      config.init_options = config.init_options or {}
      config.init_options.typescript = config.init_options.typescript or {}
      config.init_options.typescript.tsdk = tsdk
    end,
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
