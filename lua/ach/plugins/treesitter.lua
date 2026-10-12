-- Tree-sitter. nvim-treesitter installs parsers and their queries, and
-- nvim-treesitter-textobjects carries the function, class and parameter
-- queries the moves use. Both track their main branch, which needs Neovim
-- 0.12 and the tree-sitter command-line tool. lua/ach/install.lua decides
-- when a parser installs, and lua/ach/treesitter.lua starts it on a buffer.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- The main branch says it does not support lazy loading, meaning its
    -- commands and parser folder must be there before a file needs them.
    -- LazyVim loads it lazily all the same, and so does this: at the start
    -- when a file is named, otherwise after the first screen, or sooner when
    -- lua/ach/treesitter.lua starts it on a buffer or one of its commands runs.
    lazy = vim.fn.argc(-1) == 0,
    event = "VeryLazy",
    cmd = { "TSUpdate", "TSInstall", "TSInstallFromGrammar", "TSUninstall", "TSLog" },
    build = ":TSUpdate",
    init = function()
      -- nvim-treesitter rereads its parser list on this event, so the table's
      -- own parsers are added back each time.
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function() require("ach.treesitter").register_custom() end,
      })
    end,
    config = function() require("nvim-treesitter").setup({}) end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    config = function()
      require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
      -- Buffers opened before VeryLazy were attached before these queries
      -- were on the runtime path, so they get their moves now.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          require("ach.treesitter").attach(buf)
        end
      end
    end,
  },
}
