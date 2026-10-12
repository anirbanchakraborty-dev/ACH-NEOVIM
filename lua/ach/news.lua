-- Space N: newsboat, a feed reader, in a floating terminal. The feeds are
-- newsboat's own list, which this repository does not write.
local M = {}

-- The feed list newsboat reads, by newsboat's own rule: urls in the newsboat
-- folder under XDG_CONFIG_HOME, or ~/.config when that is unset or not an
-- absolute path, if that folder exists, and ~/.newsboat/urls if it does not.
---@return string
function M.urls()
  local base = vim.env.XDG_CONFIG_HOME
  if not base or base:sub(1, 1) ~= "/" then
    base = vim.fs.joinpath(vim.env.HOME, ".config")
  end
  local folder = vim.fs.joinpath(base, "newsboat")
  if vim.fn.isdirectory(folder) == 1 then
    return vim.fs.joinpath(folder, "urls")
  end
  return vim.fs.joinpath(vim.env.HOME, ".newsboat", "urls")
end

-- Space N. The terminal is toggled rather than opened, and always from the
-- home folder, so pressing again finds the same newsboat instead of starting
-- a second one, which would refuse to run while the first holds its lock.
function M.open()
  if not require("ach.need").have("newsboat") then
    return
  end
  local urls = M.urls()
  if vim.fn.filereadable(urls) ~= 1 then
    vim.notify(("newsboat has no feeds to read. Put one feed address per line in %s"):format(urls), vim.log.levels.WARN)
    return
  end
  Snacks.terminal.toggle("newsboat", {
    cwd = vim.env.HOME,
    -- o in newsboat opens an article with BROWSER, and with none it tries
    -- lynx, which macOS does not have. open hands the address to the default
    -- browser. A browser set in newsboat's own config still wins.
    env = { BROWSER = vim.env.BROWSER or "open" },
    win = { position = "float", border = "rounded", title = " News " },
  })
end

return M
