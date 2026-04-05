-- Central icon definitions for ACH-NEOVIM
-- All Nerd Font icons used across the project are defined here.

local M = {}

M.ui = {
  find_file  = "",  -- nf-fa-search
  new_file   = "",  -- nf-fa-plus
  find_text  = "󰍉",  -- nf-md-magnify
  recent     = "",  -- nf-fa-clock_o
  config     = "",  -- nf-fa-cog
  lazy       = "󰏖",  -- nf-md-package_variant
  quit       = "",  -- nf-fa-power_off
  startup    = "",  -- nf-fa-bolt
}

M.diagnostics = {
  error = "",  -- nf-fa-times_circle
  warn  = "",  -- nf-fa-exclamation_triangle
  info  = "",  -- nf-fa-info_circle
  hint  = "",  -- nf-fa-lightbulb_o
}

M.git = {
  branch  = "",  -- nf-fa-code_fork
  added   = "",  -- nf-fa-plus_circle
  changed = "",  -- nf-fa-exclamation_circle
  removed = "",  -- nf-fa-minus_circle
}

M.os = {
  mac = "",  -- nf-fa-apple
}

M.lsp = {
  server = "",  -- nf-fa-cogs
}

M.noice = {
  cmdline     = "",  -- nf-fa-terminal
  search_down = " ",  -- nf-fa-search + nf-fa-long_arrow_down
  search_up   = " ",  -- nf-fa-search + nf-fa-long_arrow_up
  filter      = "",  -- nf-fa-filter
  lua         = "",  -- nf-seti-lua
  help        = "",  -- nf-fa-question_circle
}

return M
