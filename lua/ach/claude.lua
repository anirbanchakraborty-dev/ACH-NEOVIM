-- Claude Code: what the status bar shows, claudecode's options, and the
-- panel's place among the docked panes. claudecode opens a WebSocket server on
-- 127.0.0.1 and writes its port and a token to a lock file only the owner can
-- read; Claude Code finds the file, connects with the token, and can then see
-- the selection and propose changes as diffs. With no screen, as in a script
-- or the tests, no server starts and no lock file is written.
local need = require("ach.need")

local M = {}

-- "connected" while Claude Code is connected, "waiting" while the server
-- listens with nobody connected, and "off" otherwise. The status bar calls
-- this on every redraw, so it reads claudecode only once something else has
-- loaded it.
---@return "connected"|"waiting"|"off"
function M.status()
  local cc = package.loaded["claudecode"]
  if not (cc and cc.state and cc.state.server) then
    return "off"
  end
  return cc.is_claude_connected() and "connected" or "waiting"
end

-- claudecode's setup table.
---@return table
function M.opts()
  return {
    -- A Neovim nobody can see gets no server, so Claude Code never offers it.
    auto_start = #vim.api.nvim_list_uis() > 0,
    terminal = {
      provider = "snacks",
      split_side = "right",
      split_width_percentage = 0.4,
      -- Claude starts at the top of the current file's repository.
      git_repo_cwd = true,
      -- A mark on the panel's buffer, which its edgy view looks for. It is
      -- on the buffer, not the window, because after a hide claudecode
      -- builds a new window and marks it only after edgy has looked at it.
      snacks_win_opts = { b = { ach_claude = true } },
    },
  }
end

-- The panel's view on edgy's right edge. It names its own width because edgy
-- makes a bar as wide as the widest view in it, counting a view that names no
-- width as the bar's default of 30 columns.
---@return table
function M.view()
  return {
    title = "Claude Code",
    ft = "snacks_terminal",
    size = { width = 0.4 },
    filter = function(buf) return vim.b[buf].ach_claude == true end,
  }
end

-- Runs a claudecode command once the claude program is found. When it is
-- missing, ach.need prints the line that installs it and nothing opens.
---@param command string
function M.cmd(command)
  if need.have("claude") then
    vim.cmd(command)
  end
end

return M
