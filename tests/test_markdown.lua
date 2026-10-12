-- Markdown. No test opens a browser. vim.ui.open, which live-preview calls to
-- open one, is replaced by a recorder, and the tests talk to the preview
-- server the way a browser would, over a plain connection to 127.0.0.1.

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

-- A port nothing listens on. Binding port 0 asks the system for a free one;
-- the test reads which it chose and lets it go.
local function free_port()
  local tcp = assert(vim.uv.new_tcp())
  assert(tcp:bind("127.0.0.1", 0))
  local port = tcp:getsockname().port
  tcp:close()
  return port
end

-- Sends a request made of lines to the server on port, and waits up to three
-- seconds for the server to close the connection or for the reply to contain
-- want. Returns the reply.
local function fetch(port, lines, want)
  local tcp = assert(vim.uv.new_tcp())
  local reply, over = "", false
  tcp:connect("127.0.0.1", port, function(err)
    if err then
      over = true
      return
    end
    tcp:read_start(function(read_err, chunk)
      if chunk then
        reply = reply .. chunk
      end
      if read_err or not chunk then
        over = true
      end
    end)
    tcp:write(table.concat(lines, "\r\n") .. "\r\n\r\n")
  end)
  vim.wait(3000, function() return over or (want ~= nil and reply:find(want, 1, true) ~= nil) end, 20)
  if not tcp:is_closing() then
    tcp:close()
  end
  return reply
end

-- Asks for path the way a browser on this Mac would.
local function get(port, path) return fetch(port, { "GET " .. path .. " HTTP/1.1", "Host: 127.0.0.1:" .. port }) end

-- The three-digit status at the start of a reply, such as "404".
local function status(reply) return reply:match("^HTTP/1%.1 (%d%d%d)") end

-- The options lazy.nvim passes to a plugin's setup, merged from every spec
-- that names the plugin.
local function opts_of(name)
  local plugin = assert(require("lazy.core.config").plugins[name], name .. " is not in the plugin list")
  return require("lazy.core.plugin").values(plugin, "opts", false)
end

-- A folder holding a secret and, beneath it, the site the preview serves: a
-- page, and a link pointing back up at the secret. Returns the folder and the
-- page.
local function site(t)
  local dir = t.tmpdir()
  vim.fn.mkdir(dir .. "/site", "p")
  vim.fn.writefile({ "SECRET" }, dir .. "/secret.txt")
  vim.fn.writefile({ "# Hello from the preview" }, dir .. "/site/page.md")
  assert(vim.uv.fs_symlink("../secret.txt", dir .. "/site/link.txt"))
  return dir, dir .. "/site/page.md"
end

-- Opens page and presses Space c p, with the preview on a free port and the
-- browser replaced by a recorder, then runs body with the port and the list
-- of addresses the browser was sent to. Stops the server afterwards, even
-- when body fails.
local function previewing(page, body)
  local port, opened = free_port(), {}
  local config = require("livepreview.config").config
  tidy(function()
    with({
      { config, "port", port },
      {
        vim.ui,
        "open",
        function(url) opened[#opened + 1] = url end,
      },
    }, function()
      local ok, err = pcall(function()
        vim.cmd.edit(page)
        press("<leader>cp")
        body(port, opened)
      end)
      require("livepreview").close()
      if not ok then
        error(err, 0)
      end
    end)
  end)
end

return {
  ["render-markdown leaves formulas to snacks and suggests through blink, and the preview stays local"] = function(t)
    local o = opts_of("render-markdown.nvim")
    t.eq(o.latex.enabled, false, "formulas are drawn by snacks alone")
    t.eq(o.completions.blink.enabled, true, "suggestions go through blink")
    t.ok(o.checkbox == nil or o.checkbox.enabled ~= false, "checkboxes are drawn")
    t.eq(o.file_types, { "markdown", "markdown.mdx", "rmd", "quarto" }, "the file types it draws")
    local lp = opts_of("live-preview.nvim")
    t.eq(lp.address, "127.0.0.1", "the preview listens on this Mac alone")
    t.eq(lp.dynamic_root, true, "and serves the file's own folder")
  end,

  ["headings are drawn in the editor, and Space u m turns the drawing off and on"] = function(t)
    -- Neovim ships the markdown parser, so this needs no install. The heading
    -- is below the line the cursor opens on, because render-markdown shows
    -- the cursor's own line as plain text, so it can be edited.
    local file = t.tmpdir() .. "/notes.md"
    vim.fn.writefile({ "Some text.", "", "# Heading" }, file)
    local ns = vim.api.nvim_create_namespace("render-markdown.nvim")
    local function marks() return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) end
    tidy(function()
      local ok, err = pcall(function()
        vim.cmd.edit(file)
        vim.wait(2000, function() return marks() > 0 end, 20)
        t.ok(marks() > 0, "the heading is drawn")
        press("<leader>um")
        vim.wait(2000, function() return marks() == 0 end, 20)
        t.eq(marks(), 0, "Space u m clears the drawing")
        press("<leader>um")
        vim.wait(2000, function() return marks() > 0 end, 20)
        t.ok(marks() > 0, "and pressed again draws it again")
      end)
      -- Leaves the drawing on for the tests after this one.
      pcall(function() require("render-markdown").set(true) end)
      if not ok then
        error(err, 0)
      end
    end)
  end,

  ["a Markdown file gets render-markdown's suggestions as well as blink's own"] = function(t)
    local file = t.tmpdir() .. "/notes.md"
    vim.fn.writefile({ "- [ ] a task" }, file)
    tidy(function()
      vim.cmd.edit(file)
      local lib = require("blink.cmp.sources.lib")
      vim.wait(2000, function() return vim.tbl_contains(lib.get_enabled_provider_ids("default"), "markdown") end, 20)
      local ids = lib.get_enabled_provider_ids("default")
      for _, id in ipairs({ "markdown", "lsp", "path", "snippets", "buffer" }) do
        t.ok(vim.tbl_contains(ids, id), id .. " is offered")
      end
    end)
  end,

  ["snacks draws pictures and formulas in Markdown"] = function(t)
    t.eq(Snacks.image.config.enabled, true, "images are on")
    t.eq(Snacks.image.config.math.enabled, true, "and so are formulas")
    t.ok(vim.tbl_contains(Snacks.image.langs(), "markdown"), "Markdown is one of the languages it reads")
  end,

  ["formulas and pictures name the programs they need, once, and only where pictures can be shown"] = function(t)
    local P = require("ach.preview")
    -- What check_drawing says in a terminal named term_program, with uis as
    -- the screens attached and none of the three programs installed.
    local function check(term_program, uis, force)
      local said = notices(function()
        with({
          { vim.env, "TERM_PROGRAM", term_program },
          { vim.env, "TERM", "xterm-256color" },
          {
            vim.api,
            "nvim_list_uis",
            function() return uis end,
          },
          { vim.fn, "executable", only({}) },
        }, function() P.check_drawing(force) end)
      end)
      return vim.tbl_map(function(n) return n.msg end, said)
    end
    t.eq(check("ghostty", { {} }, true), {
      "ImageMagick is not installed. Install it with: brew install imagemagick",
      "MacTeX is not installed. Install it with: brew install --cask mactex",
      "Ghostscript is not installed. Install it with: brew install ghostscript",
    }, "Ghostty, with none of the three")
    t.eq(check("ghostty", { {} }), {}, "said once per Neovim")
    t.eq(check("Apple_Terminal", { {} }, true), {}, "macOS Terminal shows no pictures, so it needs none of them")
    t.eq(check("ghostty", {}, true), {}, "nor does a Neovim with no screen")
  end,

  ["Space c p serves the file on 127.0.0.1 alone and opens it in the browser, and pressed again stops"] = function(t)
    local _, page = site(t)
    previewing(page, function(port, opened)
      t.eq(opened, { ("http://127.0.0.1:%d/page.md"):format(port) }, "the browser is sent to the file on this Mac")
      local reply = get(port, "/page.md")
      t.eq(status(reply), "200", "the page is served")
      t.ok(reply:find("Hello from the preview", 1, true) ~= nil, "with the file's text")

      -- Every socket this Neovim listens on at port, one address per line,
      -- each line starting with n. -a makes lsof require all three conditions.
      local argv = { "lsof", "-nP", "-a", "-p", tostring(vim.fn.getpid()), "-iTCP:" .. port, "-sTCP:LISTEN", "-Fn" }
      local r = vim.system(argv, { text = true }):wait()
      local names = {}
      for line in vim.gsplit(r.stdout or "", "\n", { trimempty = true }) do
        if line:sub(1, 1) == "n" then
          names[#names + 1] = line
        end
      end
      t.eq(names, { "n127.0.0.1:" .. port }, "one listening socket, on the address the Mac uses for itself")

      press("<leader>cp")
      t.eq(require("livepreview").is_running(), false, "Space c p again stops the preview")
    end)
  end,

  ["the preview refuses every path that leads outside its folder"] = function(t)
    local dir, page = site(t)
    previewing(page, function(port)
      local climb = ("%2e%2e/"):rep(30)
      local refused = {
        "/%2e%2e/secret.txt",
        "/../secret.txt",
        "/" .. climb .. "etc/passwd",
        "/link.txt",
        "/page.md%00",
        "/live-preview.nvim/" .. climb .. dir:sub(2) .. "/secret.txt",
        "/live-preview.nvim/lua/livepreview/utils.lua",
      }
      for _, path in ipairs(refused) do
        local reply = get(port, path)
        t.eq(status(reply), "404", path)
        t.ok(
          not reply:find("SECRET", 1, true) and not reply:find("root:", 1, true),
          path .. " shows nothing of the file"
        )
      end
      local css = get(port, "/live-preview.nvim/static/katex/katex.min.css")
      t.eq(status(css), "200", "the page's own styles are still served")
    end)
  end,

  ["the preview answers only the pages it served itself"] = function(t)
    local _, page = site(t)
    previewing(page, function(port)
      local here = "127.0.0.1:" .. port
      local renamed = fetch(port, { "GET /page.md HTTP/1.1", "Host: attacker.example:" .. port })
      t.eq(status(renamed), "404", "a site that pointed its own name at this Mac")
      t.ok(not renamed:find("Hello", 1, true), "learns nothing of the page")

      -- Asks to turn the connection into a WebSocket, as the preview page
      -- does, from origin or from no site at all.
      local function upgrade(origin)
        local lines = {
          "GET / HTTP/1.1",
          "Host: " .. here,
          "Upgrade: websocket",
          "Connection: Upgrade",
          -- The sample key from the WebSocket standard, RFC 6455.
          "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
          "Sec-WebSocket-Version: 13",
        }
        if origin then
          lines[#lines + 1] = "Origin: " .. origin
        end
        return fetch(port, lines, "101 Switching Protocols")
      end
      t.eq(status(upgrade("https://attacker.example")), "404", "a WebSocket from another site")
      t.eq(status(upgrade(nil)), "404", "a WebSocket that names no site")
      t.eq(status(upgrade("http://" .. here)), "101", "the preview page's own WebSocket")
    end)
  end,
}
