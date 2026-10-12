-- Every colour the theme and the status bar use, copied from the spec's
-- tables. No other file in the theme or the status bar names a colour.
return {
  bg = "#011628",
  bg_dark = "#011423", -- floating windows, popups, sidebar, status line
  bg_highlight = "#143652", -- cursor line
  bg_search = "#0A64AC",
  bg_visual = "#275378",
  border = "#547998",
  fg = "#CBE0F0",
  fg_dark = "#B4D0E9", -- secondary and sidebar text
  fg_gutter = "#627E97", -- line numbers
  comment = "#7b84ac", -- tokyonight's #565f89, raised to 5.00:1
  dark3 = "#6c759d", -- inlay hints and quiet text, raised to 4.07:1
  banner = "#7aa2f7", -- tokyonight blue, the dashboard letters

  -- The status line palette from Josean Martinez's post.
  line = {
    blue = "#65D1FF",
    green = "#3EFFDC",
    violet = "#FF61EF",
    yellow = "#FFDA7B",
    red = "#FF4A4A",
    fg = "#c3ccdc",
    bg = "#112638",
    inactive_bg = "#2c3043",
    semilightgray = "#a9b1d6",
  },
}
