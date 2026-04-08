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
  stylua                  = "stylua",
  prettier                = "prettier",
  prettierd               = "prettierd",
  ruff_format             = "ruff",
  ruff_fix                = "ruff",
  ruff_organize_imports   = "ruff",
  black                   = "black",
  isort                   = "isort",
  shfmt                   = "shfmt",
  ["clang-format"]        = "clang-format",
  goimports               = "goimports",
  gofumpt                 = "gofumpt",
  latexindent             = "latexindent",
  rubocop                 = "rubocop",
  ["bibtex-tidy"]         = "bibtex-tidy",
  perltidy                = nil, -- system (cpan / brew)
  swift_format            = nil, -- system (Xcode toolchain)

  -- Markdown extras (conditional formatters; see `formatters` block below).
  ["markdown-toc"]        = "markdown-toc",
  ["markdownlint-cli2"]   = "markdownlint-cli2",

  -- New language formatters added alongside the lang/* additions in
  -- lsp.lua. Anything `nil` is system-provided and lives outside mason.
  rustfmt                 = nil,                     -- ships with rustup
  zigfmt                  = nil,                     -- `zig fmt` (system)
  alejandra               = "alejandra",             -- nix
  ormolu                  = "ormolu",                -- haskell
  fourmolu                = "fourmolu",              -- haskell alt
  ocamlformat             = nil,                     -- system (opam)
  zprint                  = "zprint",                -- clojure
  erlfmt                  = "erlfmt",                -- erlang
  ["mix"]                 = nil,                     -- elixir (system, ships with elixir)
  ["gleam"]               = nil,                     -- `gleam format` (system)
  ["dart_format"]         = nil,                     -- `dart format` (system)
  csharpier               = "csharpier",             -- .NET
  ktlint                  = "ktlint",                -- kotlin
  scalafmt                = "scalafmt",              -- scala
  ["google-java-format"]  = "google-java-format",
  ["php-cs-fixer"]        = "php-cs-fixer",          -- php
  pint                    = "pint",                  -- php (laravel)
  taplo                   = "taplo",                 -- toml (also LSP, also formatter)
  sqlfluff                = "sqlfluff",              -- sql (also linter)
  sql_formatter           = "sql-formatter",         -- sql (alt)
  ["forge_fmt"]           = nil,                     -- solidity (system, foundry)
  cmake_format            = "cmake-format",
  ["terraform_fmt"]       = nil,                     -- system (terraform CLI)
  typstyle                = "typstyle",              -- typst
  ["elm-format"]          = "elm-format",            -- elm
}

-- Filetype -> ordered list of formatters. `stop_after_first = true` makes
-- conform fall back to the second entry only if the first isn't available,
-- which is what we want for the prettierd -> prettier chain.
--
-- Markdown picks up two conditional formatters in addition to prettier:
-- markdownlint-cli2 (only fires if there are markdownlint diagnostics on
-- the buffer) and markdown-toc (only fires if the buffer contains a
-- `<!-- toc -->` marker). Conditions live in the `formatters` block below.
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
  markdown         = { "prettierd", "prettier", "markdownlint-cli2", "markdown-toc" },
  ["markdown.mdx"] = { "prettierd", "prettier", "markdownlint-cli2", "markdown-toc" },
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

  -- ── Web (prettier handles svelte/vue/astro/angular via plugins
  --        installed in the project's package.json) ─────────────
  svelte           = { "prettierd", "prettier", stop_after_first = true },
  vue              = { "prettierd", "prettier", stop_after_first = true },
  astro            = { "prettierd", "prettier", stop_after_first = true },
  angular          = { "prettierd", "prettier", stop_after_first = true },
  htmlangular      = { "prettierd", "prettier", stop_after_first = true },
  handlebars       = { "prettierd", "prettier", stop_after_first = true },
  prisma           = { "prettierd", "prettier", stop_after_first = true },
  graphql          = { "prettierd", "prettier", stop_after_first = true },

  -- ── Systems ────────────────────────────────────────────────
  rust             = { "rustfmt" },
  zig              = { "zigfmt" },
  nix              = { "alejandra" },
  haskell          = { "ormolu" },
  ocaml            = { "ocamlformat" },
  clojure          = { "zprint" },
  erlang           = { "erlfmt" },
  elixir           = { "mix" },
  eelixir          = { "mix" },
  heex             = { "mix" },
  gleam            = { "gleam" },
  dart             = { "dart_format" },
  cs               = { "csharpier" },
  kotlin           = { "ktlint" },
  scala            = { "scalafmt" },
  java             = { "google-java-format" },
  php              = { "php-cs-fixer" },

  -- ── Infra / Data ───────────────────────────────────────────
  cmake            = { "cmake_format" },
  terraform        = { "terraform_fmt" },
  ["terraform-vars"] = { "terraform_fmt" },
  hcl              = { "terraform_fmt" },
  toml             = { "taplo" },
  sql              = { "sqlfluff" },
  mysql            = { "sqlfluff" },
  solidity         = { "forge_fmt" },

  -- ── Niche ──────────────────────────────────────────────────
  typst            = { "typstyle" },
  elm              = { "elm-format" },
}

-- prettier `condition` helper. Asks prettier whether it can parse the
-- current file before letting conform run it. The default-supported
-- filetype set short-circuits the shell-out for the common cases (the 13
-- filetypes prettier ships with built-in parsers for); anything else
-- pays the cost of one `prettier --file-info` invocation per buffer,
-- cached by buffer number so subsequent saves are free. Borrowed from
-- LazyVim's extras/formatting/prettier.lua and trimmed: no has_config
-- toggle, the cache is invalidated implicitly when the buffer is wiped.
local prettier_parser_cache = {}
local prettier_default_supported = {
  css              = true,
  html             = true,
  javascript       = true,
  javascriptreact  = true,
  json             = true,
  jsonc            = true,
  less             = true,
  markdown         = true,
  ["markdown.mdx"] = true,
  scss             = true,
  typescript       = true,
  typescriptreact  = true,
  yaml             = true,
}

local function prettier_has_parser(ctx)
  local cached = prettier_parser_cache[ctx.buf]
  if cached ~= nil then return cached end

  local ft = vim.bo[ctx.buf].filetype
  if prettier_default_supported[ft] then
    prettier_parser_cache[ctx.buf] = true
    return true
  end

  -- Out-of-the-box prettier doesn't know this filetype; ask the binary
  -- whether a plugin (e.g. prettier-plugin-svelte) has registered one.
  local result = vim.fn.system({ "prettier", "--file-info", ctx.filename })
  local ok, info = pcall(vim.json.decode, result)
  local parser = ok and info and info.inferredParser
  local has = parser ~= nil and parser ~= vim.NIL
  prettier_parser_cache[ctx.buf] = has
  return has
end

-- Drop the cache entry when a buffer is wiped so a recreated buffer with
-- the same number doesn't inherit a stale answer.
vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("ACHPrettierParserCache", { clear = true }),
  callback = function(args) prettier_parser_cache[args.buf] = nil end,
})

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
      --
      -- prettier / prettierd: gated by a `condition` callback that asks
      -- prettier whether it can actually parse the current file. Without
      -- this, conform will happily run prettier on a filetype it doesn't
      -- support (e.g. svelte without the plugin) and dump a parser error
      -- into the buffer or fall through silently. With it, the formatter
      -- skips the file and conform's `lsp_format = "fallback"` chain hands
      -- off to the LSP formatter instead. Borrowed from LazyVim's
      -- extras/formatting/prettier.lua, with two changes: (1) the 13
      -- default-supported filetypes short-circuit before any shell-out,
      -- and (2) the same condition is applied to both `prettier` and
      -- `prettierd` since they share the prettierd -> prettier fallback
      -- chain in formatters_by_ft.
      formatters = {
        injected  = { options = { ignore_errors = true } },
        prettier  = { condition = function(_, ctx) return prettier_has_parser(ctx) end },
        prettierd = { condition = function(_, ctx) return prettier_has_parser(ctx) end },

        -- markdown-toc only runs on buffers that contain a `<!-- toc -->`
        -- marker. Without this gate, conform would generate a TOC in
        -- every markdown file on save -- not what you want for blog
        -- posts, README.md without a TOC, etc.
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then return true end
            end
            return false
          end,
        },

        -- markdownlint-cli2 only runs if there are existing markdownlint
        -- diagnostics on the buffer. So nvim-lint surfaces lint issues,
        -- the user opts into auto-fixing by saving, and clean files pay
        -- zero cost. Linter source name is `markdownlint`, not the
        -- formatter name -- nvim-lint reports under the linter binary.
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
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
