-- The Homebrew programs the integrations call, and the Integrations section
-- of :checkhealth ach. vim.fn.executable and vim.notify are stand-ins, so no
-- test depends on what this Mac has installed.

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

-- Two programs to stand in for the real list.
local fake = {
  { name = "lazygit", brew = "brew install lazygit", purpose = "Lazygit on Space g g" },
  {
    name = "gh",
    label = "GitHub's gh",
    brew = "brew install gh, then run: gh auth login",
    purpose = "GitHub issues and pull requests",
  },
}

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

-- Runs the Integrations section alone and returns what it reported: one
-- { kind, msg, advice } per call, kind being the vim.health function called.
local function integrations(stubs)
  local H = require("ach.health")
  local section
  for _, s in ipairs(H.sections) do
    if s[1] == "Integrations" then
      section = s[2]
    end
  end
  assert(section, "no Integrations section in :checkhealth ach")
  local out = {}
  local function record(kind)
    return function(msg, advice) out[#out + 1] = { kind = kind, msg = msg, advice = advice } end
  end
  local all = {
    { vim.health, "ok", record("ok") },
    { vim.health, "info", record("info") },
    { vim.health, "warn", record("warn") },
    { vim.health, "error", record("error") },
  }
  vim.list_extend(all, stubs)
  with(all, function() section({}) end)
  return out
end

-- A stand-in for vim.fn.has that answers old for Neovim 0.12.4.
local function release(old)
  local real = vim.fn.has
  return function(feature)
    if feature == "nvim-0.12.4" then
      return old and 0 or 1
    end
    return real(feature)
  end
end

return {
  ["a program on the path is found and nothing is printed"] = function(t)
    local need = require("ach.need")
    local found
    local said = notices(function()
      with(
        { { need, "programs", fake }, { vim.fn, "executable", only({ lazygit = true }) } },
        function() found = need.have("lazygit") end
      )
    end)
    t.eq(found, true, "lazygit is found")
    t.eq(#said, 0, "nothing is printed")
  end,

  ["a missing program prints the line that installs it and is not found"] = function(t)
    local need = require("ach.need")
    local found
    local said = notices(function()
      with({ { need, "programs", fake }, { vim.fn, "executable", only({}) } }, function() found = need.have("gh") end)
    end)
    t.eq(found, false, "gh is not found")
    t.eq(#said, 1, "one message")
    t.eq(said[1].msg, "GitHub's gh is not installed. Install it with: brew install gh, then run: gh auth login")
    t.eq(said[1].level, vim.log.levels.WARN, "as a warning")
  end,

  ["a name the list does not hold is an error"] = function(t)
    local need = require("ach.need")
    local ok, err
    with({ { need, "programs", fake } }, function()
      ok, err = pcall(need.have, "lazygti")
    end)
    t.eq(ok, false, "an error")
    t.ok(tostring(err):find("lazygti", 1, true) ~= nil, "naming the program")
  end,

  ["every program in the list has a name, a brew line and a purpose, once each"] = function(t)
    local seen = {}
    for _, p in ipairs(require("ach.need").programs) do
      t.ok(type(p.name) == "string" and p.name ~= "", "a name")
      t.ok(not seen[p.name], p.name .. " is listed once")
      seen[p.name] = true
      t.ok(type(p.brew) == "string" and p.brew:find("^brew ") ~= nil, p.name .. " installs with brew")
      t.ok(type(p.purpose) == "string" and p.purpose ~= "", p.name .. " says what it is for")
    end
  end,

  ["every have() in the configuration names a program in the list"] = function(t)
    local need = require("ach.need")
    local files = vim.fs.find(
      function(name) return name:match("%.lua$") ~= nil end,
      { path = t.root .. "/lua", type = "file", limit = math.huge }
    )
    t.ok(#files > 0, "the configuration's Lua files are found")
    for _, file in ipairs(files) do
      local text = table.concat(vim.fn.readfile(file), "\n")
      for name in text:gmatch('have%("([^"]+)"%)') do
        t.ok(need.get(name) ~= nil, ("%s asks for %s, which ach.need does not list"):format(file, name))
      end
    end
  end,

  ["the Integrations section holds Neovim to the 0.12.4 floor VimTeX sets"] = function(t)
    local need = require("ach.need")
    local old = integrations({ { need, "programs", {} }, { vim.fn, "has", release(true) } })
    t.eq(#old, 1, "one line")
    t.eq(old[1].kind, "error", "an older Neovim is an error")
    t.ok(old[1].msg:find("0.12.4", 1, true) ~= nil, "naming the floor")
    t.eq(old[1].advice, { "brew upgrade neovim" }, "with the command that fixes it")
    local now = integrations({ { need, "programs", {} }, { vim.fn, "has", release(false) } })
    t.eq(now[1].kind, "ok", "0.12.4 or later is fine")
  end,

  ["the Integrations section reports each program, with the install line for one that is missing"] = function(t)
    local need = require("ach.need")
    local out = integrations({
      { need, "programs", fake },
      { vim.fn, "has", release(false) },
      { vim.fn, "executable", only({ lazygit = true }) },
    })
    t.eq(#out, 3, "the Neovim line and one line per program")
    t.eq(out[2], { kind = "ok", msg = "lazygit is installed, for Lazygit on Space g g" })
    t.eq(out[3], {
      kind = "warn",
      msg = "GitHub's gh is not installed, so GitHub issues and pull requests will not work",
      advice = { "brew install gh, then run: gh auth login" },
    })
  end,

  ["Integrations is the last section of :checkhealth ach"] = function(t)
    local sections = require("ach.health").sections
    t.eq(sections[#sections][1], "Integrations")
  end,
}
