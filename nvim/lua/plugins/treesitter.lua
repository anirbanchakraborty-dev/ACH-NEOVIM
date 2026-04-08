-- Treesitter: syntax highlighting, indentation, incremental selection, textobjects.
-- Parsers install purely on demand: opening a file of a new filetype triggers
-- an async install of its parser via `auto_install = true`. Nothing is ensured
-- up front -- every parser arrives the moment it is first needed.

local icons = require("config.icons")

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
      -- .add_directive` and `add_predicate` was REMOVED. Look at
      -- vim/treesitter/query.lua's M.add_directive / M.add_predicate:
      -- they only process `force`, and the handler signatures document
      -- `match` as "table mapping capture IDs to a list of captured
      -- nodes" -- always a TSNode[] array. There is zero handling of
      -- `opts.all` anywhere in 0.12's query.lua.
      --
      -- nvim-treesitter master tried to work around the breaking change
      -- in commit 3826d0c4 ("fix(query): explicitly opt-in to legacy
      -- behavior") by passing `{ force = true, all = false }`, but on
      -- 0.12 that opt is silently ignored. So every predicate and
      -- directive in query_predicates.lua that does
      --   `local node = match[capture_id]`
      -- and then calls a TSNode method (`:range()`, `:type()`,
      -- `:parent()`, or feeds it through `vim.treesitter.get_node_text`
      -- or `nvim-treesitter.locals.find_definition`) crashes -- because
      -- `node` is actually the array, not a TSNode.
      --
      -- The visible symptom is the noice toast:
      --   Decoration provider "conceal_line" (ns=nvim.treesitter.highlighter):
      --   ... attempt to call a method 'range' (a nil value)
      -- The "conceal_line" name is the decoration provider that was
      -- running when the crash happened; the actual fault is one of the
      -- nvim-treesitter handlers below.
      --
      -- Re-register every broken handler with an array-aware copy.
      -- `first_node` extracts the first TSNode from the array form (with
      -- a fallback for legacy single-node form on older Neovim).
      -- `force = true` replaces the upstream registrations. `all` is
      -- intentionally omitted from opts since it's a no-op on 0.12 anyway.
      --
      -- Note: `has-ancestor?`, `has-parent?`, and `trim!` were already
      -- removed from upstream nvim-treesitter in commit 9210b9a4 (Oct
      -- 2024) because they're upstreamed to Neovim's built-in handlers,
      -- so they don't need overriding here. Only the handlers still
      -- present in upstream `query_predicates.lua` are listed below.
      --
      -- Remove this block when nvim-treesitter master catches up to the
      -- 0.12 match[] contract.
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

          -- Inline copy of nvim-treesitter's `valid_args` so we can
          -- preserve the original argument-count validation behavior
          -- without reaching into the upstream module-local function.
          local function valid_args(name, pred, count, strict)
            local arg_count = #pred - 1
            if strict then
              if arg_count ~= count then
                vim.notify(
                  string.format("%s must have exactly %d arguments", name, count),
                  vim.log.levels.ERROR,
                  { title = "treesitter" }
                )
                return false
              end
            elseif arg_count < count then
              vim.notify(
                string.format("%s must have at least %d arguments", name, count),
                vim.log.levels.ERROR,
                { title = "treesitter" }
              )
              return false
            end
            return true
          end

          -- Lua 5.1/LuaJIT vs 5.2+ unpack compat (mirrors linting.lua).
          local unpack = table.unpack or unpack ---@diagnostic disable-line: deprecated

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

          -- ── Predicates ──────────────────────────────────────────────

          -- (#nth? @capture n) -> true if @capture is the n-th named child
          -- of its parent. Calls TSNode `:parent()`, `:named_child_count()`,
          -- `:named_child()` -- all crash on the array form.
          query.add_predicate("nth?", function(match, _, _, pred)
            if not valid_args("nth?", pred, 2, true) then return end
            local node = first_node(match, pred[2])
            local n = tonumber(pred[3])
            if node and node:parent() and node:parent():named_child_count() > n then
              return node:parent():named_child(n) == node
            end
            return false
          end, { force = true })

          -- (#is? @capture kind...) -> true if the locals analysis says
          -- the captured node is one of the listed kinds. Reaches into
          -- nvim-treesitter.locals.find_definition which calls TSNode
          -- methods internally; passing the array crashes inside there.
          query.add_predicate("is?", function(match, _, bufnr, pred)
            if not valid_args("is?", pred, 2) then return end
            local node = first_node(match, pred[2])
            local types = { unpack(pred, 3) }
            if not node then return true end
            local ok, locals = pcall(require, "nvim-treesitter.locals")
            if not ok then return false end
            local _, _, kind = locals.find_definition(node, bufnr)
            return vim.tbl_contains(types, kind)
          end, { force = true })

          -- (#kind-eq? @capture type...) -> true if the captured node's
          -- :type() is one of the listed types. `node:type()` crashes
          -- on the array form. Renamed from `has-type?` upstream in
          -- commit a80fe081 to align with Helix.
          query.add_predicate("kind-eq?", function(match, _, _, pred)
            if not valid_args("kind-eq?", pred, 2) then return end
            local node = first_node(match, pred[2])
            local types = { unpack(pred, 3) }
            if not node then return true end
            return vim.tbl_contains(types, node:type())
          end, { force = true })

          -- ── Directives ──────────────────────────────────────────────

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

  -- nvim-treesitter-context: sticky function/class header that pins the
  -- current scope's signature to the top of the buffer when you scroll
  -- past its definition. `mode = "cursor"` means the context follows the
  -- cursor (not the topmost visible line), which is the more useful mode
  -- when navigating with `}`/`{` or `[c`/`]c`. `max_lines = 3` caps the
  -- pinned area so a deeply-nested context doesn't take over the screen.
  -- Toggleable via `<leader>ut` through the snacks toggle pattern.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      mode = "cursor",
      max_lines = 3,
    },
    config = function(_, opts)
      local tsc = require("treesitter-context")
      tsc.setup(opts)
      Snacks.toggle({
        name = "Treesitter Context",
        get = function() return tsc.enabled() end,
        set = function(state)
          if state then tsc.enable() else tsc.disable() end
        end,
      }):map("<leader>ut")
    end,
  },

  -- which-key: icon for the treesitter-context toggle.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "<leader>ut", desc = "Toggle Treesitter Context", icon = { icon = icons.find.treesitter, color = "green" } },
      },
    },
  },
}
