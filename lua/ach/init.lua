-- Loads the configuration in order. Keymaps wait for VeryLazy, after the first
-- screen has drawn.
if not package.loaded["lazy"] then
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      vim.g.did_very_lazy = true
    end,
  })
end
