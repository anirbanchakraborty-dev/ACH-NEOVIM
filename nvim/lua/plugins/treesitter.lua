-- Treesitter: syntax highlighting, indentation, incremental selection, textobjects.
-- Parsers install purely on demand: opening a file of a new filetype triggers
-- an async install of its parser via `auto_install = true`. Nothing is ensured
-- up front -- every parser arrives the moment it is first needed.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSInstallInfo", "TSUpdate", "TSUpdateSync", "TSModuleInfo" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      -- Nothing pre-installed. Parsers arrive on demand via auto_install.
      ensure_installed = {},
      auto_install = true,
      sync_install = false,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      indent = {
        enable = true,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-Space>",
          node_incremental  = "<C-Space>",
          scope_incremental = false,
          node_decremental  = "<BS>",
        },
      },

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer",  desc = "Around Function" },
            ["if"] = { query = "@function.inner",  desc = "Inside Function" },
            ["ac"] = { query = "@class.outer",     desc = "Around Class" },
            ["ic"] = { query = "@class.inner",     desc = "Inside Class" },
            ["aa"] = { query = "@parameter.outer", desc = "Around Parameter" },
            ["ia"] = { query = "@parameter.inner", desc = "Inside Parameter" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = { query = "@function.outer",  desc = "Next Function" },
            ["]c"] = { query = "@class.outer",     desc = "Next Class" },
            ["]a"] = { query = "@parameter.inner", desc = "Next Parameter" },
          },
          goto_next_end = {
            ["]F"] = { query = "@function.outer",  desc = "Next Function End" },
            ["]C"] = { query = "@class.outer",     desc = "Next Class End" },
            ["]A"] = { query = "@parameter.inner", desc = "Next Parameter End" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer",  desc = "Prev Function" },
            ["[c"] = { query = "@class.outer",     desc = "Prev Class" },
            ["[a"] = { query = "@parameter.inner", desc = "Prev Parameter" },
          },
          goto_previous_end = {
            ["[F"] = { query = "@function.outer",  desc = "Prev Function End" },
            ["[C"] = { query = "@class.outer",     desc = "Prev Class End" },
            ["[A"] = { query = "@parameter.inner", desc = "Prev Parameter End" },
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)

      -- ----------------------------------------------------------------
      -- Workaround for nvim-treesitter master commit 19ac9e8b (2024-05-17)
      -- which added `:lower()` to the result of `vim.treesitter.get_node_text`
      -- in the `set-lang-from-info-string!` directive without guarding
      -- against `get_node_text` returning nil.
      --
      -- When a markdown code fence has an empty info string (` ``` ` with
      -- no language tag), `get_node_text` returns nil and `:lower()` then
      -- crashes the treesitter highlighter decoration provider with an
      -- "attempt to index a nil value" error. The error surfaces in noice
      -- as `Decoration provider "conceal_line" (ns=nvim.treesitter.highlighter)`
      -- because the conceal_line decoration provider is what was running
      -- when the crash happened.
      --
      -- Re-register the directive with a nil-guarded copy. `force = true`
      -- ensures our version replaces the broken one. The aliases table
      -- and the resolver mirror nvim-treesitter's `query_predicates.lua`
      -- verbatim (they're module-local in the upstream file). Remove this
      -- block when upstream lands a fix and the file no longer crashes.
      -- ----------------------------------------------------------------
      do
        local ok_query, query = pcall(require, "vim.treesitter.query")
        if ok_query then
          local non_filetype_aliases = {
            ex  = "elixir",
            pl  = "perl",
            sh  = "bash",
            uxn = "uxntal",
            ts  = "typescript",
          }
          local function resolve(alias)
            local match = vim.filetype.match({ filename = "a." .. alias })
            return match or non_filetype_aliases[alias] or alias
          end
          query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
            local capture_id = pred[2]
            local node = match[capture_id]
            if not node then return end
            local text = vim.treesitter.get_node_text(node, bufnr)
            if not text or text == "" then return end
            metadata["injection.language"] = resolve(text:lower())
          end, { force = true, all = false })
        end
      end

      -- Friendly toast notifications when auto_install kicks in for a new filetype.
      -- Fires a "Installing parser: X" toast, then polls until the parser becomes
      -- available and fires a "Parser installed: X" toast (or a timeout warning).
      local parsers        = require("nvim-treesitter.parsers")
      local parser_configs = parsers.get_parser_configs()
      local icons          = require("config.icons")
      local in_progress    = {}

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHTreesitterNotify", { clear = true }),
        callback = function(args)
          local lang = parsers.ft_to_lang(args.match)
          if not lang or not parser_configs[lang] then return end
          if parsers.has_parser(lang) then return end
          if in_progress[lang] then return end
          in_progress[lang] = true

          vim.notify(
            ("Installing parser: %s"):format(lang),
            vim.log.levels.INFO,
            { title = "Treesitter", icon = icons.plugins.treesitter }
          )

          local attempts = 0
          local timer = vim.uv.new_timer()
          timer:start(500, 500, vim.schedule_wrap(function()
            attempts = attempts + 1
            if parsers.has_parser(lang) then
              timer:stop(); timer:close()
              in_progress[lang] = nil
              vim.notify(
                ("Parser installed: %s"):format(lang),
                vim.log.levels.INFO,
                { title = "Treesitter", icon = icons.plugins.treesitter }
              )
            elseif attempts > 120 then -- ~60s
              timer:stop(); timer:close()
              in_progress[lang] = nil
              vim.notify(
                ("Parser install timed out: %s"):format(lang),
                vim.log.levels.WARN,
                { title = "Treesitter", icon = icons.plugins.treesitter }
              )
            end
          end))
        end,
      })
    end,
  },
}
