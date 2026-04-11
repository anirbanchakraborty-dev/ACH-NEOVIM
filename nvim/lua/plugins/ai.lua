-- AI: claude code integration via coder/claudecode.nvim.
--
-- Implements a WebSocket-based variant of MCP (Model Context Protocol) so the
-- Claude CLI can read selections, open buffers, and propose diffs that you
-- review natively in Neovim. Pairs with snacks.nvim for the terminal panel.
--
-- Requires the `claude` CLI on PATH (`npm i -g @anthropic-ai/claude-code`).
local icons = require("config.icons")

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeSelectModel",
    },
    opts = function()
      -- Resolve the claude binary defensively. Prefer whatever's on PATH
      -- (so users with a custom install elsewhere keep working), and only
      -- fall back to ~/.local/bin/claude — where install.sh's native
      -- installer puts it — when PATH lookup fails. This handles the very
      -- common case of launching Neovim from a terminal session that was
      -- started *before* ~/.local/bin was added to PATH (tmux, long-lived
      -- iTerm2 windows, etc). Without this fallback the plugin spawns
      -- `claude`, the kernel can't resolve it, and the terminal exits 127.
      local terminal_cmd
      if vim.fn.executable("claude") ~= 1 then
        local fallback = vim.fn.expand("~/.local/bin/claude")
        if vim.fn.executable(fallback) == 1 then
          terminal_cmd = fallback
        end
      end

      return {
        terminal_cmd = terminal_cmd,
        -- Use snacks.nvim as the terminal provider so Claude opens in a
        -- themed split that matches the rest of the UI. 'auto' would also
        -- pick snacks here, but pinning makes the choice explicit.
        terminal = {
          provider = "snacks",
          snacks_win_opts = {
            position = "bottom",
            relative = "editor",
            height = 0.4,
            -- Visual separation from the editor pane: remap the panel's
            -- Normal/EndOfBuffer to NormalFloat so it picks up tokyonight's
            -- bg_dark (#011423) instead of bg (#011628). Without this the
            -- claude split shares the editor's background and looks like a
            -- single mashed window. WinSeparator stays themed via the
            -- colorscheme — no override needed.
            wo = {
              winhighlight = table.concat({
                "Normal:NormalFloat",
                "NormalNC:NormalFloat",
                "EndOfBuffer:NormalFloat",
                "SignColumn:NormalFloat",
              }, ","),
            },
            -- Terminal-mode hide: <Esc><Esc> drops the panel without
            -- killing the claude session, matching the ergonomics of the
            -- toggleterm REPLs in plugins/terminal.lua.
            keys = {
              claude_hide = {
                "<Esc><Esc>",
                function(self)
                  self:hide()
                end,
                mode = "t",
                desc = "Hide Claude",
              },
            },
          },
        },
        -- Side-by-side diff view for proposed changes.
        diff_opts = {
          layout = "vertical",
          open_in_new_tab = false,
        },
      }
    end,
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Current Buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send Selection to Claude" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Diff" },
    },
  },

  -- which-key: extend spec with the AI group + per-keymap icons.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Group (n + v because <leader>as is visual-mode)
        {
          "<leader>a",
          group = "AI / Claude",
          icon = { icon = icons.ai.claude, color = "purple" },
          mode = { "n", "v" },
        },

        -- Individual keymaps
        { "<leader>ac", desc = "Toggle Claude", icon = { icon = icons.ai.claude, color = "purple" } },
        { "<leader>af", desc = "Focus Claude", icon = { icon = icons.ai.focus, color = "cyan" } },
        { "<leader>ar", desc = "Resume Claude", icon = { icon = icons.ai.resume, color = "blue" } },
        { "<leader>aC", desc = "Continue Claude", icon = { icon = icons.ai.continue, color = "blue" } },
        { "<leader>am", desc = "Select Model", icon = { icon = icons.ai.model, color = "yellow" } },
        { "<leader>ab", desc = "Add Current Buffer", icon = { icon = icons.ai.add_buf, color = "green" } },
        {
          "<leader>as",
          desc = "Send Selection to Claude",
          icon = { icon = icons.ai.send, color = "cyan" },
          mode = "v",
        },
        { "<leader>aa", desc = "Accept Diff", icon = { icon = icons.ai.accept, color = "green" } },
        { "<leader>ad", desc = "Deny Diff", icon = { icon = icons.ai.deny, color = "red" } },
      },
    },
  },
}
