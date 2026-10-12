-- Claude Code. No test starts the claude program. The server tests start
-- claudecode's server and talk to it through a client written here, which
-- sends the request Claude Code sends. The panel test runs `sleep 60` in the
-- panel in claude's place. scripts/check points CLAUDE_CONFIG_DIR at a scratch
-- folder, so every lock file lands there and never in ~/.claude/ide.
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

-- Starts claudecode's server, runs body with its port, and stops the server
-- again, even when body fails.
local function serving(t, body)
  local C = require("claudecode")
  local started, port = C.start(false)
  t.ok(started, "the server starts: " .. tostring(port))
  local ok, err = pcall(body, port)
  local stopped = C.stop()
  if not ok then
    error(err, 0)
  end
  t.eq(stopped, true, "the server stops")
end

-- Connects to the server on port and asks to turn the connection into a
-- WebSocket, sending token as Claude Code sends it. Waits up to three seconds
-- for the reply to contain want. Returns the reply and the connection, which
-- the caller closes.
local function ask(port, token, want)
  local tcp = assert(vim.uv.new_tcp())
  local reply = ""
  tcp:connect("127.0.0.1", port, function(err)
    if err then
      return
    end
    tcp:read_start(function(_, chunk)
      if chunk then
        reply = reply .. chunk
      end
    end)
    tcp:write(table.concat({
      "GET / HTTP/1.1",
      "Host: 127.0.0.1:" .. port,
      "Upgrade: websocket",
      "Connection: Upgrade",
      -- The sample key from the WebSocket standard, RFC 6455. The server
      -- checks that a key is 24 characters long, and this one is.
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
      "Sec-WebSocket-Version: 13",
      "x-claude-code-ide-authorization: " .. token,
      "",
      "",
    }, "\r\n"))
  end)
  vim.wait(3000, function() return reply:find(want, 1, true) ~= nil end, 20)
  return reply, tcp
end

-- Closes a connection ask opened.
local function hang_up(tcp)
  if not tcp:is_closing() then
    tcp:close()
  end
end

-- The window edgy has docked under the view called title, or nil.
local function docked_as(title)
  local edgy = require("edgy.editor")
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local e = edgy.get_win(win)
    if e and e.view.title == title then
      return win
    end
  end
end

-- The width of the docked Claude Code panel, or nil when it is not docked.
local function panel_width()
  local win = docked_as("Claude Code")
  return win and vim.api.nvim_win_get_width(win)
end

return {
  ["a headless Neovim starts no Claude Code server and writes no lock file"] = function(t)
    t.eq(#vim.api.nvim_list_uis(), 0, "the suite runs with no screen")
    local C = package.loaded["claudecode"]
    t.ok(C ~= nil, "claudecode has loaded, as it does once Neovim is idle")
    t.eq(C.state.server, nil, "but it started no server")
    local dir = vim.env.CLAUDE_CONFIG_DIR
    t.ok(
      dir ~= nil and dir ~= "" and not vim.startswith(dir, vim.env.HOME .. "/.claude"),
      "scripts/check gives Claude Code a scratch folder"
    )
    t.eq(vim.fn.glob(dir .. "/ide/*.lock", false, true), {}, "and no lock file was written there")
    t.eq(require("ach.claude").opts().auto_start, false, "because the automatic start is off with no screen")
  end,

  ["the status bar's check never loads claudecode"] = function(t)
    local A = require("ach.claude")
    with({ { package.loaded, "claudecode", nil } }, function()
      t.eq(A.status(), "off", "off while claudecode is not loaded")
      t.eq(package.loaded["claudecode"], nil, "and asking did not load it")
    end)
  end,

  ["the server listens on 127.0.0.1 alone and keeps a private lock file until it stops"] = function(t)
    local C = require("claudecode")
    local dir = vim.env.CLAUDE_CONFIG_DIR .. "/ide"
    local file
    serving(t, function(port)
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

      file = ("%s/%d.lock"):format(dir, port)
      t.eq(("%o"):format(vim.uv.fs_stat(dir).mode % 512), "700", "the lock folder is the owner's alone")
      t.eq(("%o"):format(vim.uv.fs_stat(file).mode % 512), "600", "and so is the lock file")

      local lock = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
      t.eq(lock.pid, vim.fn.getpid(), "the lock file names this Neovim")
      t.eq(lock.ideName, "Neovim")
      t.eq(lock.transport, "ws")
      t.eq(type(lock.workspaceFolders), "table", "and the folders being edited")
      t.ok(
        type(lock.authToken) == "string" and #lock.authToken == 32 and lock.authToken:match("^%x+$") ~= nil,
        "the token is 32 hexadecimal characters"
      )
      t.eq(lock.authToken, C.state.auth_token, "and it is the token the server checks")
    end)
    t.eq(vim.uv.fs_stat(file), nil, "stopping the server removes the lock file")
  end,

  ["the server refuses the wrong token, lets in the right one, and the status follows"] = function(t)
    local A = require("ach.claude")
    t.eq(A.status(), "off", "off before the server starts")
    serving(t, function(port)
      t.eq(A.status(), "waiting", "waiting once the server listens")

      local reply, tcp = ask(port, string.rep("0", 32), "Invalid authentication token")
      hang_up(tcp)
      t.eq(vim.split(reply, "\r\n")[1], "HTTP/1.1 400 Bad Request", "a wrong token is refused")
      t.ok(
        reply:find("Bad WebSocket upgrade request: Invalid authentication token", 1, true) ~= nil,
        "and the refusal says why"
      )
      t.eq(A.status(), "waiting", "a refused connection does not count as Claude")

      reply, tcp = ask(port, require("claudecode").state.auth_token, "101 Switching Protocols")
      local connected = vim.wait(3000, function() return A.status() == "connected" end, 20)
      hang_up(tcp)
      t.eq(vim.split(reply, "\r\n")[1], "HTTP/1.1 101 Switching Protocols", "the right token is let in")
      t.ok(connected, "and the status bar shows Claude as connected")
    end)
    t.eq(A.status(), "off", "off again once the server stops")
  end,

  ["the panel takes 40 percent of the width alone, beside Grug Far, and after a hide"] = function(t)
    with({ { vim.o, "columns", 200 } }, function()
      tidy(function()
        local provider = require("claudecode.terminal.snacks")
        -- The panel's own settings, except that it stays in normal mode, so
        -- the test never sits in the terminal waiting for keys.
        local config = vim.tbl_extend("force", require("ach.claude").opts().terminal, { auto_insert = false })
        provider.open("sleep 60", vim.empty_dict(), config, false)
        t.ok(
          vim.wait(3000, function() return panel_width() == 80 end, 20),
          "alone on the right, the panel is 80 of 200 columns, not 30"
        )

        require("grug-far").open()
        t.ok(
          vim.wait(3000, function() return docked_as("Grug Far") ~= nil and panel_width() == 80 end, 20),
          "with Grug Far docked beside it, still 80"
        )

        provider.simple_toggle("sleep 60", {}, config)
        t.ok(
          vim.wait(3000, function() return docked_as("Claude Code") == nil end, 20),
          "the first toggle hides the panel"
        )
        provider.simple_toggle("sleep 60", {}, config)
        t.ok(vim.wait(3000, function() return panel_width() == 80 end, 20), "the second shows it again, docked at 80")

        provider.close()
      end)
    end)
  end,

  ["every Space a key is set, with a description that has an icon"] = function(t)
    local keys = {
      { "<leader>ac", "n" },
      { "<leader>af", "n" },
      { "<leader>ar", "n" },
      { "<leader>aC", "n" },
      { "<leader>am", "n" },
      { "<leader>ab", "n" },
      { "<leader>as", "x" },
      { "<leader>aa", "n" },
      { "<leader>ad", "n" },
    }
    for _, k in ipairs(keys) do
      local m = vim.fn.maparg(k[1], k[2], false, true)
      t.ok(m.desc ~= nil, ("%s is set in mode %s"):format(k[1], k[2]))
      t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
    end
    tidy(function()
      vim.cmd.enew()
      vim.bo.filetype = "snacks_picker_list"
      local m = vim.fn.maparg("<leader>as", "n", false, true)
      t.eq(m.buffer, 1, "in the file explorer, Space a s belongs to the buffer")
      t.eq(m.desc, "Add File to Claude", "and adds the file rather than a selection")
      t.ok(I.key(m.desc) ~= nil, "and has a line in M.keys")
    end)
  end,

  ["with no claude program, a Space a key prints the Homebrew line and opens nothing"] = function(t)
    tidy(function()
      local wins = #vim.api.nvim_list_wins()
      local said = notices(function()
        with({ { vim.fn, "executable", only({}) } }, function() press("<leader>ac") end)
      end)
      t.eq(
        vim.tbl_map(function(n) return n.msg end, said),
        { "Claude Code is not installed. Install it with: brew install --cask claude-code" },
        "one line, saying what to run"
      )
      t.eq(#vim.api.nvim_list_wins(), wins, "and no panel opened")
    end)
  end,
}
