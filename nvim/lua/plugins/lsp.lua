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
  ts_ls = {
    mason = "typescript-language-server",
    filetypes = {
      "javascript", "javascriptreact", "javascript.jsx",
      "typescript", "typescriptreact", "typescript.tsx",
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
      "html", "css", "scss", "sass", "less",
      "javascriptreact", "typescriptreact", "vue", "svelte",
    },
  },

  -- Data formats
  jsonls = {
    mason = "json-lsp",
    filetypes = { "json", "jsonc" },
  },
  yamlls = {
    mason = "yaml-language-server",
    filetypes = { "yaml", "yaml.docker-compose" },
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
  clangd = {
    mason = "clangd",
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  },

  -- Go
  gopls = {
    mason = "gopls",
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    config = {
      settings = {
        gopls = {
          analyses = { unusedparams = true },
          staticcheck = true,
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
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
}

return {
  -- Mason: package manager for LSPs (and later formatters/linters).
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    keys = {
      { "<leader>mm", "<cmd>Mason<cr>",       desc = "Mason Home" },
      { "<leader>mu", "<cmd>MasonUpdate<cr>", desc = "Mason Update" },
    },
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed   = "",
          package_pending     = "",
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
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
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
            [vim.diagnostic.severity.WARN]  = icons.diagnostics.Warn,
            [vim.diagnostic.severity.INFO]  = icons.diagnostics.Info,
            [vim.diagnostic.severity.HINT]  = icons.diagnostics.Hint,
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
          if not client then return end
          local bufnr = ev.buf

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          -- Navigation
          map("n", "gd", vim.lsp.buf.definition,      "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration,     "Go to Declaration")
          map("n", "gr", vim.lsp.buf.references,      "References")
          map("n", "gI", vim.lsp.buf.implementation,  "Go to Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Go to Type Definition")

          -- Info
          map("n", "K",  vim.lsp.buf.hover,          "Hover Docs")
          map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
          map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

          -- Code actions (format-on-save + manual <leader>cf is owned by
          -- conform.nvim in formatting.lua). <leader>cr (Rename) is owned
          -- by inc-rename.nvim below for live in-buffer preview, and
          -- <leader>cs (Outline) is owned by outline.nvim in editor.lua --
          -- the vanilla vim.lsp.buf.document_symbol dumps to quickfix
          -- which is much worse UX than a sidebar tree.
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>cd", vim.diagnostic.open_float,    "Line Diagnostic")
          map("n", "<leader>cl", "<cmd>LspInfo<cr>",           "LSP Info")
          map("n", "<leader>cS", vim.lsp.buf.workspace_symbol, "Workspace Symbols")

          -- Diagnostic navigation (uses the 0.11+ jump API)
          map("n", "]d", function() vim.diagnostic.jump({ count = 1,  float = true }) end, "Next Diagnostic")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev Diagnostic")

          -- Inlay hints: enable when the server supports them. Can be
          -- toggled globally later via <leader>uh in keymaps.lua.
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
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

      local enabled    = {}  -- server -> true once vim.lsp.enable has been called
      local installing = {}  -- server -> true while an install is in flight

      -- After vim.lsp.enable, fire FileType for any already-loaded buffers
      -- whose filetype matches so the newly-registered enable autocmd picks
      -- them up. Scheduled so we don't re-fire FileType while still inside
      -- the current FileType handler.
      local function attach_to_loaded_buffers(filetypes)
        local fts = {}
        for _, ft in ipairs(filetypes) do fts[ft] = true end
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
        if enabled[name] or installing[name] then return end
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
        if not ok then return end

        -- mason-registry is lazy-loaded: on a cold-start nvim the package
        -- index hasn't been fetched yet and has_package() silently returns
        -- false. mr.refresh(cb) guarantees cb runs after the registry is
        -- populated (fires immediately on subsequent calls since the refresh
        -- result is cached).
        mr.refresh(vim.schedule_wrap(function()
          if enabled[name] or installing[name] then return end
          if not mr.has_package(entry.mason) then return end

          local pkg = mr.get_package(entry.mason)
          if pkg:is_installed() then
            enable_server(name)
            return
          end

          installing[name] = true
          vim.notify(
            ("Installing LSP: %s"):format(entry.mason),
            vim.log.levels.INFO,
            { title = "LSP", icon = icons.plugins.lsp }
          )

          pkg:install():once("closed", vim.schedule_wrap(function()
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
          end))
        end))
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHLspInstall", { clear = true }),
        callback = function(args)
          local list = ft_index[args.match]
          if not list then return end
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

  -- which-key: extend spec with code / LSP / mason keymap icons.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Code group
        { "<leader>c",  group = "Code",  icon = { icon = icons.ui.code,                  color = "yellow" } },
        { "<leader>ca", desc = "Code Action",        icon = { icon = icons.lsp.code_action,      color = "yellow" } },
        { "<leader>cr", desc = "Rename Symbol",      icon = { icon = icons.lsp.rename,           color = "orange" } },
        { "<leader>cd", desc = "Line Diagnostic",    icon = { icon = icons.lsp.diagnostic,       color = "red"    } },
        { "<leader>cl", desc = "LSP Info",           icon = { icon = icons.ui.info,              color = "cyan"   } },
        -- <leader>cs (Outline) lives in editor.lua's which-key spec since
        -- outline.nvim owns it. Keeping the icon registration there
        -- adjacent to the keymap definition.
        { "<leader>cS", desc = "Workspace Symbols",  icon = { icon = icons.lsp.workspace_symbol, color = "green"  } },

        -- Mason group
        { "<leader>m",  group = "Mason", icon = { icon = icons.plugins.mason, color = "purple" } },
        { "<leader>mm", desc = "Mason Home",   icon = { icon = icons.plugins.mason, color = "purple" } },
        { "<leader>mu", desc = "Mason Update", icon = { icon = icons.plugins.mason, color = "purple" } },
      },
    },
  },
}
