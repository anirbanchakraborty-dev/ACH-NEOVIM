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
