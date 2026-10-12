local banner = require("ach.banner")
local dashboard = require("ach.dashboard")

-- Writes two files into a fresh folder, one of them inside a git repository,
-- and makes them the recent files the dashboard lists.
local function seed(t)
  local base = t.tmpdir()
  local project = base .. "/ach-dash-project"
  vim.fn.mkdir(project, "p")
  vim.fn.system({ "git", "-C", project, "init", "-q" })
  vim.fn.writefile({ "# notes" }, project .. "/ach-dash-notes.md")
  vim.fn.writefile({ "plain" }, base .. "/ach-dash-plain.txt")
  vim.v.oldfiles = { project .. "/ach-dash-notes.md", base .. "/ach-dash-plain.txt" }
end

-- Draws the dashboard in a new tab at the given width, returns its lines and
-- the highlight groups it used, then closes the tab, which wipes the buffer.
local function draw(columns)
  local saved = vim.o.columns
  vim.o.columns = columns
  vim.cmd("tabnew")
  local dash = Snacks.dashboard.open({ win = 0 })
  local lines = vim.api.nvim_buf_get_lines(dash.buf, 0, -1, false)
  local groups = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(dash.buf, -1, 0, -1, { details = true })) do
    if mark[4].hl_group then
      groups[mark[4].hl_group] = true
    end
  end
  vim.cmd("tabclose")
  vim.o.columns = saved
  return lines, groups
end

local function has(lines, text)
  return table.concat(lines, "\n"):find(text, 1, true) ~= nil
end

return {
  ["draws every part at full width"] = function(t)
    seed(t)
    local lines, groups = draw(200)
    local top = banner.lines()[1]:gsub("^%s+", "")
    local want = {
      top,
      "░░  computer architecture · post-quantum cryptography  ░░",
      "Find File",
      "Recent Files",
      "Projects",
      "Search Text",
      "Configuration",
      "Plugins",
      "Quit",
      "ach-dash-notes.md",
      "ach-dash-plain.txt",
      dashboard.tip(),
      "Neovim loaded ",
    }
    local missing = {}
    for _, text in ipairs(want) do
      if not has(lines, text) then
        missing[#missing + 1] = text
      end
    end
    t.eq(missing, {}, "parts missing from the dashboard")
    for _, group in ipairs({ "AchBanner", "AchBannerShadow", "AchBannerCaption" }) do
      t.ok(groups[group], group .. " is used")
    end
  end,

  ["lists the project a recent file belongs to"] = function(t)
    seed(t)
    local lines = draw(200)
    local found = false
    for _, line in ipairs(lines) do
      if line:find("ach-dash-project", 1, true) and not line:find("ach-dash-notes", 1, true) then
        found = true
      end
    end
    t.ok(found, "a Projects row for ach-dash-project")
  end,

  ["shows the words instead of the banner in a narrow window"] = function(t)
    seed(t)
    local lines = draw(60)
    t.ok(not has(lines, "██"), "no banner letters at 60 columns")
    t.ok(has(lines, "ACH NEOVIM"), "the words ACH NEOVIM")
    local wide = {}
    for i, line in ipairs(lines) do
      local width = vim.api.nvim_strwidth((line:gsub("%s+$", "")))
      if width > 60 then
        wide[#wide + 1] = ("line %d is %d columns"):format(i, width)
      end
    end
    t.eq(wide, {}, "lines wider than the window")
  end,

  ["offers language tools exactly when Mason is installed"] = function(t)
    local lines = draw(200)
    t.eq(has(lines, "Language Tools"), vim.fn.exists(":Mason") == 2)
  end,

  ["every button draws an icon from the icon database"] = function(t)
    local held, bad = {}, {}
    for _, glyph in pairs(require("ach.icons").dashboard) do
      held[glyph] = true
    end
    for _, b in ipairs(dashboard.buttons()) do
      if not held[b.icon] then
        bad[#bad + 1] = b.key .. " " .. b.desc
      end
    end
    t.eq(bad, {}, "buttons whose icon the database does not hold")
    t.eq(dashboard.tip_icon, require("ach.icons").dashboard.tip, "the tip's icon")
  end,

  ["shows a button added by a private .nvim.lua"] = function(t)
    local notes = require("ach.icons").dashboard.notes
    dashboard.add_button({ key = "n", desc = "Notes", icon = notes, action = function() end })
    local ok, lines = pcall(draw, 200)
    dashboard.extra_buttons = {}
    t.ok(ok, "the dashboard draws with the extra button: " .. tostring(lines))
    t.ok(has(lines, "Notes"), "the Notes button")
  end,

  ["refuses a button key that is already taken"] = function(t)
    local ok, err = pcall(dashboard.add_button, { key = "f", desc = "Other", icon = "x", action = "enew" })
    t.eq(ok, false, "adding a second f button")
    t.ok(tostring(err):find("already taken", 1, true), "the error says why, got: " .. tostring(err))
    t.eq(dashboard.extra_buttons, {}, "nothing was added")
  end,

  ["keeps one tip for the whole session"] = function(t)
    t.eq(dashboard.tip(), dashboard.tip())
    t.ok(vim.tbl_contains(dashboard.tips, dashboard.tip()), "the tip comes from the list")
  end,

  ["every tip fits a 60-column window"] = function(t)
    local long = {}
    for _, tip in ipairs(dashboard.tips) do
      local width = vim.api.nvim_strwidth(dashboard.tip_icon .. " " .. tip)
      if width > 60 then
        long[#long + 1] = ("%d: %s"):format(width, tip)
      end
    end
    t.eq(long, {}, "tips wider than 60 columns")
  end,
}
