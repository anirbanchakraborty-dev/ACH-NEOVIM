-- Formatting: conform.nvim owns both format-on-save and the manual
-- <leader>cf keymap. Formatters install on demand via mason on the first
-- FileType event for a supported filetype, mirroring the lsp.lua pattern.
--
-- Bypass format-on-save at runtime with `:let g:disable_autoformat = 1` or
-- per-buffer via `:let b:disable_autoformat = 1`; this lets you commit a
-- file unmodified without disabling the whole stack.

local icons = require("config.icons")

-- conform formatter name -> mason package name. Entries set to nil are
-- formatters that aren't in the mason registry and must be provided by the
-- system toolchain (perltidy via cpan/brew, swift-format via Xcode).
local formatter_to_mason = {
  stylua                = "stylua",
  prettier              = "prettier",
  prettierd             = "prettierd",
  ruff_format           = "ruff",
  ruff_fix              = "ruff",
  ruff_organize_imports = "ruff",
  black                 = "black",
  isort                 = "isort",
  shfmt                 = "shfmt",
  ["clang-format"]      = "clang-format",
  goimports             = "goimports",
  gofumpt               = "gofumpt",
  latexindent           = "latexindent",
  rubocop               = "rubocop",
  ["bibtex-tidy"]       = "bibtex-tidy",
  perltidy              = nil, -- system (cpan / brew)
  swift_format          = nil, -- system (Xcode toolchain)
}

-- Filetype -> ordered list of formatters. `stop_after_first = true` makes
-- conform fall back to the second entry only if the first isn't available,
-- which is what we want for the prettierd -> prettier chain.
local formatters_by_ft = {
  lua              = { "stylua" },
  python           = { "ruff_organize_imports", "ruff_format" },
  javascript       = { "prettierd", "prettier", stop_after_first = true },
  javascriptreact  = { "prettierd", "prettier", stop_after_first = true },
  typescript       = { "prettierd", "prettier", stop_after_first = true },
  typescriptreact  = { "prettierd", "prettier", stop_after_first = true },
  html             = { "prettierd", "prettier", stop_after_first = true },
  css              = { "prettierd", "prettier", stop_after_first = true },
  scss             = { "prettierd", "prettier", stop_after_first = true },
  less             = { "prettierd", "prettier", stop_after_first = true },
  json             = { "prettierd", "prettier", stop_after_first = true },
  jsonc            = { "prettierd", "prettier", stop_after_first = true },
  yaml             = { "prettierd", "prettier", stop_after_first = true },
  markdown         = { "prettierd", "prettier", stop_after_first = true },
  ["markdown.mdx"] = { "prettierd", "prettier", stop_after_first = true },
  sh               = { "shfmt" },
  bash             = { "shfmt" },
  zsh              = { "shfmt" },
  c                = { "clang-format" },
  cpp              = { "clang-format" },
  go               = { "goimports", "gofumpt" },
  tex              = { "latexindent" },
  bib              = { "bibtex-tidy" },
  ruby             = { "rubocop" },
  perl             = { "perltidy" },
  swift            = { "swift_format" },
}

return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format Buffer",
      },
      -- Format embedded language blocks (e.g. lua heredocs in shell scripts,
      -- code fences in markdown, SQL strings in Python, HTML/CSS/JS inside
      -- Vue/Svelte SFCs). Each block is formatted with its own formatter.
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      -- Per-formatter overrides. `injected` is conform's built-in recursive
      -- formatter for embedded language blocks; ignore_errors silences spam
      -- when an embedded block has a parse error (e.g. an in-progress code
      -- fence in a draft markdown file).
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
      -- Format-on-save: sync so the formatted content is what lands on disk.
      -- Guarded by g:disable_autoformat / b:disable_autoformat so the user
      -- can turn it off per session or per buffer without unloading conform.
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
      -- Defaults inherited by manual format calls (<leader>cf / <leader>cF)
      -- when they don't pass timeout_ms explicitly. Save-time formatting is
      -- still capped at 1500ms via the format_on_save table above.
      default_format_opts = {
        timeout_ms  = 3000,
        lsp_format  = "fallback",
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)

      -- ----------------------------------------------------------------
      -- On-demand installer -- same shape as lsp.lua's. On FileType, look
      -- up every formatter configured for that filetype, skip ones already
      -- installed or not in mason, and fire an async install with toast
      -- feedback for anything missing.
      -- ----------------------------------------------------------------
      local installing = {}

      local function ensure_formatter(name)
        if installing[name] then return end
        local mason_name = formatter_to_mason[name]
        if not mason_name then return end -- system-provided or unknown

        local ok, mr = pcall(require, "mason-registry")
        if not ok then return end

        -- mason-registry is lazy-loaded: on a cold-start nvim the package
        -- index hasn't been fetched yet and has_package() silently returns
        -- false. Wrapping the query in mr.refresh(cb) guarantees cb runs
        -- after the registry is populated (no-op on subsequent calls since
        -- the refresh result is cached).
        mr.refresh(vim.schedule_wrap(function()
          if installing[name] then return end
          if not mr.has_package(mason_name) then return end

          local pkg = mr.get_package(mason_name)
          if pkg:is_installed() then return end

          installing[name] = true
          vim.notify(
            ("Installing formatter: %s"):format(mason_name),
            vim.log.levels.INFO,
            { title = "Conform", icon = icons.lsp.format }
          )

          pkg:install():once("closed", vim.schedule_wrap(function()
            installing[name] = nil
            if pkg:is_installed() then
              vim.notify(
                ("Formatter installed: %s"):format(mason_name),
                vim.log.levels.INFO,
                { title = "Conform", icon = icons.lsp.format }
              )
            else
              vim.notify(
                ("Formatter install failed: %s"):format(mason_name),
                vim.log.levels.WARN,
                { title = "Conform", icon = icons.lsp.format }
              )
            end
          end))
        end))
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHFormatInstall", { clear = true }),
        callback = function(args)
          local list = formatters_by_ft[args.match]
          if not list then return end
          -- ipairs stops at the `stop_after_first` hash key naturally since
          -- it's not an integer index, so we only iterate actual formatters.
          for _, name in ipairs(list) do
            if type(name) == "string" then
              ensure_formatter(name)
            end
          end
        end,
      })

      -- Cover the buffer that lazy-loaded us: its FileType event already
      -- fired before our autocmd existed.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
        end
      end

      -- User commands to toggle format-on-save at runtime.
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, { desc = "Disable autoformat-on-save", bang = true })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save" })
    end,
  },

  -- which-key: <leader>cf / <leader>cF icons (keymaps registered by conform above).
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "<leader>cf", desc = "Format Buffer",        icon = { icon = icons.lsp.format, color = "blue" } },
        { "<leader>cF", desc = "Format Injected Langs", icon = { icon = icons.lsp.format, color = "cyan" } },
      },
    },
  },
}
