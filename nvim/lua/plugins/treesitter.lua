-- Treesitter on the `main` branch.
--
-- nvim-treesitter's main branch is a complete rewrite that delegates every
-- runtime feature (highlighting, folds, incremental selection, etc.) to
-- Neovim 0.12+'s built-in treesitter API. The plugin's job is now limited to:
--
--   1. Maintaining the parser table (name -> URL + revision) shipped in
--      `lua/nvim-treesitter/parsers.lua`.
--   2. Installing / updating / uninstalling parsers via an async API
--      (`require("nvim-treesitter").install({...})`).
--   3. Providing the indent expression (`require("nvim-treesitter").indentexpr()`).
--   4. Shipping bundled queries (highlights/injections/folds/locals) under
--      `queries/<lang>/` on the runtimepath.
--
-- Highlighting, folds, incremental selection, and textobjects are NOT
-- enabled by the plugin. We wire them ourselves:
--
--   * Highlighting + folds: handled by autocmds.lua's `TreesitterFolds` group
--     which calls `vim.treesitter.start(buf)` on every FileType event. That
--     autocmd is parser-aware (no-op if no parser installed) so it gracefully
--     handles cold starts.
--   * Indentation: enabled per-buffer in this file's FileType autocmd by
--     setting `vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
--     Marked experimental in the upstream README -- if a parser ships buggy
--     indent rules and you'd rather fall back to the global `indent`
--     foldmethod, drop this line and re-source the file.
--   * Incremental selection: replaced by a small node-stack helper at the
--     bottom of this file, bound to `<C-Space>` and `<BS>` to mirror the
--     master branch's `init_selection` / `node_decremental` UX exactly.
--
-- IMPORTANT: the main branch DOES NOT support lazy-loading per its README.
-- The plugin spec is `lazy = false` for that reason. Startup cost is small
-- because the rewrite is much leaner than master (no opts processing, no
-- module configuration, no per-language module dispatch).
--
-- The ~150-line directive override block that lived here on master is GONE.
-- Master shipped query files written for the pre-0.12 single-node match
-- contract; main ships queries written for the 0.12+ array contract, so
-- there's nothing to patch. If you ever see a "attempt to call a method
-- 'range' (a nil value)" toast again, it means a query file regressed --
-- file an upstream issue, don't re-add the override.

local icons = require("config.icons")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- Lazy-loading is unsupported on main; the plugin must be on the
    -- runtimepath before any FileType event so the bundled queries are
    -- visible to vim.treesitter.start.
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- Default install_dir (~/.local/share/nvim/site). Calling setup
      -- with an empty table is allowed and is what the upstream
      -- README recommends for the common case.
      require("nvim-treesitter").setup({})

      -- ----------------------------------------------------------------
      -- Defensive wrapper around vim.treesitter.start().
      --
      -- Neovim's runtime ftplugin/markdown.lua (and a few others) calls
      -- `vim.treesitter.start()` unconditionally on its very first line,
      -- with no pcall and no "does the parser exist" guard. On a fresh
      -- install, when the user opens their first markdown file before
      -- the on-demand parser installer below has had time to compile
      -- `markdown.so`, this raises:
      --
      --     E5113: Parser could not be created for buffer N and language "markdown"
      --
      -- from assert(get_parser(...)) at runtime/lua/vim/treesitter.lua.
      -- The error fires twice in the first-open window: once when
      -- ftplugin/markdown.lua runs for real, and once when the LSP
      -- on-demand installer in lsp.lua re-fires FileType after mason
      -- finishes installing marksman.
      --
      -- This wrapper swallows ONLY the specific "Parser could not be
      -- created" message, which is the benign "async install hasn't
      -- finished yet" case. Any other error (bad query, wrong ABI,
      -- corrupted parser, etc.) still propagates. When the install
      -- autocmd below finishes and re-fires FileType, vim.treesitter.start
      -- is called again on the now-ready parser and highlighting kicks
      -- in normally.
      --
      -- This is a config-side workaround, not a monkey-patch of the
      -- runtime file -- remove the wrapper when upstream fixes the
      -- runtime ftplugin to guard its own start() call.
      do
        local original_start = vim.treesitter.start
        vim.treesitter.start = function(bufnr, lang)
          local ok, err = pcall(original_start, bufnr, lang)
          if not ok then
            local msg = tostring(err or "")
            if not msg:find("Parser could not be created", 1, true) then
              error(err, 2)
            end
          end
        end
      end

      -- ----------------------------------------------------------------
      -- On-demand parser install.
      --
      -- Master branch had `auto_install = true`. On main we wire the
      -- equivalent ourselves: a FileType autocmd that consults the
      -- installed-parsers set, fires the async installer for any
      -- missing parser, and on completion enables treesitter for
      -- every loaded buffer that matches.
      -- ----------------------------------------------------------------

      -- Cache the installed-parsers set to avoid re-scanning the
      -- install directory on every FileType event. Refreshed after
      -- each successful install.
      local function refresh_installed_set()
        local set = {}
        local list = require("nvim-treesitter").get_installed("parsers") or {}
        for _, lang in ipairs(list) do
          set[lang] = true
        end
        return set
      end
      local installed = refresh_installed_set()

      -- Build the available-parsers set once. Used to bail out for
      -- filetypes that nvim-treesitter has no recipe for (e.g.
      -- pure-vim filetypes like `qf` or `help` -- although `help` is
      -- aliased to `vimdoc` by Neovim core).
      local available = {}
      for _, lang in ipairs(require("nvim-treesitter").get_available()) do
        available[lang] = true
      end

      local in_progress = {} ---@type table<string, boolean>

      -- Enable treesitter features for a single buffer. Idempotent;
      -- safe to call repeatedly. Sets indentexpr (the experimental
      -- treesitter indent on main) in addition to whatever the
      -- TreesitterFolds autocmd in autocmds.lua already does for
      -- highlight + folds.
      local function enable_for_buffer(bufnr, lang)
        if not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end
        pcall(vim.treesitter.start, bufnr, lang)
        vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      -- After install, enable for every loaded buffer whose
      -- filetype maps to the just-installed lang. Re-fires FileType
      -- on those buffers so the autocmds.lua TreesitterFolds group
      -- (which would have no-op'd before the install) gets a second
      -- chance to wire up foldexpr.
      local function enable_for_lang(lang)
        vim.schedule(function()
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(b) then
              local ft = vim.bo[b].filetype
              if ft ~= "" and (vim.treesitter.language.get_lang(ft) or ft) == lang then
                enable_for_buffer(b, lang)
                vim.api.nvim_exec_autocmds("FileType", { buffer = b })
              end
            end
          end
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ACHTreesitterInstall", { clear = true }),
        callback = function(args)
          local ft = args.match
          if ft == "" then
            return
          end
          local lang = vim.treesitter.language.get_lang(ft) or ft

          -- Filetype has no nvim-treesitter parser recipe -- nothing to do.
          if not available[lang] then
            return
          end

          -- Parser already installed: just make sure this buffer
          -- has indentexpr wired (treesitter.start is the
          -- TreesitterFolds autocmd's job).
          if installed[lang] then
            enable_for_buffer(args.buf, lang)
            return
          end

          -- Async install in flight already; the on-complete
          -- callback will catch this buffer.
          if in_progress[lang] then
            return
          end
          in_progress[lang] = true

          vim.notify(
            ("Installing parser: %s"):format(lang),
            vim.log.levels.INFO,
            { title = "Treesitter", icon = icons.plugins.treesitter }
          )

          -- nvim-treesitter's install API is a TaskFun (vendored
          -- async wrapper). Calling it returns a Task; Task:await
          -- takes a plain callback and does NOT require an async
          -- coroutine context, which is what we want here.
          local task = require("nvim-treesitter").install({ lang })
          task:await(function(err)
            vim.schedule(function()
              in_progress[lang] = nil
              installed = refresh_installed_set()
              if not err and installed[lang] then
                vim.notify(
                  ("Parser installed: %s"):format(lang),
                  vim.log.levels.INFO,
                  { title = "Treesitter", icon = icons.plugins.treesitter }
                )
                enable_for_lang(lang)
              else
                vim.notify(
                  ("Parser install failed: %s"):format(lang),
                  vim.log.levels.WARN,
                  { title = "Treesitter", icon = icons.plugins.treesitter }
                )
              end
            end)
          end)
        end,
      })

      -- Re-fire FileType for buffers that were already loaded before
      -- this autocmd existed (the buffer that triggered plugin load,
      -- plus anything `argv` brought in). Otherwise the very first
      -- buffer of the session is the one that misses out on the
      -- on-demand install path.
      --
      -- Only re-fire for filetypes that have a parser recipe in
      -- nvim-treesitter. Plugins that manage their own treesitter
      -- parser (e.g. orgmode) handle the first-load path themselves;
      -- re-firing during their async grammar install creates a race
      -- where ftplugin calls vim.treesitter.start() before the parser
      -- exists.
      vim.schedule(function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
            local ft = vim.bo[bufnr].filetype
            local lang = vim.treesitter.language.get_lang(ft) or ft
            if available[lang] then
              vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
            end
          end
        end
      end)

      -- ----------------------------------------------------------------
      -- Incremental selection (master branch parity).
      --
      -- Master shipped this as a built-in module under
      -- `incremental_selection`. On main it's removed entirely, so
      -- we reimplement the minimum surface here: <C-Space> grows the
      -- visual selection to the next-larger treesitter ancestor,
      -- <BS> shrinks back. State is a per-buffer node stack so a
      -- shrink can return the prior frame exactly.
      -- ----------------------------------------------------------------
      local node_stack = {} ---@type table<integer, TSNode[]>

      local function set_visual_range(srow, scol, erow, ecol)
        -- Treesitter ranges are 0-indexed, end-exclusive on column.
        -- Vim marks are 1-indexed, end-inclusive on column.
        vim.fn.setpos("'<", { 0, srow + 1, scol + 1, 0 })
        vim.fn.setpos("'>", { 0, erow + 1, ecol, 0 })
        vim.cmd("normal! gv")
      end

      local function init_selection()
        local bufnr = vim.api.nvim_get_current_buf()
        local node = vim.treesitter.get_node()
        if not node then
          return
        end
        node_stack[bufnr] = { node }
        local srow, scol, erow, ecol = node:range()
        set_visual_range(srow, scol, erow, ecol)
      end

      local function grow_selection()
        local bufnr = vim.api.nvim_get_current_buf()
        local stack = node_stack[bufnr]
        if not stack or #stack == 0 then
          init_selection()
          return
        end
        local current = stack[#stack]
        local parent = current:parent()
        if not parent then
          return
        end
        table.insert(stack, parent)
        local srow, scol, erow, ecol = parent:range()
        set_visual_range(srow, scol, erow, ecol)
      end

      local function shrink_selection()
        local bufnr = vim.api.nvim_get_current_buf()
        local stack = node_stack[bufnr]
        if not stack or #stack <= 1 then
          return
        end
        table.remove(stack)
        local current = stack[#stack]
        local srow, scol, erow, ecol = current:range()
        set_visual_range(srow, scol, erow, ecol)
      end

      -- Drop the saved stack when leaving visual mode so the next
      -- <C-Space> press starts a fresh selection from the cursor.
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = vim.api.nvim_create_augroup("ACHTreesitterIncSel", { clear = true }),
        pattern = { "[vV\22]:n", "[vV\22]:i" },
        callback = function()
          node_stack[vim.api.nvim_get_current_buf()] = nil
        end,
      })

      vim.keymap.set("n", "<C-Space>", init_selection, { silent = true, desc = "Init Selection" })
      vim.keymap.set("x", "<C-Space>", grow_selection, { silent = true, desc = "Grow Selection" })
      vim.keymap.set("x", "<BS>", shrink_selection, { silent = true, desc = "Shrink Selection" })
    end,
  },

  -- nvim-treesitter-textobjects on main branch.
  --
  -- The main branch ships a brand-new keymap-driven API: instead of
  -- declaring `textobjects.select.keymaps` in opts, you call
  -- `select.select_textobject("@function.outer", "textobjects")` from a
  -- keymap callback. The "textobjects" second argument is the query
  -- group name (file: queries/<lang>/textobjects.scm). Same shape for
  -- move (`move.goto_next_start`, `move.goto_previous_end`, etc.) and
  -- swap (`swap.swap_next`, `swap.swap_previous`).
  --
  -- The init hook sets `vim.g.no_plugin_maps = true` per the upstream
  -- README to disable Neovim's built-in ftplugin keymaps that would
  -- otherwise collide with custom textobjects. Per-filetype escapes
  -- (`vim.g.no_python_maps`, etc.) are available if a specific
  -- filetype's defaults are worth keeping.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    init = function()
      vim.g.no_plugin_maps = true
    end,
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          -- Mirrors the master branch behavior: jump forward to
          -- the next textobject if the cursor isn't currently
          -- inside one.
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      -- Helper to keep the keymap declarations short. Each binding
      -- maps a query capture (e.g. "@function.outer") to one of the
      -- two select / move APIs.
      local function map_select(lhs, capture, desc)
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(capture, "textobjects")
        end, { silent = true, desc = desc })
      end
      local function map_move(lhs, capture, dir, desc)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move["goto_" .. dir](capture, "textobjects")
        end, { silent = true, desc = desc })
      end

      -- Select: af / if (function), ac / ic (class), aa / ia (parameter).
      map_select("af", "@function.outer", "Around Function")
      map_select("if", "@function.inner", "Inside Function")
      map_select("ac", "@class.outer", "Around Class")
      map_select("ic", "@class.inner", "Inside Class")
      map_select("aa", "@parameter.outer", "Around Parameter")
      map_select("ia", "@parameter.inner", "Inside Parameter")

      -- Move: ]f / [f, ]F / [F (function start / end),
      --       ]c / [c, ]C / [C (class start / end),
      --       ]a / [a, ]A / [A (parameter inner start / end).
      map_move("]f", "@function.outer", "next_start", "Next Function")
      map_move("[f", "@function.outer", "previous_start", "Prev Function")
      map_move("]F", "@function.outer", "next_end", "Next Function End")
      map_move("[F", "@function.outer", "previous_end", "Prev Function End")
      map_move("]c", "@class.outer", "next_start", "Next Class")
      map_move("[c", "@class.outer", "previous_start", "Prev Class")
      map_move("]C", "@class.outer", "next_end", "Next Class End")
      map_move("[C", "@class.outer", "previous_end", "Prev Class End")
      map_move("]a", "@parameter.inner", "next_start", "Next Parameter")
      map_move("[a", "@parameter.inner", "previous_start", "Prev Parameter")
      map_move("]A", "@parameter.inner", "next_end", "Next Parameter End")
      map_move("[A", "@parameter.inner", "previous_end", "Prev Parameter End")
    end,
  },

  -- nvim-treesitter-context: sticky function/class header that pins the
  -- current scope's signature to the top of the buffer when you scroll
  -- past its definition. `mode = "cursor"` means the context follows the
  -- cursor (not the topmost visible line), which is the more useful mode
  -- when navigating with `}`/`{` or `[c`/`]c`. `max_lines = 3` caps the
  -- pinned area so a deeply-nested context doesn't take over the screen.
  -- Toggleable via `<leader>ut` through the snacks toggle pattern.
  --
  -- This plugin is independent of nvim-treesitter master/main and works
  -- with either branch as long as `vim.treesitter` is enabled in the
  -- buffer (which our autocmds.lua / install autocmd above handles).
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
        get = function()
          return tsc.enabled()
        end,
        set = function(state)
          if state then
            tsc.enable()
          else
            tsc.disable()
          end
        end,
      }):map("<leader>ut")
    end,
  },

  -- which-key: icons for treesitter-specific keymaps.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        {
          "<leader>ut",
          desc = "Toggle Treesitter Context",
          icon = { icon = icons.find.treesitter, color = "green" },
        },
        -- Incremental selection (operator/visual mode bindings).
        { "<C-Space>", desc = "Init / Grow Selection", icon = { icon = icons.ui.expand, color = "cyan" } },
        { "<BS>", desc = "Shrink Selection", mode = "x", icon = { icon = icons.ui.collapse, color = "cyan" } },
      },
    },
  },
}
