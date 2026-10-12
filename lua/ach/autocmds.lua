-- Autocommands that no plugin owns. Each lives in its own ach_* group so a
-- reload replaces rather than duplicates it.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/autocmds.lua.
local M = {}

function M.group(name) return vim.api.nvim_create_augroup("ach_" .. name, { clear = true }) end

-- Briefly highlight what was just yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = M.group("highlight_yank"),
  callback = function() vim.hl.on_yank() end,
})

-- Keep splits equal when the terminal window is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = M.group("resize_splits"),
  callback = function()
    local current = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current)
  end,
})

-- Return to the last place edited in a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = M.group("last_place"),
  callback = function(event)
    local exclude = { gitcommit = true }
    local buf = event.buf
    if exclude[vim.bo[buf].filetype] or vim.b[buf].ach_last_place then
      return
    end
    vim.b[buf].ach_last_place = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close throwaway windows with q.
vim.api.nvim_create_autocmd("FileType", {
  group = M.group("close_with_q"),
  pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth", "grug-far", "dap-float" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, desc = "Close Window" })
  end,
})

-- Create missing parent folders when a file is first saved.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = M.group("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

return M
