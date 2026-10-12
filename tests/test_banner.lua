local banner = require("ach.banner")

return {
  ["the rule reproduces the banner the spec prints"] = function(t)
    t.eq(banner.lines(), vim.fn.readfile(t.root .. "/assets/banner.txt"))
  end,

  ["is seventeen lines and 78 columns"] = function(t)
    local lines = banner.lines()
    t.eq(#lines, 17, "line count")
    t.eq(banner.width(lines), 78, "width")
  end,

  ["shades the cell below and to the right of each filled cell"] = function(t)
    -- The letter I on its own: three filled cells on top and bottom, a
    -- one-cell stem, and the shadow one row down and one cell right.
    t.eq(banner.render("I"), {
      "██████",
      "  ██░░░░",
      "  ██░░",
      "  ██░░",
      "  ██░░",
      "  ██░░",
      "██████",
      "  ░░░░░░",
    })
  end,

  ["splits the banner into runs of one colour"] = function(t)
    local lines = banner.lines()
    local only = { AchBanner = "█", AchBannerShadow = "░" }
    local texts, mixed = {}, {}
    for _, chunk in ipairs(banner.chunks(lines)) do
      texts[#texts + 1] = chunk[1]
      local body = chunk[1]:gsub("^\n", "")
      local rest = body:gsub(vim.pesc(only[chunk.hl] or " "), "")
      if rest ~= "" then
        mixed[#mixed + 1] = vim.inspect(chunk)
      end
    end
    t.eq(mixed, {}, "chunks that mix characters")
    local rows = vim.split(table.concat(texts), "\n", { plain = true })
    t.eq(#rows, 17, "rows")
    for i, row in ipairs(rows) do
      t.eq(vim.api.nvim_strwidth(row), 78, "width of row " .. i)
      t.eq((row:gsub("%s+$", "")), lines[i], "row " .. i)
    end
  end,
}
