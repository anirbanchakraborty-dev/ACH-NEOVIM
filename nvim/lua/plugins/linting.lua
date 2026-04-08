-- Linting: nvim-lint runs external linters async on save / read / insert
-- leave and feeds results into vim.diagnostic alongside LSP diagnostics.
-- Linters install on demand via mason, mirroring lsp.lua and formatting.lua.
--
-- Linters complement LSP-provided diagnostics: where a language server
-- already reports lint-quality issues (ruff-lsp for Python, lua_ls for
-- Lua), we leave it to the LSP and omit the linter here to avoid duplicate
-- squiggles.

local icons = require("config.icons")

-- nvim-lint linter name -> mason package name. nil entries are
-- system-provided / not in mason.
--
-- ESLint is intentionally absent: we use the eslint LSP
-- (vscode-eslint-language-server, registered in lsp.lua) for real-time
-- diagnostics + code actions + auto-fix-on-save instead of running
-- eslint_d as a separate linter. The LSP supersedes the linter; running
-- both would double-count every issue.
local linter_to_mason = {
  shellcheck = "shellcheck",
  markdownlint = "markdownlint",
  hadolint = "hadolint",
  yamllint = "yamllint",

  -- New linters added alongside the lang/* additions in lsp.lua. The
  -- LSP servers themselves serve diagnostics for most languages, so
  -- this list is intentionally short -- only meta-linters that catch
  -- things the LSP doesn't (golangci-lint, ansible-lint, tflint,
  -- sqlfluff, solhint).
  golangcilint = "golangci-lint",
  ["ansible-lint"] = "ansible-lint",
  cmakelint = "cmakelint",
  tflint = "tflint",
  sqlfluff = "sqlfluff",
  solhint = "solhint",
}

local linters_by_ft = {
  -- JS / TS get their lint diagnostics from the eslint LSP, not
  -- from a separate eslint_d linter. See linter_to_mason comment above.
  sh = { "shellcheck" },
  bash = { "shellcheck" },
  zsh = { "shellcheck" },
  markdown = { "markdownlint" },
  ["markdown.mdx"] = { "markdownlint" },
  dockerfile = { "hadolint" },
  yaml = { "yamllint" },

  -- ── Additional linters (LSP-only languages omitted on purpose) ──
  go = { "golangcilint" },
  ["yaml.ansible"] = { "ansible-lint" },
  cmake = { "cmakelint" },
  terraform = { "tflint" },
  ["terraform-vars"] = { "tflint" },
  sql = { "sqlfluff" },
  mysql = { "sqlfluff" },
  solidity = { "solhint" },
}

return {
  {
    "mfussenegger/nvim-lint",
    dependencies = { "mason-org/mason.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- Events that trigger a lint pass. The dispatch is debounced (see
      -- config below) so rapid edits / chained saves only fire once per
      -- 100ms window.
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },

      -- Per-filetype linter list. Mirrors module-level `linters_by_ft`
      -- which the on-demand mason installer also reads.
      linters_by_ft = linters_by_ft,

      -- Per-linter overrides. Empty for now -- entries here can customize
      -- args, define a custom linter, or set a `condition(ctx)` callback
      -- that decides at runtime whether to run a linter (e.g. only if a
      -- project config file exists in an ancestor directory).
      ---@type table<string, table>
      linters = {},
    },
    config = function(_, opts)
      local lint = require("lint")

      -- Merge opts.linters into nvim-lint's registered linters table. For
      -- existing linters, deep-extend so we can override individual fields
      -- (args, cmd, parser, etc.) without redefining the whole linter.
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
          if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}
            vim.list_extend(lint.linters[name].args, linter.prepend_args)
          end
        else
          lint.linters[name] = linter
        end
      end
      lint.linters_by_ft = opts.linters_by_ft

      -- Debounce wrapper: coalesces rapid event bursts (BufWritePost +
      -- InsertLeave fired in quick succession, etc.) so we run the linter
      -- pass at most once per `ms`-millisecond window. We resolve `unpack`
      -- via `table.unpack or unpack` so this works on both LuaJIT (where
      -- `unpack` is a global) and Lua 5.2+ (where it lives at table.unpack).
      local unpack = table.unpack or unpack ---@diagnostic disable-line: deprecated
      local function debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      -- Smart lint dispatcher. Resolves the linter list for the current
      -- buffer with four extras over plain `lint.try_lint()`:
      --   1. Compound filetypes ("markdown.mdx") are split correctly.
      --   2. linters_by_ft["_"] are fallback linters (run only if nothing
      --      else matched the filetype).
      --   3. linters_by_ft["*"] are global linters (run on every filetype).
      --   4. Per-linter `condition(ctx)` callbacks can disable a linter at
      --      runtime based on the current file/dir context.
      -- Missing linters are flagged via vim.notify so typos in
      -- linters_by_ft surface immediately instead of silently no-op'ing.
      local function try_lint()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)
        names = vim.list_extend({}, names)

        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")

        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN, { title = "nvim-lint" })
          end
          return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("ACHLint", { clear = true }),
        callback = debounce(100, try_lint),
      })

      -- ----------------------------------------------------------------
      -- On-demand installer (same shape as lsp.lua / formatting.lua)
      -- ----------------------------------------------------------------
      local installing = {}

      local function ensure_linter(name)
        if installing[name] then
          return
        end
        local mason_name = linter_to_mason[name]
        if not mason_name then
          return
        end

        local ok, mr = pcall(require, "mason-registry")
        if not ok then
          return
        end

        -- mason-registry is lazy-loaded: on a cold-start nvim the package
        -- index hasn't been fetched yet and has_package() silently returns
        -- false. Wrapping the query in mr.refresh(cb) guarantees cb runs
        -- after the registry is populated (no-op on subsequent calls since
        -- the refresh result is cached).
        mr.refresh(vim.schedule_wrap(function()
          if installing[name] then
            return
          end
          if not mr.has_package(mason_name) then
            return
          end

          local pkg = mr.get_package(mason_name)
          if pkg:is_installed() then
            return
          end

          installing[name] = true

          local function on_done()
            installing[name] = nil
            if pkg:is_installed() then
              vim.notify(
                ("Linter installed: %s"):format(mason_name),
                vim.log.levels.INFO,
                { title = "Lint", icon = icons.lsp.diagnostic }
              )
              -- Re-run lint on currently-open buffers of this filetype so
              -- the freshly-installed linter produces results immediately.
              vim.schedule(function()
                lint.try_lint()
              end)
            else
              vim.notify(
                ("Linter install failed: %s"):format(mason_name),
                vim.log.levels.WARN,
                { title = "Lint", icon = icons.lsp.diagnostic }
              )
            end
          end

          -- Cross-installer race guard. Same mason package can be
          -- targeted by lsp.lua (LSP), formatting.lua (formatter), and
          -- this file (linter). mason asserts on a second pkg:install()
          -- while one is in flight, so attach to the existing handle
          -- instead. See lsp.lua for the canonical explanation.
          if pkg:is_installing() then
            pkg:get_install_handle():if_present(function(handle)
              handle:once("closed", vim.schedule_wrap(on_done))
            end)
            return
          end

          vim.notify(
            ("Installing linter: %s"):format(mason_name),
            vim.log.levels.INFO,
            { title = "Lint", icon = icons.lsp.diagnostic }
          )
          pkg:install():once("closed", vim.schedule_wrap(on_done))
        end))
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHLintInstall", { clear = true }),
        callback = function(args)
          local list = linters_by_ft[args.match]
          if not list then
            return
          end
          for _, name in ipairs(list) do
            ensure_linter(name)
          end
        end,
      })

      -- Cover the buffer that lazy-loaded us.
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
        end
      end
    end,
  },
}
