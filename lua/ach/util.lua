-- Small helpers shared by the status bar, the dashboard and the pickers.
local M = {}

-- The nearest folder at or above the buffer's file that holds .git, if any.
function M.git_root(buf) return vim.fs.root(buf or 0, ".git") end

-- The buffer's project: its git root, or else the working folder.
function M.root(buf) return M.git_root(buf) or vim.uv.cwd() end

return M
