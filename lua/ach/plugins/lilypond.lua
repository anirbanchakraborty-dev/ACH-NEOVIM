-- LilyPond: Swara brings the grammar and the language server in one program,
-- downloads that program the first time a LilyPond file opens, and starts both
-- itself. Its keys follow Backslash, and its check runs each time typing stops.
return {
  {
    "anirbanchakraborty-dev/swara",
    -- The plugin downloads the release matching its own version, so lazy.nvim
    -- takes only released versions, never a commit between two releases.
    version = "^0.1",
    ft = "lilypond",
    opts = function()
      return {
        -- Saving formats through conform, whose LSP fallback asks Swara's
        -- server, so the autoformat switches govern LilyPond like any other
        -- language. Swara's own format on save would format a second time.
        format_on_save = false,
        -- A dry run, as scripts/check makes, downloads nothing. A file address
        -- that does not exist fails at once, without the network.
        release_base_url = require("ach.install").dry and "file:///nonexistent/swara" or nil,
      }
    end,
  },
}
