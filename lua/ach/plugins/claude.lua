-- Claude Code: claudecode.nvim runs the claude program in a panel on the right
-- and opens the server Claude Code connects to. Every key calls ach.claude,
-- which checks for the program first.

-- A key's action: the claudecode command, once the claude program is found.
local function claude(command)
  return function() require("ach.claude").cmd(command) end
end

return {
  {
    "coder/claudecode.nvim",
    -- Loaded once Neovim is idle, so the server is up before Claude Code looks
    -- for an editor, without slowing the start.
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeAdd",
      "ClaudeCodeClose",
      "ClaudeCodeCloseAllDiffs",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeFocus",
      "ClaudeCodeOpen",
      "ClaudeCodeSelectModel",
      "ClaudeCodeSend",
      "ClaudeCodeSendText",
      "ClaudeCodeStart",
      "ClaudeCodeStatus",
      "ClaudeCodeStop",
      "ClaudeCodeTreeAdd",
    },
    opts = function() return require("ach.claude").opts() end,
    keys = {
      { "<leader>ac", claude("ClaudeCode"), desc = "Toggle Claude" },
      { "<leader>af", claude("ClaudeCodeFocus"), desc = "Focus Claude" },
      { "<leader>ar", claude("ClaudeCode --resume"), desc = "Resume Claude" },
      { "<leader>aC", claude("ClaudeCode --continue"), desc = "Continue Claude" },
      { "<leader>am", claude("ClaudeCodeSelectModel"), desc = "Select Claude Model" },
      -- ClaudeCodeAdd completes file names, so Neovim turns % into this file's name.
      { "<leader>ab", claude("ClaudeCodeAdd %"), desc = "Add Buffer to Claude" },
      { "<leader>as", claude("ClaudeCodeSend"), mode = "x", desc = "Send to Claude" },
      {
        "<leader>as",
        claude("ClaudeCodeTreeAdd"),
        ft = { "oil", "snacks_picker_list" },
        desc = "Add File to Claude",
      },
      { "<leader>aa", claude("ClaudeCodeDiffAccept"), desc = "Accept Diff" },
      { "<leader>ad", claude("ClaudeCodeDiffDeny"), desc = "Deny Diff" },
    },
  },
}
