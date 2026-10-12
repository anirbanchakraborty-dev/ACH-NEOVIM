-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/lang/tex.lua.
-- LaTeX: VimTeX builds with latexmk, shows the PDF in Skim, and follows
-- Skim's clicks back to the source. Its settings, keys and build hook live in
-- ach.latex.
return {
  {
    "lervag/vimtex",
    -- Loaded at start rather than on a LaTeX file, because the Neovim that
    -- Skim starts for an inverse search opens no LaTeX file and still needs
    -- the VimtexInverseSearch command.
    lazy = false,
    -- VimTeX reads its settings when it loads, so they are set first.
    init = function()
      for name, value in pairs(require("ach.latex").globals()) do
        vim.g[name] = value
      end
    end,
    config = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ach_latex", { clear = true }),
        pattern = "VimtexEventInitPost",
        callback = function() require("ach.latex").attach(vim.api.nvim_get_current_buf()) end,
      })
    end,
  },
}
