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
      -- Workaround for nvim-treesitter master vs Neovim 0.12 incompat.
      --
      -- In Neovim 0.12 the `all = false` option to `vim.treesitter.query
      -- .add_directive` was REMOVED. Look at vim/treesitter/query.lua's
      -- M.add_directive: it only processes `force`, and the handler
      -- signature documents `match` as `table mapping capture IDs to a
      -- list of captured nodes` -- always an array. There is zero
      -- handling of `opts.all` anywhere in 0.12's query.lua.
      --
      -- nvim-treesitter master tried to work around the breaking change
      -- in commit 3826d0c4 ("fix(query): explicitly opt-in to legacy
      -- behavior") by passing `{ force = true, all = false }`, but on
      -- 0.12 that opt is silently ignored. So every directive in
      -- query_predicates.lua that does `local node = match[capture_id]`
      -- and then calls a TSNode method (`:range()`, `:type()`, or feeds
      -- it through `vim.treesitter.get_node_text`) crashes -- because
      -- `node` is actually a `TSNode[]` array, not a TSNode.
      --
      -- The visible symptom is the noice toast:
      --   Decoration provider "conceal_line" (ns=nvim.treesitter.highlighter):
      --   ... attempt to call a method 'range' (a nil value)
      -- The "conceal_line" name is the decoration provider that was
      -- running when the crash happened; the actual fault is one of the
      -- nvim-treesitter directives below.
      --
      -- Re-register all three broken directives with array-aware copies
      -- (the `first_node` helper extracts the first TSNode from the
      -- array form, with a fallback for legacy single-node form on
      -- older Neovim). `force = true` replaces the upstream registrations.
      -- `all` is intentionally omitted from opts since it's a no-op on
      -- 0.12 anyway. Remove this block when nvim-treesitter master
      -- catches up to the 0.12 directive contract.
      -- ----------------------------------------------------------------
      do
        local ok_query, query = pcall(require, "vim.treesitter.query")
        if ok_query then
          -- Extract the first TSNode for a capture, handling both the
          -- 0.12+ array form (`TSNode[]`) and the legacy single-node
          -- form so this works on older Neovim too. TSNodes are
          -- userdata, never tables, so the type check is unambiguous.
          local function first_node(match, capture_id)
            local raw = match[capture_id]
            if type(raw) == "table" then return raw[1] end
            return raw
          end

          local non_filetype_aliases = {
            ex  = "elixir",
            pl  = "perl",
            sh  = "bash",
            uxn = "uxntal",
            ts  = "typescript",
          }
          local function resolve_markdown_alias(alias)
            local match = vim.filetype.match({ filename = "a." .. alias })
            return match or non_filetype_aliases[alias] or alias
          end

          local html_script_type_languages = {
            ["importmap"]              = "json",
            ["module"]                 = "javascript",
            ["application/ecmascript"] = "javascript",
            ["text/ecmascript"]        = "javascript",
          }

          -- markdown code fence: ` ```python ` -> injection.language=python
          query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
            local node = first_node(match, pred[2])
            if not node then return end
            local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
            if not ok or not text or text == "" then return end
            metadata["injection.language"] = resolve_markdown_alias(text:lower())
          end, { force = true })

          -- HTML <script type="..."> -> injection.language=<resolved>
          query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
            local node = first_node(match, pred[2])
            if not node then return end
            local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
            if not ok or not text or text == "" then return end
            local configured = html_script_type_languages[text]
            if configured then
              metadata["injection.language"] = configured
            else
              local parts = vim.split(text, "/", {})
              metadata["injection.language"] = parts[#parts]
            end
          end, { force = true })

          -- (#downcase! @capture) -> set capture metadata.text to lowercased text
          query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
            local id = pred[2]
            local node = first_node(match, id)
            if not node then return end
            local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr, { metadata = metadata[id] })
            if not ok then return end
            text = text or ""
            if not metadata[id] then metadata[id] = {} end
            metadata[id].text = string.lower(text)
          end, { force = true })
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
