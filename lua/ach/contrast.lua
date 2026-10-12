-- WCAG 2 relative luminance and contrast ratio for "#rrggbb" colours.
local M = {}

local function channel(value)
  local c = value / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

function M.luminance(hex)
  local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

function M.ratio(a, b)
  local la, lb = M.luminance(a), M.luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

return M
