-- Minimal shim that lets us require() NvChad/base46 theme files verbatim
-- without pulling in base46 itself.
--
-- Every vendored theme file under `themes/nvchad/*.lua` ends with a line
-- like `M = require("base46").override_theme(M, "<name>")`. base46's real
-- override_theme() applies user customizations from chadrc.lua (which we
-- don't have). This shim returns the palette table unchanged.
--
-- Registered as `package.preload["base46"]` from `themes/init.lua` so the
-- shim resolves first whenever a theme file does `require("base46")`.

local M = {}

function M.override_theme(theme, _name)
  return theme
end

return M
