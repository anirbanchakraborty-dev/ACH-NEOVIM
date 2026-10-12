-- Language servers. Every server in the table has a program to look for; a
-- file type's servers are enabled once each and only when installed; a
-- server's buffer gets exactly the keys its capabilities allow, each with an
-- icon, plus inlay hints and code lenses; a capability registered later adds
-- its key; the pickers the keys open exist; and SchemaStore, the per-server
-- settings, the diagnostic signs and lazydev all reach their places. The
-- buffer tests talk to a fake server inside this Neovim, so no program runs.
local I = require("ach.icons")

-- Replaces fields for the length of body, then puts every one back and
-- clears ach.lsp's state, even when body fails. Each stub is
-- { table, key, value }.
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
  require("ach.lsp").reset()
  if not ok then
    error(err, 0)
  end
end

-- A server that runs inside this Neovim. It answers initialize with the
-- given capabilities and ignores every other request.
local function fake(capabilities)
  return function(dispatchers)
    local closing, id = false, 0
    return {
      request = function(method, _, callback)
        id = id + 1
        if method == "initialize" then
          callback(nil, { capabilities = capabilities })
        elseif method == "shutdown" then
          callback(nil, vim.NIL)
        end
        return true, id
      end,
      notify = function(method)
        if method == "exit" then
          closing = true
          dispatchers.on_exit(0, 15)
        end
        return true
      end,
      is_closing = function() return closing end,
      terminate = function()
        if not closing then
          closing = true
          dispatchers.on_exit(0, 15)
        end
      end,
    }
  end
end

-- The descriptions of a buffer's own keys, in normal, visual and insert mode.
local function descs(buf)
  local out = {}
  for _, mode in ipairs({ "n", "x", "i" }) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      if map.desc then
        out[map.desc] = true
      end
    end
  end
  return out
end

-- Opens a new file, starts a fake server on it and waits for its keys.
local function attach(t, name, capabilities)
  local dir = t.tmpdir()
  local path = dir .. "/sample.txt"
  vim.fn.writefile({ "one two one" }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local id = vim.lsp.start({ name = name, cmd = fake(capabilities), root_dir = dir }, { bufnr = buf })
  t.ok(id, "the fake server started")
  vim.wait(2000, function() return descs(buf)["Lsp Info"] ~= nil end)
  return buf, vim.lsp.get_client_by_id(id)
end

local function detach(buf, client)
  local id = client.id
  client:stop(true)
  vim.wait(2000, function() return vim.lsp.get_client_by_id(id) == nil end)
  vim.api.nvim_buf_delete(buf, { force = true })
end

local function sorted_keys(t)
  local out = vim.tbl_keys(t)
  table.sort(out)
  return out
end

return {
  ["every server in the table has a program to look for"] = function(t)
    local lsp = require("ach.lsp")
    local missing = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      local program = lsp.program(name)
      if type(program) ~= "string" or program == "" then
        missing[#missing + 1] = name
      end
    end
    table.sort(missing)
    t.eq(missing, {}, "servers with no program")
  end,

  ["a program is listed exactly where the command is built by a function"] = function(t)
    local want = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      local config = vim.lsp.config[name]
      if config and type(config.cmd) == "function" then
        want[#want + 1] = name
      end
    end
    table.sort(want)
    t.eq(sorted_keys(require("ach.servers").programs), want)
  end,

  ["every server with settings is one the table names"] = function(t)
    local known = {}
    for _, name in ipairs(require("ach.lang").servers()) do
      known[name] = true
    end
    local stray = {}
    for name in pairs(require("ach.servers").settings) do
      if not known[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "settings for servers the table does not name")
  end,

  ["a file type's servers are enabled once each, when their programs are installed"] = function(t)
    local lsp = require("ach.lsp")
    local installed = { dockerls = "true" }
    local enabled = {}
    with({
      { lsp, "program", function(name) return installed[name] or "ach-no-such-program" end },
      { lsp, "capabilities", function() return {} end },
      { vim.lsp, "enable", function(name) enabled[#enabled + 1] = name end },
    }, function()
      lsp.enable_for("dockerfile")
      lsp.enable_for("dockerfile")
      t.eq(enabled, { "dockerls" }, "after two Dockerfiles")
      installed.docker_compose_language_service = "true"
      lsp.enable_for("yaml.docker-compose")
      t.eq(enabled, { "dockerls", "docker_compose_language_service" }, "after the compose server installs")
    end)
  end,

  ["a server's buffer gets the keys its capabilities allow, each with an icon"] = function(t)
    local buf, client = attach(t, "ach-fake-keys", {
      definitionProvider = true,
      hoverProvider = true,
      codeActionProvider = true,
      codeLensProvider = { resolveProvider = false },
      documentHighlightProvider = true,
      inlayHintProvider = true,
    })
    local ok, err = pcall(function()
      local got = descs(buf)
      local absent = {}
      for _, desc in ipairs({
        "Lsp Info",
        "Goto Definition",
        "Hover",
        "Code Action",
        "Source Action",
        "Organize Imports",
        "Run Codelens",
        "Toggle Codelens",
        "Next Reference",
        "Prev Reference",
      }) do
        if not got[desc] then
          absent[#absent + 1] = desc
        end
      end
      t.eq(absent, {}, "keys the capabilities allow but the buffer lacks")
      local extra = {}
      for _, desc in ipairs({ "Rename", "Rename File", "References", "Goto Declaration", "LSP Workspace Symbols" }) do
        if got[desc] then
          extra[#extra + 1] = desc
        end
      end
      t.eq(extra, {}, "keys set without their capability")
      local plain = {}
      for desc in pairs(got) do
        if not I.key(desc) then
          plain[#plain + 1] = desc
        end
      end
      table.sort(plain)
      t.eq(plain, {}, "buffer keys with no icon")
      t.ok(vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), "inlay hints are on")
      t.ok(vim.lsp.codelens.is_enabled({ bufnr = buf }), "code lenses are on")
    end)
    detach(buf, client)
    if not ok then
      error(err, 0)
    end
  end,

  ["a capability the server registers later adds its key"] = function(t)
    local buf, client = attach(t, "ach-fake-later", { hoverProvider = true })
    local ok, err = pcall(function()
      t.ok(not descs(buf)["Rename"], "Rename before the server registers it")
      vim.lsp.handlers["client/registerCapability"](
        nil,
        { registrations = { { id = "ach-rename", method = "textDocument/rename" } } },
        { client_id = client.id, method = "client/registerCapability" }
      )
      t.ok(descs(buf)["Rename"], "Rename once the server registers it")
    end)
    detach(buf, client)
    if not ok then
      error(err, 0)
    end
  end,

  ["every key opens a picker that exists and has an icon of its own"] = function(t)
    local lsp = require("ach.lsp")
    local sources = require("snacks.picker.config.sources")
    local unknown, plain = {}, {}
    for _, name in ipairs(lsp.pickers) do
      if not sources[name] then
        unknown[#unknown + 1] = name
      end
    end
    for _, key in ipairs(lsp.keys) do
      if not I.key(key.desc) then
        plain[#plain + 1] = key.desc
      end
    end
    t.ok(#lsp.pickers >= 10, "the keys open at least ten pickers")
    t.eq(unknown, {}, "pickers snacks does not have")
    t.eq(plain, {}, "keys with no icon")
  end,

  ["JSON and YAML servers get SchemaStore's catalogue"] = function(t)
    for _, case in ipairs({ { "jsonls", "json" }, { "yamlls", "yaml" } }) do
      local config = vim.deepcopy(vim.lsp.config[case[1]])
      config.before_init({}, config)
      local schemas = config.settings[case[2]].schemas
      t.ok(type(schemas) == "table" and vim.tbl_count(schemas) > 100, case[1] .. " has SchemaStore's schemas")
    end
    t.eq(vim.lsp.config.yamlls.settings.yaml.schemaStore.enable, false, "yamlls' own download of the catalogue")
  end,

  ["Astro's server finds TypeScript in the project, or else the copy Mason installed with it"] = function(t)
    local project = t.tmpdir()
    vim.fn.mkdir(project .. "/node_modules/typescript/lib", "p")
    local config = vim.deepcopy(vim.lsp.config.astro)
    config.root_dir = project
    config.before_init({}, config)
    t.eq(config.init_options.typescript.tsdk, project .. "/node_modules/typescript/lib", "the project's own TypeScript")
    local bare = vim.deepcopy(vim.lsp.config.astro)
    bare.root_dir = t.tmpdir()
    bare.before_init({}, bare)
    local mason = vim.fn.stdpath("data") .. "/mason/packages/astro-language-server/node_modules/typescript/lib"
    t.eq(bare.init_options.typescript.tsdk, mason, "Mason's copy, outside a project with TypeScript")
  end,

  ["each server's own settings reach its configuration"] = function(t)
    local client = { server_capabilities = { hoverProvider = true } }
    vim.lsp.config.ruff.on_init(client)
    t.eq(client.server_capabilities.hoverProvider, false, "ruff leaves hover to basedpyright")
    t.ok(vim.tbl_contains(vim.lsp.config.clangd.cmd, "--clang-tidy"), "clangd runs clang-tidy")
    t.eq(type(vim.lsp.config.julials.cmd), "function", "julials' command")
    t.ok(
      vim.endswith(vim.lsp.config.powershell_es.bundle_path, "/mason/packages/powershell-editor-services"),
      "PowerShell's bundle"
    )
    t.ok(vim.tbl_contains(vim.lsp.config.vtsls.filetypes, "vue"), "vtsls serves Vue files")
    local plugin = vim.lsp.config.vtsls.settings.vtsls.tsserver.globalPlugins[1]
    t.eq(plugin.name, "@vue/typescript-plugin", "the Vue plugin")
    t.ok(
      vim.endswith(plugin.location, "/vue-language-server/node_modules/@vue/language-server"),
      "the Vue plugin's location"
    )
    t.eq(vim.lsp.config.gopls.settings.gopls.gofumpt, true, "gopls formats with gofumpt")
  end,

  ["diagnostics draw with the icon database's glyphs"] = function(t)
    local config = vim.diagnostic.config()
    local severity = vim.diagnostic.severity
    t.eq(config.signs.text, {
      [severity.ERROR] = I.diagnostics.Error,
      [severity.WARN] = I.diagnostics.Warn,
      [severity.INFO] = I.diagnostics.Info,
      [severity.HINT] = I.diagnostics.Hint,
    }, "the signs")
    t.eq(config.virtual_text.prefix({ severity = severity.WARN }), I.diagnostics.Warn, "the inline prefix")
    t.eq({ config.severity_sort, config.update_in_insert }, { true, false }, "severity_sort and update_in_insert")
  end,

  ["Lua files complete from lazydev"] = function(t)
    require("lazy").load({ plugins = { "blink.cmp" } })
    local config = require("blink.cmp.config")
    t.ok(vim.tbl_contains(config.sources.default, "lazydev"), "lazydev is a default source")
    for _, source in ipairs({ "lsp", "path", "snippets", "buffer" }) do
      t.ok(vim.tbl_contains(config.sources.default, source), source .. " is still a default source")
    end
    t.eq(config.sources.providers.lazydev.module, "lazydev.integrations.blink", "lazydev's provider")
  end,
}
