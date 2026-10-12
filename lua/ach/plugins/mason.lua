-- mason.nvim installs language servers, formatters, linters and debuggers
-- into Neovim's data folder and puts them on the path. lua/ach/install.lua
-- decides what to install and when, and lua/ach/masonlock.lua pins each
-- package's version in mason-lock.json, which mason.nvim has no notion of.
local I = require("ach.icons")

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" },
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    init = function()
      vim.api.nvim_create_user_command("AchMasonLock", function()
        local added = require("ach.masonlock").adopt()
        vim.notify(
          #added == 0 and "mason-lock.json already pins every installed package"
            or ("Pinned %s in mason-lock.json"):format(table.concat(added, ", "))
        )
      end, { desc = "Pin each installed Mason package that mason-lock.json does not list" })
      vim.api.nvim_create_user_command("AchMasonUpdate", function()
        vim.notify("Updating Mason packages")
        require("ach.masonlock").update(function(changed, failed)
          local lines =
            { #changed == 0 and "Every Mason package is up to date" or ("Updated " .. table.concat(changed, ", ")) }
          if #failed > 0 then
            lines[#lines + 1] = "Could not update " .. table.concat(failed, ", ")
          end
          vim.notify(table.concat(lines, "\n"), #failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
        end)
      end, { desc = "Update every installed Mason package and move its pin" })
    end,
    opts = {
      ui = {
        icons = {
          package_installed = I.mason.installed,
          package_pending = I.mason.pending,
          package_uninstalled = I.mason.uninstalled,
        },
      },
    },
  },
}
