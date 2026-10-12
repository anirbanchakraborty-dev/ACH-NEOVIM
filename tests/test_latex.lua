-- LaTeX. No test opens Skim or runs LaTeX. Stand-in shell scripts named
-- latexmk and osascript sit first on PATH and write their arguments to a
-- file, so a test reads exactly what VimTeX would have run. The inverse search
-- test starts a second Neovim nobody can see, as Skim does.
local I = require("ach.icons")

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name) return found[name] and 1 or 0 end
end

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level) said[#said + 1] = { msg = msg, level = level } end,
    },
  }, body)
  return said
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- Writes a shell script called name into bin that adds each of its arguments,
-- one to a line, to the file record, then runs line.
local function stand_in(bin, name, record, line)
  vim.fn.mkdir(bin, "p")
  local path = bin .. "/" .. name
  vim.fn.writefile({
    "#!/bin/sh",
    ("printf '%%s\\n' \"$@\" >> '%s'"):format(record),
    line or "",
  }, path)
  vim.uv.fs_chmod(path, tonumber("755", 8))
end

-- What a stand-in has written to record, or "" when it never ran.
local function recorded(record)
  local f = io.open(record)
  if not f then
    return ""
  end
  local text = f:read("*a")
  f:close()
  return text
end

-- Writes a one-page document to dir/main.tex and returns its path. On line 3
-- the formula $x^2$ runs from column 8 to column 12.
local function write_tex(dir)
  local tex = dir .. "/main.tex"
  vim.fn.writefile({
    "\\documentclass{article}",
    "\\begin{document}",
    "Hello, $x^2$.",
    "\\section{One}",
    "\\end{document}",
  }, tex)
  return tex
end

-- Runs body with fn as the build hook, then puts the previous hook back, even
-- when body fails.
local function hooked(fn, body)
  local latex = require("ach.latex")
  local previous = latex.build_with(fn)
  local ok, err = pcall(body)
  latex.build_with(previous)
  if not ok then
    error(err, 0)
  end
end

-- Every key on buf whose action is one of VimTeX's, with the name of that
-- action, such as vimtex-info. A mapping whose left side is itself a <Plug>
-- name is VimTeX's own wiring, which nobody presses and which-key never
-- shows: <Plug>(vimtex-env-surround-line) runs the surround operator on _.
local function vimtex_keys(buf)
  local found = {}
  for _, mode in ipairs({ "n", "x", "o", "i" }) do
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      local name = (m.rhs or ""):match("^<[Pp][Ll][Uu][Gg]>%((vimtex%-.-)%)")
      if name and not m.lhs:lower():find("^<plug>") then
        found[#found + 1] = { mode = mode, lhs = m.lhs, name = name, desc = m.desc }
      end
    end
  end
  return found
end

-- VimTeX's build status for buf's document: 1 while a build runs, 2 when it
-- succeeded and 3 when it failed.
local function build_status(buf)
  return vim.api.nvim_buf_call(
    buf,
    function() return vim.fn.eval("get(get(get(b:, 'vimtex', {}), 'compiler', {}), 'status', -1)") end
  )
end

return {
  ["VimTeX is set up for Skim, with its build folder under the cache"] = function(t)
    t.eq(vim.g.vimtex_view_method, "skim", "the viewer")
    t.eq(vim.g.vimtex_view_skim_sync, 1, "Skim follows the cursor after each build")
    t.eq(vim.g.vimtex_view_skim_activate, 1, "Skim comes to the front")
    t.eq(vim.g.vimtex_view_skim_reading_bar, 1, "Skim marks the line with its reading bar")
    t.eq(vim.g.vimtex_mappings_disable, { n = { "K" } }, "K is left to the language server")
    t.eq(vim.fn.exists(":VimtexInverseSearch"), 2, "the inverse search command exists before any LaTeX file opens")
    local latex = require("ach.latex")
    local cache = vim.fn.stdpath("cache") .. "/latex/"
    local aux = latex.aux_dir("/Users/someone/My Book")
    t.eq(aux:sub(1, #cache), cache, "the build folder is under the cache")
    t.ok(not aux:find(" ", 1, true), ("%s has no space"):format(aux))
    t.ok(aux:find("/My-Book-", 1, true), ("%s names the project"):format(aux))
    t.ok(latex.aux_dir("/a/book") ~= latex.aux_dir("/b/book"), "two projects with the same name get different folders")
  end,

  ["a LaTeX file gets both highlighters, and VimTeX's indentation"] = function(t)
    local ok, added = pcall(vim.treesitter.language.add, "latex")
    if not (ok and added) then
      t.skip("the latex parser is not installed; scripts/check --full installs it")
    end
    tidy(function()
      vim.cmd.edit(vim.fn.fnameescape(write_tex(t.tmpdir())))
      local buf = vim.api.nvim_get_current_buf()
      t.eq(vim.bo[buf].filetype, "tex", "the file type")
      t.ok(vim.treesitter.highlighter.active[buf] ~= nil, "tree-sitter colours the file")
      t.eq(vim.b[buf].current_syntax, "tex", "Vim's LaTeX syntax is loaded too")
      t.eq(vim.bo[buf].indentexpr, "VimtexIndentExpr()", "VimTeX indents the file")
      t.eq(vim.fn["vimtex#syntax#in_mathzone"](3, 9), 1, "VimTeX sees the x of $x^2$ as math")
      t.eq(vim.fn["vimtex#syntax#in_mathzone"](3, 2), 0, "and the e of Hello as text")
    end)
  end,

  ["every VimTeX key has a description and an icon, and ] ] stays VimTeX's"] = function(t)
    local latex = require("ach.latex")
    local added = {}
    tidy(function()
      with({
        {
          require("which-key"),
          "add",
          function(specs) vim.list_extend(added, specs) end,
        },
      }, function() vim.cmd.edit(vim.fn.fnameescape(write_tex(t.tmpdir()))) end)
      local buf = vim.api.nvim_get_current_buf()
      local keys = vimtex_keys(buf)
      t.ok(#keys > 0, "VimTeX set its keys")
      local seen = {}
      for _, k in ipairs(keys) do
        local want = latex.describe[k.name]
        t.ok(want ~= nil, ("%s, on %s in mode %s, has a description"):format(k.name, k.lhs, k.mode))
        t.eq(k.desc, want, ("%s in mode %s"):format(k.lhs, k.mode))
        t.ok(I.key(want) ~= nil, ("%q has a line in M.keys"):format(want))
        seen[k.name] = true
      end
      for name in pairs(latex.describe) do
        t.ok(seen[name], ("%s is on a key"):format(name))
      end

      local build = vim.fn.maparg("<leader>cb", "n", false, true)
      t.eq(build.buffer, 1, "Space c b belongs to the LaTeX buffer")
      t.eq(build.desc, "Build Document", "Space c b")
      t.ok(I.key(build.desc) ~= nil, '"Build Document" has a line in M.keys')
      local group = { "<localleader>l", group = "latex", icon = I.group("latex"), buffer = buf, mode = { "n", "x" } }
      t.ok(
        vim.iter(added):any(function(spec) return vim.deep_equal(spec, group) end),
        "which-key names Backslash l latex, with its icon"
      )

      -- A language server that offers references, as texlab does.
      require("ach.lsp").attach(buf, {
        supports_method = function(_, method) return method == "textDocument/documentHighlight" end,
      })
      t.eq(vim.fn.maparg("]]", "n", false, true).desc, "Next Section Start", "] ] after a language server attaches")
      t.eq(vim.fn.maparg("[[", "n", false, true).desc, "Prev Section Start", "[ [ after a language server attaches")
    end)
  end,

  ["Space c b with no hook builds once with latexmk into the cache, and Skim shows the PDF"] = function(t)
    local latex = require("ach.latex")
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    stand_in(bin, "latexmk", dir .. "/latexmk.args", ": > main.pdf")
    stand_in(bin, "osascript", dir .. "/osascript.args", "echo net.sourceforge.skim-app")
    -- VimTeX makes the build folder when the build starts, in the real
    -- cache, so it is removed afterwards whether or not the test passed.
    local ok, err = pcall(tidy, function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
        local buf = vim.api.nvim_get_current_buf()
        press("<leader>cb")
        vim.wait(10000, function() return build_status(buf) >= 2 end, 20)
        t.eq(build_status(buf), 2, "the build finished and succeeded")
        local args = vim.split(vim.trim(recorded(dir .. "/latexmk.args")), "\n")
        t.ok(vim.tbl_contains(args, "-synctex=1"), "latexmk writes the file that links the PDF to the source")
        t.ok(vim.tbl_contains(args, "-emulate-aux-dir"), "latexmk keeps its build files apart")
        t.ok(vim.tbl_contains(args, "-auxdir=" .. latex.aux_dir(dir)), "in the project's folder under the cache")
        t.eq(args[#args], "main.tex", "latexmk builds the main file")
        t.ok(
          vim.wait(
            10000,
            function()
              return recorded(dir .. "/osascript.args"):find(('Path("%s/main.pdf")'):format(dir), 1, true) ~= nil
            end,
            20
          ),
          "Skim is asked to show the PDF"
        )
      end)
    end)
    vim.fn.delete(latex.aux_dir(dir), "rf")
    if not ok then
      error(err, 0)
    end
  end,

  ["a build hook's command runs in a terminal; returning nothing falls back, and failing runs nothing"] = function(t)
    require("ach.latex")
    local dir = t.tmpdir()
    local opened = {}
    tidy(function()
      vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
      with({
        {
          Snacks.terminal,
          "open",
          function(cmd, opts) opened[#opened + 1] = { cmd = cmd, opts = opts } end,
        },
      }, function()
        hooked(
          function(file) return { "scripts/build.sh", vim.fs.basename(file) }, dir .. "/book" end,
          function() press("<leader>cb") end
        )
        t.eq(#opened, 1, "one terminal opened")
        t.eq(opened[1].cmd, { "scripts/build.sh", "main.tex" }, "running the hook's command on the main file")
        t.eq(opened[1].opts.cwd, dir .. "/book", "in the hook's folder")
        t.eq(opened[1].opts.interactive, false, "and it stays open when the build ends, to be read")

        local said = notices(function()
          with({ { vim.fn, "executable", only({}) } }, function()
            hooked(function() end, function() press("<leader>cb") end)
          end)
        end)
        t.eq(said, {
          {
            msg = "MacTeX is not installed. Install it with: brew install --cask mactex",
            level = vim.log.levels.WARN,
          },
        }, "a hook that returns nothing falls back to latexmk, which is missing here")
        t.eq(#opened, 1, "and no terminal opened")

        said = notices(function()
          hooked(function() error("no build script here") end, function() press("<leader>cb") end)
        end)
        t.eq(#said, 1, "a hook that fails prints one line")
        t.eq(said[1].level, vim.log.levels.ERROR, "as an error")
        t.ok(vim.startswith(said[1].msg, "The LaTeX build hook failed: "), "saying the hook failed")
        t.ok(said[1].msg:find("no build script here", 1, true), "and why")
        t.eq(#opened, 1, "and nothing ran")
      end)
    end)
  end,

  ["with no latexmk, Space c b prints the Homebrew line and runs nothing"] = function(t)
    require("ach.latex")
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    stand_in(bin, "latexmk", dir .. "/latexmk.args")
    tidy(function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
        local said = notices(function()
          with({ { vim.fn, "executable", only({}) } }, function() press("<leader>cb") end)
        end)
        t.eq(
          vim.tbl_map(function(n) return n.msg end, said),
          { "MacTeX is not installed. Install it with: brew install --cask mactex" },
          "one line, saying what to run"
        )
        vim.wait(500)
        t.eq(recorded(dir .. "/latexmk.args"), "", "and latexmk never ran")
      end)
    end)
  end,

  ["View PDF opens Skim at the cursor's line, with the reading bar"] = function(t)
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    local record = dir .. "/osascript.args"
    stand_in(bin, "latexmk", dir .. "/latexmk.args")
    stand_in(bin, "osascript", record, "echo net.sourceforge.skim-app")
    vim.fn.writefile({}, dir .. "/main.pdf")
    tidy(function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        local tex = write_tex(dir)
        vim.cmd.edit(vim.fn.fnameescape(tex))
        vim.api.nvim_win_set_cursor(0, { 3, 0 })
        vim.cmd("VimtexView")
        t.ok(
          vim.wait(10000, function() return recorded(record):find("app.open(theFile);", 1, true) ~= nil end, 20),
          "Skim is asked to open the PDF"
        )
        local script = recorded(record)
        for _, want in ipairs({
          ('Path("%s/main.pdf")'):format(dir),
          "app.activate();",
          "app.texLines[2]",
          ('from: Path("%s")'):format(tex),
          "showingReadingBar: true",
        }) do
          t.ok(script:find(want, 1, true), ("the script Skim runs contains %s"):format(want))
        end
      end)
    end)
  end,

  ["Skim's inverse search moves this Neovim's cursor to the line clicked"] = function(t)
    -- VimTeX lists this Neovim's address when a LaTeX file opens, so the
    -- address must exist first.
    if vim.v.servername == "" then
      vim.fn.serverstart()
    end
    tidy(function()
      local tex = write_tex(t.tmpdir())
      vim.cmd.edit(vim.fn.fnameescape(tex))
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      local exited
      -- The command Skim runs, less the path to Neovim. The trailing qa! ends
      -- the second Neovim even when the command is unknown.
      vim.system({
        vim.v.progpath,
        "--headless",
        "-u",
        t.root .. "/init.lua",
        "-c",
        ("VimtexInverseSearch 3 '%s'"):format(tex),
        "-c",
        "qa!",
      }, { text = true }, function(out) exited = out end)
      t.ok(vim.wait(60000, function() return exited ~= nil end, 50), "the second Neovim quits")
      t.ok(
        vim.wait(5000, function() return vim.api.nvim_win_get_cursor(0)[1] == 3 end, 20),
        "the cursor moved to line 3"
      )
      t.eq(exited.code, 0, "the second Neovim's exit code")
    end)
  end,
}
