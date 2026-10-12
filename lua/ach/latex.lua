-- LaTeX: VimTeX's settings, the build key, and a description for each of
-- VimTeX's own keys. VimTeX builds with latexmk into a folder under Neovim's
-- cache, shows the PDF in Skim, and moves the cursor when Skim is
-- Command-Shift-clicked. A project can give Space c b its own command
-- through build_with.
local need = require("ach.need")

local M = {}

-- The project's build command, set by build_with, or nil.
---@type ach.latex.hook?
local hook

-- The folder latexmk writes its build files to for the project in root: one
-- per project under Neovim's cache, named after the project with eight
-- characters of a hash of its path, so two projects with the same name stay
-- apart. Anything but a letter, digit, dot, dash or underscore becomes a
-- dash, because the path goes on a shell command line.
---@param root string
---@return string
function M.aux_dir(root)
  local name = vim.fs.basename(root):gsub("[^%w._-]", "-")
  return ("%s/latex/%s-%s"):format(vim.fn.stdpath("cache"), name, vim.fn.sha256(root):sub(1, 8))
end

-- VimTeX's settings, as global variables. The plugin spec sets them before
-- VimTeX loads, because VimTeX reads them then.
---@return table<string, any>
function M.globals()
  return {
    vimtex_view_method = "skim",
    -- After each build Skim moves to the cursor's line, marks it with the
    -- reading bar, and comes to the front.
    vimtex_view_skim_sync = 1,
    vimtex_view_skim_activate = 1,
    vimtex_view_skim_reading_bar = 1,
    -- K stays the language server's hover, as in every other language.
    vimtex_mappings_disable = { n = { "K" } },
    -- The error list opens after a failed build, not for warnings alone.
    vimtex_quickfix_open_on_warning = 0,
    -- The build files go under the cache. A project whose .latexmkrc names
    -- its own folder keeps it, because VimTeX gives that file the last word.
    vimtex_compiler_latexmk = {
      aux_dir = function(info) return M.aux_dir(info.root) end,
    },
  }
end

-- Sets the project's build command, or clears it with nil, and returns the
-- one it replaces. fn receives the main file's path and returns the command,
-- as a string or a list, and the folder to run it in, which defaults to the
-- main file's. Returning nothing falls back to latexmk. A project sets it in
-- its own .nvim.lua, which Neovim runs only once its owner has trusted it.
---@alias ach.latex.hook fun(file: string): (string|string[])?, string?
---@param fn? ach.latex.hook
---@return ach.latex.hook?
function M.build_with(fn)
  vim.validate("fn", fn, "function", true)
  local previous = hook
  hook = fn
  return previous
end

-- The document's main file, which VimTeX works out by following \input and
-- the like back to the file with \documentclass, so a chapter builds the
-- whole book. buf's own file when VimTeX has not looked at buf.
local function main_file(buf)
  local main = vim.api.nvim_buf_call(buf, function() return vim.fn.eval("get(get(b:, 'vimtex', {}), 'tex', '')") end)
  return main ~= "" and main or vim.api.nvim_buf_get_name(buf)
end

-- Runs cmd in cwd in a terminal along the bottom, which stays open when the
-- command ends so its output can be read.
---@param cmd string|string[]
---@param cwd string
function M.run(cmd, cwd) Snacks.terminal.open(cmd, { cwd = cwd, interactive = false, win = { position = "bottom" } }) end

-- Builds buf's document: with the project's hook when it gives a command,
-- otherwise once with latexmk. A hook that fails is reported and nothing
-- runs.
---@param buf integer
function M.build(buf)
  local file = main_file(buf)
  if hook then
    local ok, cmd, cwd = pcall(hook, file)
    if not ok then
      vim.notify(("The LaTeX build hook failed: %s"):format(cmd), vim.log.levels.ERROR)
      return
    end
    if cmd then
      M.run(cmd, cwd or vim.fs.dirname(file))
      return
    end
  end
  if need.have("latexmk") then
    vim.api.nvim_buf_call(buf, function() vim.cmd("VimtexCompileSS") end)
  end
end

-- A description for each of VimTeX's actions that VimTeX puts on a key by
-- default, keyed by the action's name. Actions VimTeX leaves off every key,
-- or puts on one only for another viewer, have none.
M.describe = {
  -- About VimTeX itself.
  ["vimtex-info"] = "VimTeX Info",
  ["vimtex-info-full"] = "VimTeX Full Info",
  ["vimtex-reload"] = "Reload VimTeX",
  ["vimtex-reload-state"] = "Reload VimTeX State",
  ["vimtex-toggle-main"] = "Toggle Main File",
  ["vimtex-log"] = "VimTeX Log",
  ["vimtex-context-menu"] = "Context Menu",
  -- Building.
  ["vimtex-compile"] = "Compile Continuously",
  ["vimtex-compile-ss"] = "Compile Once",
  ["vimtex-compile-output"] = "Compiler Output",
  ["vimtex-compile-selected"] = "Compile Selection",
  ["vimtex-stop"] = "Stop Compiling",
  ["vimtex-stop-all"] = "Stop All Compiling",
  ["vimtex-errors"] = "Compile Errors",
  ["vimtex-clean"] = "Clean Build Files",
  ["vimtex-clean-full"] = "Clean All Build Files",
  ["vimtex-status"] = "Compiler Status",
  ["vimtex-status-all"] = "All Compilers Status",
  -- Contents, viewing and shortcuts.
  ["vimtex-toc-open"] = "Table of Contents",
  ["vimtex-toc-toggle"] = "Toggle Table of Contents",
  ["vimtex-view"] = "View PDF",
  ["vimtex-imaps-list"] = "Insert Shortcuts",
  -- Environments and formulas.
  ["vimtex-env-delete"] = "Delete Surrounding Environment",
  ["vimtex-env-change"] = "Change Surrounding Environment",
  ["vimtex-env-toggle"] = "Toggle Environment",
  ["vimtex-env-toggle-star"] = "Toggle Starred Environment",
  ["vimtex-env-delete-math"] = "Delete Surrounding Math",
  ["vimtex-env-change-math"] = "Change Surrounding Math",
  ["vimtex-env-toggle-math"] = "Toggle Inline or Display Math",
  ["vimtex-env-surround-line"] = "Surround Line with Environment",
  ["vimtex-env-surround-visual"] = "Surround with Environment",
  -- Commands.
  ["vimtex-cmd-delete"] = "Delete Surrounding Command",
  ["vimtex-cmd-change"] = "Change Surrounding Command",
  ["vimtex-cmd-toggle-star"] = "Toggle Starred Command",
  ["vimtex-cmd-toggle-frac"] = "Toggle Fraction",
  ["vimtex-cmd-toggle-break"] = "Toggle Line Break",
  ["vimtex-cmd-create"] = "Create Command",
  -- Brackets.
  ["vimtex-delim-delete"] = "Delete Surrounding Delimiters",
  ["vimtex-delim-change-math"] = "Change Surrounding Delimiters",
  ["vimtex-delim-toggle-modifier"] = "Toggle Delimiter Size",
  ["vimtex-delim-toggle-modifier-reverse"] = "Toggle Delimiter Size Back",
  ["vimtex-delim-close"] = "Close Environment or Delimiter",
  ["vimtex-delim-add-modifiers"] = "Size Delimiters to Content",
  -- Motions.
  ["vimtex-%"] = "Matching Pair",
  ["vimtex-]]"] = "Next Section Start",
  ["vimtex-]["] = "Next Section End",
  ["vimtex-[["] = "Prev Section Start",
  ["vimtex-[]"] = "Prev Section End",
  ["vimtex-]m"] = "Next Environment Start",
  ["vimtex-]M"] = "Next Environment End",
  ["vimtex-[m"] = "Prev Environment Start",
  ["vimtex-[M"] = "Prev Environment End",
  ["vimtex-]n"] = "Next Math Start",
  ["vimtex-]N"] = "Next Math End",
  ["vimtex-[n"] = "Prev Math Start",
  ["vimtex-[N"] = "Prev Math End",
  ["vimtex-]r"] = "Next Frame Start",
  ["vimtex-]R"] = "Next Frame End",
  ["vimtex-[r"] = "Prev Frame Start",
  ["vimtex-[R"] = "Prev Frame End",
  ["vimtex-]/"] = "Next Comment Start",
  ["vimtex-]*"] = "Next Comment End",
  ["vimtex-[/"] = "Prev Comment Start",
  ["vimtex-[*"] = "Prev Comment End",
  -- Text objects.
  ["vimtex-ic"] = "Inside Command",
  ["vimtex-ac"] = "Around Command",
  ["vimtex-id"] = "Inside Delimiters",
  ["vimtex-ad"] = "Around Delimiters",
  ["vimtex-ie"] = "Inside Environment",
  ["vimtex-ae"] = "Around Environment",
  ["vimtex-i$"] = "Inside Math",
  ["vimtex-a$"] = "Around Math",
  ["vimtex-iP"] = "Inside Section",
  ["vimtex-aP"] = "Around Section",
  ["vimtex-im"] = "Inside Item",
  ["vimtex-am"] = "Around Item",
}

-- The modes VimTeX sets keys in.
local modes = { "n", "x", "o", "i" }

-- Gives each of VimTeX's keys on buf its description, so which-key shows it
-- with its icon, and adds the build key and the name of the Backslash l menu.
-- VimTeX sets its keys without descriptions, so each is set again here with
-- the same action. It runs on VimtexEventInitPost, which VimTeX fires once
-- its keys are set.
---@param buf integer
function M.attach(buf)
  for _, mode in ipairs(modes) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      -- VimTeX writes <plug> in lower case; Neovim may report it as <Plug>.
      local name = (map.rhs or ""):match("^<[Pp][Ll][Uu][Gg]>%((vimtex%-.-)%)")
      local desc = name and M.describe[name]
      if desc then
        vim.keymap.set(mode, map.lhs, map.rhs, {
          buf = buf,
          remap = true,
          silent = map.silent == 1,
          nowait = map.nowait == 1,
          desc = desc,
        })
      end
    end
  end
  vim.keymap.set("n", "<leader>cb", function() M.build(buf) end, { buf = buf, desc = "Build Document" })
  require("which-key").add({
    {
      "<localleader>l",
      group = "latex",
      icon = require("ach.icons").group("latex"),
      buffer = buf,
      mode = { "n", "x" },
    },
  })
end

return M
