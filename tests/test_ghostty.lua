-- Ghostty's settings, ghostty/config.ghostty. Every colour is checked against
-- lua/ach/palette.lua or against the terminal colours tokyonight gives Neovim.
-- No Ghostty window opens: two tests run Ghostty's command line, and they skip
-- until Ghostty is installed.

local FILE = "/ghostty/config.ghostty"

-- The cask installs the app and puts no ghostty command on the PATH, so the
-- command inside the app is used when the PATH has none.
local APP = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

local function ghostty()
  local bin = vim.fn.exepath("ghostty")
  if bin == "" and vim.fn.executable(APP) == 1 then
    bin = APP
  end
  return bin ~= "" and bin or nil
end

-- Reads the file into { key = { value, ... } }, a list per key, since palette
-- appears sixteen times. Ghostty's comments take a whole line, so a # later in
-- a line belongs to the value.
local function read(t)
  local ok, lines = pcall(vim.fn.readfile, t.root .. FILE)
  t.ok(ok and #lines > 0, "ghostty/config.ghostty exists and is not empty")
  local conf = {}
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") and not line:match("^%s*#") then
      local key, value = line:match("^%s*([%w%-]+)%s*=%s*(.-)%s*$")
      t.ok(key ~= nil, "every line is a name = value setting: " .. line)
      conf[key] = conf[key] or {}
      table.insert(conf[key], value)
    end
  end
  return conf
end

-- The sixteen palette lines as { [0] = "#rrggbb", ... }, in lowercase.
local function sixteen(t, conf)
  local got = {}
  for _, v in ipairs(conf.palette or {}) do
    local n, hex = v:match("^(%d+)=(#%x%x%x%x%x%x)$")
    t.ok(n ~= nil, "a palette line reads N=#rrggbb: " .. v)
    got[tonumber(n)] = hex:lower()
  end
  t.eq(#(conf.palette or {}), 16, "palette lines")
  return got
end

-- Neovim's own terminal colours, which tokyonight sets as it loads.
local function neovims()
  local want = {}
  for n = 0, 15 do
    local c = vim.g["terminal_color_" .. n]
    want[n] = c and c:lower()
  end
  return want
end

return {
  ["the background, text, cursor and selection are the theme's"] = function(t)
    local conf = read(t)
    local p = require("ach.palette")
    local function one(key)
      t.eq(conf[key] and #conf[key], 1, key .. " is set once")
      return conf[key][1]:upper()
    end
    t.eq(one("background"), p.bg:upper(), "background, the navy behind the editor")
    t.eq(one("foreground"), p.fg:upper(), "foreground, the text")
    t.eq(one("cursor-color"), p.fg:upper(), "cursor-color")
    t.eq(one("selection-background"), p.bg_visual:upper(), "selection-background, as Neovim's Visual")
    t.eq(one("selection-foreground"), p.fg:upper(), "selection-foreground")
  end,

  ["the sixteen colours are the ones Neovim gives its own terminal"] = function(t)
    local got = sixteen(t, read(t))
    local want = neovims()
    t.ok(want[0] ~= nil, "tokyonight has set vim.g.terminal_color_0")
    t.eq(got, want, "palette 0 to 15")
  end,

  ["every colour that draws text reads at 4.5 to 1 or better on the navy"] = function(t)
    local got = sixteen(t, read(t))
    local ratio = require("ach.contrast").ratio
    local bg = require("ach.palette").bg
    local low = {}
    for n, hex in pairs(got) do
      -- 0, black, is a background shade, and 8, bright black, is kept faint on
      -- purpose, for hints such as a shell's suggested rest of a command.
      if n ~= 0 and n ~= 8 and ratio(hex, bg) < 4.5 then
        table.insert(low, ("%d %s at %.2f to 1"):format(n, hex, ratio(hex, bg)))
      end
    end
    table.sort(low)
    t.eq(low, {}, "text colours below 4.5 to 1")
  end,

  ["no colour appears that is not the palette's or Neovim's terminal's"] = function(t)
    local conf = read(t)
    local known = {}
    for _, hex in pairs(require("ach.palette")) do
      if type(hex) == "string" then
        known[hex:lower()] = true
      end
    end
    for _, hex in pairs(neovims()) do
      known[hex] = true
    end
    local strays = {}
    for key, values in pairs(conf) do
      for _, value in ipairs(values) do
        for hex in value:gmatch("#%x%x%x%x%x%x") do
          if not known[hex:lower()] then
            table.insert(strays, key .. " " .. hex)
          end
        end
      end
    end
    table.sort(strays)
    t.eq(strays, {}, "colours from nowhere")
  end,

  ["the font is MesloLGS Nerd Font Mono at 14 points, and the left Option key is Alt"] = function(t)
    local conf = read(t)
    t.eq(conf["font-family"], { "MesloLGS Nerd Font Mono" }, "font-family")
    t.eq(conf["font-size"], { "14" }, "font-size, 14 points")
    t.eq(conf["macos-option-as-alt"], { "left" }, "macos-option-as-alt")
  end,

  ["Ghostty accepts every line of the file"] = function(t)
    read(t)
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+validate-config", "--config-file=" .. t.root .. FILE }, { text = true }):wait(30000)
    t.eq(r.code, 0, "ghostty +validate-config, which printed: " .. (r.stdout or "") .. (r.stderr or ""))
  end,

  ["the font the file names is one Ghostty can find"] = function(t)
    local family = (read(t)["font-family"] or {})[1] or ""
    t.ok(family ~= "", "font-family is set")
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+list-fonts", "--family=" .. family }, { text = true }):wait(30000)
    if not (r.stdout or ""):find(family, 1, true) then
      t.human(family .. " is not installed. Install it with: brew install --cask font-meslo-lg-nerd-font")
    end
  end,
}
