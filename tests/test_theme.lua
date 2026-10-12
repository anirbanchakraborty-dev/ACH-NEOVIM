local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function hex(n)
  return n and ("#%06X"):format(n) or "unset"
end

local function round(x)
  return math.floor(x * 100 + 0.5) / 100
end

return {
  ["uses tokyonight night"] = function(t)
    t.eq(vim.g.colors_name, "tokyonight-night")
  end,

  ["sets the colours in the spec's tables"] = function(t)
    local p = require("ach.palette")
    local want = {
      { "Normal", "bg", p.bg },
      { "Normal", "fg", p.fg },
      { "NormalFloat", "bg", p.bg_dark },
      { "NormalFloat", "fg", p.fg },
      { "CursorLine", "bg", p.bg_highlight },
      { "Search", "bg", p.bg_search },
      { "Visual", "bg", p.bg_visual },
      { "WinSeparator", "fg", p.border },
      { "LineNr", "fg", p.fg_gutter },
      { "Comment", "fg", p.comment },
      { "LspInlayHint", "fg", p.dark3 },
      { "AchBanner", "fg", p.banner },
      { "AchBannerShadow", "fg", p.border },
      { "AchBannerCaption", "fg", p.fg_dark },
      { "SnacksImageMath", "fg", p.fg },
    }
    local wrong = {}
    for _, w in ipairs(want) do
      local got = hl(w[1])[w[2]]
      if got ~= tonumber(w[3]:sub(2), 16) then
        table.insert(wrong, ("%s %s is %s, want %s"):format(w[1], w[2], hex(got), w[3]:upper()))
      end
    end
    t.eq(wrong, {}, "highlight colours")
  end,

  ["computes WCAG 2 contrast"] = function(t)
    local ratio = require("ach.contrast").ratio
    -- The spec's "before" figures, for the colours tokyonight ships.
    t.eq(round(ratio("#565f89", "#011628")), 2.96, "old comment colour on the background")
    t.eq(round(ratio("#565f89", "#143652")), 2.02, "old comment colour on the cursor line")
    t.eq(round(ratio("#545c7e", "#011628")), 2.80, "old dark3 on the background")
    t.eq(round(ratio("#011628", "#CBE0F0")), round(ratio("#CBE0F0", "#011628")), "order does not matter")
  end,

  ["meets the spec's contrast figures, recomputed from the live colours"] = function(t)
    local ratio = require("ach.contrast").ratio
    local p = require("ach.palette")
    local function c(fg_group, bg_group)
      return round(ratio(hex(hl(fg_group).fg), hex(hl(bg_group).bg)))
    end
    t.eq(c("Comment", "Normal"), 5.00, "comments on the background")
    t.eq(c("Comment", "CursorLine"), 3.42, "comments on the cursor line")
    t.eq(c("LspInlayHint", "Normal"), 4.07, "inlay hints")
    t.eq(c("Normal", "Normal"), 13.48, "body text")
    t.eq(c("LineNr", "Normal"), 4.32, "line numbers")
    t.eq(c("Normal", "Visual"), 5.96, "text over a selection")
    t.eq(c("Normal", "Search"), 4.51, "text over a search match")
    t.eq(c("AchBanner", "Normal"), 7.27, "banner letters")
    t.eq(round(ratio(p.line.semilightgray, p.line.inactive_bg)), 6.17, "inactive status line text")
  end,
}
