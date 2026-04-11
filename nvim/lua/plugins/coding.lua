-- Coding: the IDE interaction layer. Completion + signature help + snippets
-- via blink.cmp, autopairs via mini.pairs, surround operator via mini.surround,
-- richer a/i text objects via mini.ai, and auto-closing HTML/JSX tags via
-- nvim-ts-autotag.
--
-- blink.cmp is listed as a dependency of nvim-lspconfig in lsp.lua so it
-- loads before the LSP config runs and its get_lsp_capabilities() can be
-- merged into vim.lsp.config("*"). That way every language server learns
-- about snippet + resolve support from the get-go.

local icons = require("config.icons")

return {
  -- blink.cmp: Rust-powered completion engine. Ships its own snippet engine
  -- that consumes friendly-snippets directly (no LuaSnip needed).
  {
    "saghen/blink.cmp",
    version = "*", -- pull the pre-built fuzzy matcher binary
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    event = "InsertEnter",
    -- Let other plugin specs append to the source lists without overwriting
    -- them (mirrors the which-key `opts_extend = { "spec" }` pattern). A
    -- future plugin file can add an entry to sources.default or register a
    -- custom provider in sources.providers and lazy.nvim will deep-merge it
    -- onto the table below instead of clobbering.
    opts_extend = { "sources.default", "sources.providers" },
    opts = {
      -- "enter" preset: <CR> accepts the current selection (falls back to
      -- inserting a newline when no menu is open). Tab/Shift-Tab navigate
      -- snippet placeholders.
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        -- Vim-traditional accept binding alongside <CR>. Lets you confirm a
        -- completion without leaving the home row when <CR> would otherwise
        -- insert a literal newline (e.g. multi-line popup contexts).
        ["<C-y>"] = { "select_and_accept" },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        -- Replace blink's built-in completion-kind glyphs with the central
        -- M.kinds table from icons.lua so the popup matches the rest of the
        -- UI (lualine, fzf-lua, which-key, etc).
        kind_icons = icons.kinds,
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        -- lazydev only fires on Lua buffers via per_filetype instead of
        -- living in the global default list. `inherit_defaults = true` keeps
        -- lsp/path/snippets/buffer active alongside lazydev on Lua files,
        -- so the only behavior change is that lazydev is silent on every
        -- non-Lua filetype (where its integration would otherwise no-op
        -- needlessly on every keystroke).
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
          org = { inherit_defaults = true, "orgmode" },
        },
        providers = {
          -- lazydev.nvim feeds Neovim runtime / plugin globals into completion
          -- when editing Lua config files. score_offset boosts these above
          -- generic LSP results so vim.api / Snacks.* surface near the top.
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          orgmode = {
            name = "Orgmode",
            module = "orgmode.org.autocompletion.blink",
            score_offset = 100,
          },
        },
      },

      -- Inline signature help as you type function arguments.
      signature = {
        enabled = true,
        window = {
          border = "rounded",
          -- See documentation.treesitter_highlighting below for the rationale.
          treesitter_highlighting = false,
        },
      },

      completion = {
        -- Insert () (and placeholders) after accepting a function.
        accept = {
          auto_brackets = { enabled = true },
        },

        -- Doc popup auto-opens after a short delay on the highlighted item.
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
          -- blink.cmp <= v1.10.2 invokes vim.treesitter.get_range from
          -- lib/window/docs.lua during markdown rendering, which calls a
          -- node API that was changed in Neovim 0.12.1 and throws
          -- "attempt to call a nil value" on every popup render. Disabling
          -- treesitter_highlighting on docs + signature keeps the popups
          -- working without the syntax-highlighted code blocks. Re-enable
          -- (along with menu.draw.treesitter below) once v1.10.3 ships
          -- with the fix (tracked in memory: project_pending_blink_cmp_1_10_3).
          treesitter_highlighting = false,
        },

        -- VSCode-style inline preview of the current selection.
        ghost_text = { enabled = true },

        list = {
          selection = { preselect = true, auto_insert = false },
        },

        menu = {
          border = "rounded",
          winblend = 0,
          -- Same v1.10.2 + Neovim 0.12.1 incompat as documentation above.
          -- draw = { treesitter = { "lsp" } },
        },
      },
    },
  },

  -- mini.pairs: autopairs. ( -> (), [ -> [], " -> "", etc. Smart about
  -- context so it doesn't double up on existing closers, doesn't autopair
  -- inside string nodes, and handles markdown code fences specially.
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- Skip autopair when the next character is one of these (alphanumerics,
      -- existing quotes/brackets, etc) so we don't double up on identifiers.
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- Skip autopair when the cursor is inside a string treesitter node
      -- (e.g. don't insert a `)` when typing `(` inside a quoted string).
      skip_ts = { "string" },
      -- Skip when there are already more closers than openers on the line.
      skip_unbalanced = true,
      -- Better handling for markdown code fences (```).
      markdown = true,
    },
  },

  -- mini.surround: add / delete / change surroundings under the "gs" prefix.
  -- Left unprefixed (the default "sa/sd/sr/..." conflict with useful s
  -- motions that flash-style plugins rely on), so gs here is a deliberate
  -- mapping choice for clarity. Lazy-loaded on the gs* keys themselves so
  -- the plugin doesn't touch startup unless you actually invoke a surround
  -- operator -- previously this loaded on BufReadPost, which fired on every
  -- single buffer read regardless of whether you used the keys.
  {
    "nvim-mini/mini.surround",
    keys = {
      { "gsa", desc = "Add Surrounding", mode = { "n", "x" } },
      { "gsd", desc = "Delete Surrounding" },
      { "gsf", desc = "Find Right Surrounding" },
      { "gsF", desc = "Find Left Surrounding" },
      { "gsh", desc = "Highlight Surrounding" },
      { "gsr", desc = "Replace Surrounding" },
      { "gsn", desc = "Update n_lines" },
    },
    opts = {
      mappings = {
        add = "gsa", -- Add surrounding
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (right)
        find_left = "gsF", -- Find surrounding (left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update n_lines
      },
    },
  },

  -- mini.ai: richer a/i text objects. The custom_textobjects table layers
  -- treesitter-powered targets on top of mini.ai's defaults so daf deletes a
  -- whole function, cic changes inside a class, vao selects an if/loop block,
  -- etc. Tag/digit/usage are regex-based fallbacks that work even without
  -- treesitter parsers loaded.
  --
  -- e / g / U are borrowed from LazyVim's coding.lua mini.ai block:
  --   * e: CamelCase / snake_case word part. `viw` selects the whole
  --     identifier; `vie` only selects the chunk under the cursor (so
  --     `fooBarBaz` becomes 3 navigable units, `snake_case_thing` becomes
  --     3 navigable units). Useful for renaming a single component of a
  --     compound identifier without touching the rest.
  --   * g: entire buffer. `vag` selects every line including trailing
  --     blanks; `vig` strips leading/trailing blank lines. Inlined from
  --     LazyVim's `ai_buffer` helper which is itself a copy of
  --     `MiniExtra.gen_ai_spec.buffer` -- we don't pull in mini.extra just
  --     for one helper, so the implementation lives next to its consumer.
  --   * U: function call WITHOUT dotted access. The default `u` (set
  --     above) accepts any callable including `foo.bar.baz()`; `U` is
  --     restricted to bare identifiers like `foo()`. Useful for refactors
  --     where you want to rewrite a top-level call without grabbing the
  --     surrounding method chain.
  {
    "nvim-mini/mini.ai",
    event = "BufReadPost",
    opts = function()
      local ai = require("mini.ai")

      -- Inlined from LazyVim's lazyvim.util.mini.ai_buffer (which is
      -- itself copied from MiniExtra.gen_ai_spec.buffer). We keep the
      -- inline copy because pulling mini.extra in just for this single
      -- spec would add a startup-path module for one ~15-line helper.
      local function ai_buffer(ai_type)
        local start_line, end_line = 1, vim.fn.line("$")
        if ai_type == "i" then
          local first_nonblank = vim.fn.nextnonblank(start_line)
          local last_nonblank = vim.fn.prevnonblank(end_line)
          if first_nonblank == 0 or last_nonblank == 0 then
            return { from = { line = start_line, col = 1 } }
          end
          start_line, end_line = first_nonblank, last_nonblank
        end
        local to_col = math.max(vim.fn.getline(end_line):len(), 1)
        return {
          from = { line = start_line, col = 1 },
          to = { line = end_line, col = to_col },
        }
      end

      return {
        n_lines = 500,
        custom_textobjects = {
          -- o: cOde block (conditionals + loops + plain blocks)
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          -- f: Function definition
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- c: Class definition
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          -- t: HTML/JSX Tag (regex-based, parser-free)
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          -- d: Digits run
          d = { "%f[%d]%d+" },
          -- e: CamelCase / snake_case word chunk
          e = {
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          -- g: Entire buffer
          g = ai_buffer,
          -- u: function call ("Usage"), accepts dotted callees (foo.bar.baz())
          u = ai.gen_spec.function_call(),
          -- U: function call without dot in the name (foo() only)
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
        },
      }
    end,
  },

  -- nvim-ts-autotag: auto-close and auto-rename HTML / JSX / Vue / Svelte
  -- tags using treesitter, so typing <div> inserts </div> automatically and
  -- renaming the opener also renames the closer.
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },

  -- ts-comments.nvim: treesitter-aware commenting on top of Neovim 0.10+'s
  -- built-in `gc` operator. Picks the right commentstring for embedded
  -- languages (JSX inside JS, CSS inside HTML, code fences in markdown, etc.)
  -- so the gco/gcO keymaps in keymaps.lua produce the right comment syntax.
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- dial.nvim: supercharged <C-a> / <C-x>. Vim's native increment/
  -- decrement only knows numbers; dial teaches it booleans (true/false,
  -- True/False), dates (2026-04-07 -> 2026-04-08), hex colors, weekday
  -- names, month names, ordinal numbers, logical operators (&& / ||,
  -- and / or), markdown checkboxes ([ ] / [x]), markdown headers, semver
  -- versions, language-specific things like let/const in TS, etc.
  --
  -- The dial helper at the top of the keys block dispatches to the
  -- right augend group based on the current filetype, falling back to
  -- the "default" group if none matches. The config function deep-merges
  -- the default augends into every per-language group so the language
  -- groups are additive, not overrides.
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "<C-a>",
        function()
          local mode = vim.fn.mode(true)
          local is_visual = mode == "v" or mode == "V" or mode == "\22"
          local fn = "inc_" .. (is_visual and "visual" or "normal")
          local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
          return require("dial.map")[fn](group)
        end,
        expr = true,
        mode = { "n", "v" },
        desc = "Increment",
      },
      {
        "<C-x>",
        function()
          local mode = vim.fn.mode(true)
          local is_visual = mode == "v" or mode == "V" or mode == "\22"
          local fn = "dec_" .. (is_visual and "visual" or "normal")
          local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
          return require("dial.map")[fn](group)
        end,
        expr = true,
        mode = { "n", "v" },
        desc = "Decrement",
      },
    },
    opts = function()
      local augend = require("dial.augend")
      return {
        dials_by_ft = {
          css = "css",
          scss = "css",
          sass = "css",
          javascript = "typescript",
          javascriptreact = "typescript",
          typescript = "typescript",
          typescriptreact = "typescript",
          json = "json",
          lua = "lua",
          markdown = "markdown",
          python = "python",
        },
        groups = {
          default = {
            augend.integer.alias.decimal, -- 0, 1, 2, 3, ...
            augend.integer.alias.decimal_int, -- includes negatives
            augend.integer.alias.hex, -- 0x01, 0x1a1f, ...
            augend.date.alias["%Y-%m-%d"], -- ISO date (matches the project's date format)
            augend.date.alias["%Y/%m/%d"],
            augend.constant.alias.en_weekday, -- Mon, Tue, ..., Sun
            augend.constant.alias.en_weekday_full,
            augend.constant.alias.bool, -- true / false
            augend.constant.alias.Bool, -- True / False
            augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
          },
          typescript = {
            augend.constant.new({ elements = { "let", "const" } }),
          },
          css = {
            augend.hexcolor.new({ case = "lower" }),
            augend.hexcolor.new({ case = "upper" }),
          },
          markdown = {
            augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
            augend.misc.alias.markdown_header,
          },
          json = {
            augend.semver.alias.semver,
          },
          lua = {
            augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
          },
          python = {
            augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
          },
        },
      }
    end,
    config = function(_, opts)
      -- Extend each language group with the defaults so language augends
      -- are additive (e.g. typescript still gets numbers + dates + bools).
      for name, group in pairs(opts.groups) do
        if name ~= "default" then
          vim.list_extend(group, opts.groups.default)
        end
      end
      require("dial.config").augends:register_group(opts.groups)
      vim.g.dials_by_ft = opts.dials_by_ft
    end,
  },

  -- refactoring.nvim: real refactoring operations (extract function,
  -- extract variable, inline variable, extract block, extract to file)
  -- powered by treesitter. Visual-select code, hit <leader>rE, type a
  -- name, the plugin inserts a new function definition above and
  -- replaces the selection with a call. Supported langs: Python, JS/TS,
  -- Lua, Go, C/C++, Java, Ruby, PHP.
  --
  -- The pick keymap (<leader>rs) routes through fzf-lua so refactor
  -- selection uses the same picker as the rest of the config -- no
  -- vim.ui.select fallback (which would land in snacks.input and look
  -- inconsistent next to the rest of the fzf-lua-driven UI).
  --
  -- The <leader>r* group was reserved for "Run/Build" in CLAUDE.md but
  -- never wired up; reassigned to refactoring here. Build/run/test now
  -- live under <leader>o (overseer) in util.lua.
  {
    "ThePrimeagen/refactoring.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      prompt_func_return_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      printf_statements = {},
      print_var_statements = {},
      show_success_message = true,
    },
    keys = {
      {
        "<leader>rs",
        function()
          local refactoring = require("refactoring")
          local fzf = require("fzf-lua")
          fzf.fzf_exec(refactoring.get_refactors(), {
            fzf_opts = {},
            fzf_colors = true,
            actions = {
              ["default"] = function(selected)
                refactoring.refactor(selected[1])
              end,
            },
          })
        end,
        mode = { "n", "x" },
        desc = "Refactor (pick)",
      },
      {
        "<leader>rE",
        function()
          return require("refactoring").refactor("Extract Function")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Extract Function",
      },
      {
        "<leader>rF",
        function()
          return require("refactoring").refactor("Extract Function To File")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Extract Function To File",
      },
      {
        "<leader>rv",
        function()
          return require("refactoring").refactor("Extract Variable")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Extract Variable",
      },
      {
        "<leader>ri",
        function()
          return require("refactoring").refactor("Inline Variable")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Inline Variable",
      },
      {
        "<leader>rb",
        function()
          return require("refactoring").refactor("Extract Block")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Extract Block",
      },
      {
        "<leader>rB",
        function()
          return require("refactoring").refactor("Extract Block To File")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Extract Block To File",
      },
      {
        "<leader>rp",
        function()
          require("refactoring").debug.print_var({ normal = true })
        end,
        mode = { "n", "x" },
        desc = "Debug Print Variable",
      },
      {
        "<leader>rP",
        function()
          require("refactoring").debug.printf({ below = false })
        end,
        desc = "Debug Print",
      },
      {
        "<leader>rc",
        function()
          require("refactoring").debug.cleanup({})
        end,
        desc = "Debug Cleanup",
      },
    },
  },

  -- yanky.nvim: yank ring + indented paste. Every yank is recorded so
  -- you can browse history with <leader>p (native YankyRingHistory popup
  -- since the user is on fzf-lua and snacks.picker isn't enabled). After
  -- a paste, [y / ]y cycle the just-pasted text backwards/forwards
  -- through the ring -- the killer feature, no re-yanking needed when
  -- you paste the wrong thing. ]p / [p give indent-matched paste, > p
  -- and < p paste then shift right/left.
  --
  -- All operators (y / p / P / gp / gP) are remapped through <Plug>
  -- bindings so yanky's tracker sees every yank/paste; behavior is
  -- transparent to the user beyond the ring being populated.
  {
    "gbprod/yanky.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- Pull external clipboard contents into the ring so anything
      -- you Cmd-C in another app becomes browsable via <leader>p.
      -- Skip on SSH where the clipboard story is OSC 52 (matches the
      -- options.lua clipboard guard).
      system_clipboard = {
        sync_with_ring = not vim.env.SSH_CONNECTION,
      },
      -- Don't double-flash on yank: autocmds.lua's HighlightYank group
      -- already calls vim.hl.on_yank() on TextYankPost for every yank,
      -- regardless of whether yanky is loaded. Letting yanky also
      -- highlight would stack two flashes on the same event. The
      -- existing autocmd uses IncSearch (already themed by tokyonight)
      -- and is independent of yanky's lazy-load timing.
      highlight = { on_yank = false, on_put = false },
    },
    keys = {
      { "<leader>p", "<cmd>YankyRingHistory<cr>", mode = { "n", "x" }, desc = "Yank History" },

      -- Core operators (Plug remaps that route through yanky's ring tracker)
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put After Cursor" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Before Cursor" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put After Selection" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Before Selection" },

      -- Cycle through yank history. Only meaningful immediately after a paste.
      { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
      { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },

      -- Indented put (linewise). Overrides vim's native [p / ]p with
      -- yanky's more reliable indent-matching implementation.
      { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After (Linewise)" },
      { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before (Linewise)" },
      { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After (Linewise)" },
      { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before (Linewise)" },

      -- Put then shift indent. Useful for moving pasted blocks left/right.
      { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
      { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
      { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
      { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },

      -- Put through a filter (yanky's filter API). Niche but harmless.
      { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying Filter" },
      { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Applying Filter" },
    },
  },

  -- neogen: treesitter-driven docstring/annotation generator. Press
  -- <leader>cn on a function/class/type and it inserts a templated comment
  -- block above with navigable tabstops for the description / @param /
  -- @return fields. Supports EmmyLua (Lua), JSDoc (JS/TS), Google/Numpy/
  -- Sphinx (Python), Godoc (Go), rustdoc (Rust), Doxygen (C/C++), and
  -- more -- the language matches whichever treesitter parser is loaded.
  --
  -- snippet_engine = "nvim" routes the templated insertion through Neovim
  -- 0.10+'s native vim.snippet API rather than LuaSnip / mini.snippets /
  -- etc. Tabstop navigation for vim.snippet sessions lives on <C-l>/<C-h>
  -- in keymaps.lua because blink.cmp's <Tab> chain only sees blink-inserted
  -- snippets and is invisible to vim.snippet sessions.
  {
    "danymat/neogen",
    cmd = "Neogen",
    keys = {
      {
        "<leader>cn",
        function()
          require("neogen").generate()
        end,
        desc = "Generate Annotations",
      },
    },
    opts = {
      snippet_engine = "nvim",
    },
  },

  -- lazydev.nvim: teaches lua_ls about the Neovim runtime API plus selected
  -- plugin globals (Snacks, lazy.nvim, vim.uv) so editing this config gets
  -- full completion + type-checking and the "Undefined global vim" warnings
  -- go away. Loads only on Lua filetypes so it has zero startup cost
  -- elsewhere. Pairs with the blink.cmp `lazydev` source above.
  --
  -- The nvim-lspconfig library entry is the LazyVim trick for getting
  -- typed completion on `lspconfig.settings` references when authoring
  -- this very file. With it, typing
  -- `settings = { Lua = { ... } }` in lsp.lua surfaces the full schema
  -- (every legal `settings.<server>.*` key with hover docs) sourced from
  -- nvim-lspconfig's bundled metadata. Triggers only on buffers that
  -- mention the `lspconfig.settings` word so it stays cheap on every
  -- other Lua file in the config.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "Lazy" } },
        { path = "nvim-lspconfig", words = { "lspconfig.settings" } },
      },
    },
  },

  -- which-key: announce the surround group under "gs" plus per-binding
  -- icons + descriptions so the popup surfaces every gsa/gsd/gsf/gsF/
  -- gsh/gsr/gsn entry.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Group
        { "gs", group = "Surround", icon = { icon = icons.ui.code, color = "cyan" } },

        -- Individual bindings
        {
          "gsa",
          desc = "Add Surrounding",
          mode = { "n", "x" },
          icon = { icon = icons.ui.pencil, color = "green" },
        },
        {
          "gsd",
          desc = "Delete Surrounding",
          icon = { icon = icons.ui.trash, color = "red" },
        },
        {
          "gsf",
          desc = "Find Right Surrounding",
          icon = { icon = icons.ui.search, color = "cyan" },
        },
        {
          "gsF",
          desc = "Find Left Surrounding",
          icon = { icon = icons.ui.search, color = "cyan" },
        },
        {
          "gsh",
          desc = "Highlight Surrounding",
          icon = { icon = icons.ui.eye, color = "yellow" },
        },
        {
          "gsr",
          desc = "Replace Surrounding",
          icon = { icon = icons.ui.replace, color = "orange" },
        },
        {
          "gsn",
          desc = "Update n_lines",
          icon = { icon = icons.ui.refresh, color = "blue" },
        },

        -- Neogen
        { "<leader>cn", desc = "Generate Annotations", icon = { icon = icons.lsp.format, color = "green" } },

        -- Yanky (only the discoverable keys -- y / p / P / gp / gP are
        -- universal vim and don't need which-key labels; the indented
        -- and shift-paste variants are similarly muscle-memory-driven).
        {
          "<leader>p",
          desc = "Yank History",
          mode = { "n", "x" },
          icon = { icon = icons.ui.clipboard, color = "yellow" },
        },
        {
          "[y",
          desc = "Cycle Forward Through Yank History",
          icon = { icon = icons.misc.arrow_left, color = "yellow" },
        },
        {
          "]y",
          desc = "Cycle Backward Through Yank History",
          icon = { icon = icons.misc.arrow_right, color = "yellow" },
        },

        -- dial.nvim (top-level <C-a>/<C-x> are vim defaults; only
        -- registering descs so which-key surfaces them on the cheatsheet).
        { "<C-a>", desc = "Increment", mode = { "n", "v" }, icon = { icon = icons.ui.zoom_in, color = "green" } },
        { "<C-x>", desc = "Decrement", mode = { "n", "v" }, icon = { icon = icons.ui.zoom_out, color = "red" } },

        -- Refactoring group (<leader>r). Repurposed from CLAUDE.md's
        -- old "Run/Build" placeholder; build/run/test now live under
        -- <leader>o (overseer) in util.lua.
        { "<leader>r", group = "Refactor", icon = { icon = icons.ui.wand, color = "purple" } },
        {
          "<leader>rs",
          desc = "Refactor (pick)",
          mode = { "n", "x" },
          icon = { icon = icons.ui.menu, color = "purple" },
        },
        {
          "<leader>rE",
          desc = "Extract Function",
          mode = { "n", "x" },
          icon = { icon = icons.kinds.Function, color = "blue" },
        },
        {
          "<leader>rF",
          desc = "Extract Function To File",
          mode = { "n", "x" },
          icon = { icon = icons.kinds.Function, color = "blue" },
        },
        {
          "<leader>rv",
          desc = "Extract Variable",
          mode = { "n", "x" },
          icon = { icon = icons.kinds.Variable, color = "cyan" },
        },
        {
          "<leader>ri",
          desc = "Inline Variable",
          mode = { "n", "x" },
          icon = { icon = icons.kinds.Variable, color = "orange" },
        },
        {
          "<leader>rb",
          desc = "Extract Block",
          mode = { "n", "x" },
          icon = { icon = icons.ui.code, color = "yellow" },
        },
        {
          "<leader>rB",
          desc = "Extract Block To File",
          mode = { "n", "x" },
          icon = { icon = icons.ui.code, color = "yellow" },
        },
        {
          "<leader>rp",
          desc = "Debug Print Variable",
          mode = { "n", "x" },
          icon = { icon = icons.ui.bug, color = "red" },
        },
        {
          "<leader>rP",
          desc = "Debug Print",
          icon = { icon = icons.ui.bug, color = "red" },
        },
        {
          "<leader>rc",
          desc = "Debug Cleanup",
          icon = { icon = icons.ui.trash, color = "grey" },
        },
      },
    },
  },
}
