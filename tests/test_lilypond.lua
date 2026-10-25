-- LilyPond, through Swara. Each test loads the plugin and calls the part it
-- checks rather than opening a LilyPond file.
local I = require("ach.icons")

local function swara()
  require("lazy").load({ plugins = { "swara" } })
  return require("lazy.core.config").plugins.swara
end

return {
  ["Swara loads on a LilyPond file and leaves saving to conform"] = function(t)
    local p = swara()
    t.ok(p ~= nil, "Swara has a spec")
    t.ok(p._.handlers.ft and p._.handlers.ft.lilypond ~= nil, "it loads when a LilyPond file opens")
    t.eq(require("swara.config").get().format_on_save, false, "Swara's own format on save is off")
    t.eq(require("conform").formatters_by_ft.lilypond, nil, "conform names no formatter, so it asks Swara's server")
  end,

  -- Swara downloads its program the first time a LilyPond file opens, and
  -- test_filetypes opens one. scripts/check keeps the installer dry, so the
  -- download must fail on this machine too, before it reaches the network.
  ["a dry run points Swara's download at a file that is not there"] = function(t)
    swara()
    t.eq(require("ach.install").dry, true, "scripts/check runs dry")
    local base = require("swara.config").get().release_base_url
    t.eq(base:sub(1, 8), "file:///", "the download address")
    t.eq(vim.uv.fs_stat(base:sub(8)), nil, "nothing is at " .. base)
  end,

  ["every Swara key draws its own icon in which-key"] = function(t)
    swara()
    local wk_icons = require("which-key.icons")
    local buf = vim.api.nvim_create_buf(false, true)
    local ok, err = pcall(function()
      require("swara.keys").attach(buf)
      local keys = vim.api.nvim_buf_get_keymap(buf, "n")
      t.eq(#keys, 6, "Swara's six keys")
      for _, k in ipairs(keys) do
        local want = I.key(k.desc)
        t.ok(want ~= nil, ("%q has a line in M.keys"):format(k.desc))
        local icon = wk_icons.get({ desc = k.desc })
        t.eq(icon, want and want.icon, ("which-key draws the database's icon for %q"):format(k.desc))
      end
    end)
    vim.api.nvim_buf_delete(buf, { force = true })
    if not ok then
      error(err, 0)
    end
  end,
}
