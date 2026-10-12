-- Git: gitsigns for the change bars and the keys for one change at a time,
-- Neogit for staging and committing in a tab, diffview for side-by-side diffs
-- and file history, octo for GitHub, and lazygit, the browse link and the git
-- pickers from snacks. Every key calls ach.git, which checks for a repository
-- and for the program first.

-- A key's action: the ach.git function called name, given a and b.
local function git(name, a, b)
  return function() require("ach.git")[name](a, b) end
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function() return require("ach.git").gitsigns_opts() end,
    config = function(_, opts)
      require("gitsigns").setup(opts)
      require("ach.git").toggles()
    end,
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "sindrets/diffview.nvim" },
    opts = {
      kind = "tab",
      graph_style = "unicode",
      integrations = { diffview = true, snacks = true },
    },
    keys = {
      { "<leader>gn", git("neogit"), desc = "Neogit (Root Dir)" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      -- A merge conflict shows the two sides above and the result below.
      view = { merge_tool = { layout = "diff3_mixed" } },
    },
    keys = {
      { "<leader>gD", git("diffview", "open"), desc = "Diff View (Root Dir)" },
      { "<leader>gF", git("diffview", "file"), desc = "File History (Diff View)" },
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    -- Reopening an octo:// buffer, from the jump list or a session, loads it.
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { picker = "snacks", enable_builtin = true },
    keys = {
      { "<leader>gi", git("octo", "issue list"), desc = "GitHub Issues" },
      { "<leader>gp", git("octo", "pr list"), desc = "GitHub Pull Requests" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", git("lazygit"), desc = "Lazygit (Root Dir)" },
      { "<leader>gG", git("lazygit", "cwd"), desc = "Lazygit (cwd)" },
      { "<leader>gs", git("pick", "git_status"), desc = "Git Status" },
      { "<leader>gS", git("pick", "git_stash"), desc = "Git Stash" },
      { "<leader>gd", git("pick", "git_diff"), desc = "Git Diff (hunks)" },
      { "<leader>gl", git("pick", "git_log"), desc = "Git Log (Root Dir)" },
      { "<leader>gL", git("pick", "git_log", "cwd"), desc = "Git Log (cwd)" },
      { "<leader>gf", git("pick", "git_log_file"), desc = "Git File History" },
      { "<leader>gb", git("pick", "git_log_line"), desc = "Git Line History" },
      { "<leader>gc", git("pick", "git_branches"), desc = "Git Branches" },
      { "<leader>gB", git("browse"), mode = { "n", "x" }, desc = "Git Browse (open)" },
      { "<leader>gY", git("copy_link"), mode = { "n", "x" }, desc = "Git Browse (copy link)" },
    },
  },
}
