-- The status bar and the icon set behind it. The nvim-web-devicons stand-in
-- is adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/ui.lua.
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-mini/mini.icons" },
    opts = function()
      return require("ach.statusline").options()
    end,
    config = function(_, opts)
      require("ach.statusline").setup(opts)
    end,
  },
  {
    "nvim-mini/mini.icons",
    -- The icon database's overrides: the hardware languages get chips, gates and
    -- waveforms, and file types mini.icons does not know get an icon of their own.
    opts = function()
      return require("ach.icons").mini()
    end,
    init = function()
      -- Plugins that ask for nvim-web-devicons get mini.icons instead.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
