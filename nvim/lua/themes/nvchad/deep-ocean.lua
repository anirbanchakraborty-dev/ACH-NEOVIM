-- ACH-NEOVIM signature palette. Not from NvChad/base46.
-- Hand-tuned deep navy ocean aesthetic, authored in the base46 file
-- format so the theme loader can treat it uniformly alongside the
-- vendored NvChad palettes.

local M = {}

M.base_30 = {
  white = "#CBE0F0",
  darker_black = "#011423", -- floats, sidebars, popups, statusline
  black = "#011628", --  nvim bg
  black2 = "#011a2e",
  one_bg = "#0d2238",
  one_bg2 = "#143652", -- cursorline, pmenu selection
  one_bg3 = "#1a4063",
  grey = "#3d5b7a",
  grey_fg = "#4d6b8a",
  grey_fg2 = "#627E97", -- dim text, line numbers, comments
  light_grey = "#7890a8",
  red = "#FF5370",
  baby_pink = "#ff7d92",
  pink = "#ff75a0",
  line = "#143652", -- for lines like vertsplit
  green = "#C3E88D",
  vibrant_green = "#7eca9c",
  nord_blue = "#82AAFF",
  blue = "#82AAFF",
  yellow = "#FFCB6B",
  sun = "#FFCB6B",
  purple = "#C792EA",
  dark_purple = "#a652de",
  teal = "#80CBC4",
  orange = "#F78C6C",
  cyan = "#89DDFF",
  statusline_bg = "#011423",
  lightbg = "#143652",
  pmenu_bg = "#82AAFF",
  folder_bg = "#82AAFF",
}

M.base_16 = {
  base00 = "#011628", -- default bg
  base01 = "#011a2e", -- lighter bg (status, line numbers)
  base02 = "#143652", -- selection bg
  base03 = "#627E97", -- comments, invisibles
  base04 = "#7890a8", -- dark fg (status)
  base05 = "#CBE0F0", -- default fg
  base06 = "#d4e5f2", -- light fg
  base07 = "#dce9f5", -- lightest fg
  base08 = "#FF5370", -- variables, diff deleted
  base09 = "#F78C6C", -- integers, constants
  base0A = "#FFCB6B", -- classes, search bg
  base0B = "#C3E88D", -- strings, diff inserted
  base0C = "#89DDFF", -- support, regexes, escapes
  base0D = "#82AAFF", -- functions, methods, headings
  base0E = "#C792EA", -- keywords, storage, diff changed
  base0F = "#f07178", -- deprecated, language tags
}

M.type = "dark"

M = require("base46").override_theme(M, "deep-ocean")

return M
