-- The start screen: the ACH NEOVIM banner, the research caption, the buttons,
-- recent files and projects, a tip that changes at each start, and the
-- startup time. snacks.nvim draws it; this module says what goes on it.
local banner = require("ach.banner")
local I = require("ach.icons")

local M = {}

-- Below this width the 78-column banner would wrap, so the words replace it.
M.min_banner_columns = 80

M.caption = {
  { "░░", hl = "AchBannerShadow" },
  { "  computer architecture · post-quantum cryptography  ", hl = "AchBannerCaption" },
  { "░░", hl = "AchBannerShadow" },
}

M.tip_icon = I.dashboard.tip
M.tips = {
  "Your configuration lives in ~/.config/nvim",
  "History, undo and sessions live in ~/.local/state/nvim",
  "Plugins and language tools live in ~/.local/share/nvim",
  "Press Space and pause to see every key that can follow",
  "Space s k searches every key by what it does",
  "Space ? lists the keys that belong to this buffer",
  "Space u f turns format on save off and on again",
  "Space q s brings back the last session in this folder",
  "Space a c opens Claude Code beside the file",
  "Space a b hands the current file to Claude Code",
  "docs/key-card.md has the everyday keys on one page",
}

local chosen
function M.tip()
  chosen = chosen or M.tips[vim.uv.hrtime() % #M.tips + 1]
  return chosen
end

-- Keys the built-in buttons use, including m, which appears once Mason does.
M.reserved = { f = true, r = true, p = true, g = true, c = true, l = true, m = true, q = true }
M.extra_buttons = {}

-- Adds a button between the built-in ones and Quit. The owner's private
-- .nvim.lua calls this for a notes button, so this repository never names
-- that folder.
function M.add_button(button)
  vim.validate("key", button.key, "string")
  vim.validate("desc", button.desc, "string")
  vim.validate("icon", button.icon, "string")
  vim.validate("action", button.action, { "string", "function" })
  local taken = M.reserved[button.key] or false
  for _, b in ipairs(M.extra_buttons) do
    taken = taken or b.key == button.key
  end
  if taken then
    error(("dashboard key %q is already taken"):format(button.key), 2)
  end
  table.insert(M.extra_buttons, { key = button.key, desc = button.desc, icon = button.icon, action = button.action })
end

function M.buttons()
  local list = {
    { key = "f", icon = I.dashboard.find_file, desc = "Find File", action = function() Snacks.picker.files() end },
    { key = "r", icon = I.dashboard.recent, desc = "Recent Files", action = function() Snacks.picker.recent() end },
    { key = "p", icon = I.dashboard.projects, desc = "Projects", action = function() Snacks.picker.projects() end },
    { key = "g", icon = I.dashboard.search_text, desc = "Search Text", action = function() Snacks.picker.grep() end },
    {
      key = "c",
      icon = I.dashboard.config,
      desc = "Configuration",
      action = function() Snacks.picker.files({ cwd = vim.g.ach_root }) end,
    },
    { key = "l", icon = I.dashboard.plugins, desc = "Plugins", action = function() vim.cmd("Lazy") end },
  }
  if vim.fn.exists(":Mason") == 2 then
    list[#list + 1] = {
      key = "m",
      icon = I.dashboard.language_tools,
      desc = "Language Tools",
      action = function() vim.cmd("Mason") end,
    }
  end
  for _, b in ipairs(M.extra_buttons) do
    list[#list + 1] = vim.tbl_extend("force", {}, b)
  end
  list[#list + 1] = { key = "q", icon = I.dashboard.quit, desc = "Quit", action = function() vim.cmd("qa") end }
  return list
end

-- The section list snacks.nvim draws, rebuilt on every redraw, so a resize
-- swaps between the banner and the words.
function M.sections(self)
  local width = vim.api.nvim_win_get_width(self.win)
  local head = width >= M.min_banner_columns and banner.chunks(banner.lines())
    or { { "ACH NEOVIM", hl = "AchBanner" } }
  local buttons = M.buttons()
  buttons.padding = 1
  return {
    { text = head, align = "center", padding = 1 },
    { text = M.caption, align = "center", padding = 1 },
    buttons,
    { icon = I.ui.clock, title = "Recent Files", section = "recent_files", limit = 8, indent = 2, padding = 1 },
    { icon = I.files.folder_search, title = "Projects", section = "projects", limit = 8, indent = 2, padding = 1 },
    { text = { { M.tip_icon .. " " .. M.tip(), hl = "footer" } }, align = "center", padding = 1 },
    { section = "startup" },
  }
end

return M
