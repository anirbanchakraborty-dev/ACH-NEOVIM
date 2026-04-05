-- Editor: fzf-lua (fuzzy finder)

return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find File" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Grep Word" },
      { "<leader>fc", "<cmd>FzfLua files cwd=~/.config/nvim<cr>", desc = "Config Files" },
      { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
      { "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
      { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
      { "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
      { "<leader>sr", "<cmd>FzfLua resume<cr>", desc = "Resume Last" },
      { "<leader>sg", "<cmd>FzfLua git_files<cr>", desc = "Git Files" },
      { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git Commits" },
      { "<leader>gb", "<cmd>FzfLua git_branches<cr>", desc = "Git Branches" },
      { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git Status" },
    },
    opts = {
      -- Global fzf-lua options
      "default-title",
      fzf_colors = true,
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        border = "rounded",
        preview = {
          border = "rounded",
          layout = "flex",
          flip_columns = 120,
          scrollbar = "float",
        },
      },
      files = {
        cwd_prompt = false,
        git_icons = true,
        file_icons = true,
      },
      grep = {
        git_icons = true,
        file_icons = true,
      },
      lsp = {
        symbols = {
          symbol_icons = true,
        },
      },
    },
  },
}
