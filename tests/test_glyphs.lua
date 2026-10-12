return {
  ["forbids the 1,123 codepoints from Nerd Fonts 3.5.1"] = function(t)
    t.eq(vim.tbl_count(require("ach.glyphs_forbidden")), 1123)
  end,

  ["forbids chevrons, separators, the XML icon, code brackets and arrows"] = function(t)
    local glyphs = require("ach.glyphs")
    for _, cp in ipairs({ 0xF054, 0xE0B0, 0xF05C0, 0xF121, 0x3C, 0x3E, 0x2192 }) do
      t.ok(glyphs.forbidden(cp), ("U+%04X should be forbidden"):format(cp))
    end
  end,

  ["allows the warning sign and the open folder"] = function(t)
    local glyphs = require("ach.glyphs")
    t.ok(not glyphs.forbidden(0xF071), "U+F071, the warning sign, is allowed")
    t.ok(not glyphs.forbidden(0xF07C), "U+F07C, the open folder, is allowed")
  end,

  ["lists the forbidden characters of a string"] = function(t)
    t.eq(require("ach.glyphs").offending("a > b \u{F054} \u{F07C}"), { 0x3E, 0xF054 })
  end,

  ["swaps a forbidden icon for the plain file icon"] = function(t)
    local glyphs = require("ach.glyphs")
    t.eq(glyphs.fallback, "\u{F15B}")
    t.eq(glyphs.safe_icon("\u{F05C0}"), "\u{F15B}", "the XML icon")
    t.eq(glyphs.safe_icon("\u{F07C}"), "\u{F07C}", "an allowed icon passes through")
  end,

  ["knows the 10,617 Nerd Font codepoints in 27 ranges"] = function(t)
    local ranges = require("ach.glyphs_known")
    local total = 0
    for _, range in ipairs(ranges) do
      total = total + range[2] - range[1] + 1
    end
    t.eq(#ranges, 27, "ranges")
    t.eq(total, 10617, "codepoints")
  end,

  ["knows text and symbols but not the gaps between Nerd Font ranges"] = function(t)
    local glyphs = require("ach.glyphs")
    for _, cp in ipairs({ 0x41, 0xB7, 0x2726, 0x258E, 0xF015, 0xE62B, 0xF0001, 0xF1AF0 }) do
      t.ok(glyphs.known(cp), ("U+%04X should be known"):format(cp))
    end
    for _, cp in ipairs({ 0x1F600, 0xE0C9, 0xE6BC, 0xF386, 0xF1AF1 }) do
      t.ok(not glyphs.known(cp), ("U+%04X should not be known"):format(cp))
    end
  end,
}
