-- Language servers: what the client tells a server it can do, how
-- diagnostics are drawn, the keys a server's buffer gets, and enabling a
-- file type's servers once their programs are installed.
local M = {}

local I = require("ach.icons")

-- Every picker a key opens, collected as the keys are defined, so a test can
-- check that snacks has each one.
M.pickers = {}

local function picker(name)
  M.pickers[#M.pickers + 1] = name
  return function() Snacks.picker.pick(name) end
end

-- Each key is set on a buffer only when one of its servers supports the
-- method in has, or one of the methods when has is a list. A key with no has
-- is set for any server.
M.keys = {
  { "<leader>cl", picker("lsp_config"), desc = "Lsp Info" },
  { "gd", picker("lsp_definitions"), desc = "Goto Definition", has = "textDocument/definition" },
  { "gD", picker("lsp_declarations"), desc = "Goto Declaration", has = "textDocument/declaration" },
  { "grr", picker("lsp_references"), desc = "References", has = "textDocument/references" },
  { "gri", picker("lsp_implementations"), desc = "Goto Implementation", has = "textDocument/implementation" },
  { "grt", picker("lsp_type_definitions"), desc = "Goto Type Definition", has = "textDocument/typeDefinition" },
  { "gai", picker("lsp_incoming_calls"), desc = "Incoming Calls", has = "callHierarchy/incomingCalls" },
  { "gao", picker("lsp_outgoing_calls"), desc = "Outgoing Calls", has = "callHierarchy/outgoingCalls" },
  {
    "K",
    function() vim.lsp.buf.hover() end,
    desc = "Hover",
    has = "textDocument/hover",
  },
  {
    "gK",
    function() vim.lsp.buf.signature_help() end,
    desc = "Signature Help",
    has = "textDocument/signatureHelp",
  },
  {
    "<leader>ca",
    function() vim.lsp.buf.code_action() end,
    desc = "Code Action",
    mode = { "n", "x" },
    has = "textDocument/codeAction",
  },
  {
    "<leader>cA",
    function() vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } }) end,
    desc = "Source Action",
    has = "textDocument/codeAction",
  },
  {
    "<leader>co",
    function()
      vim.lsp.buf.code_action({ apply = true, context = { only = { "source.organizeImports" }, diagnostics = {} } })
    end,
    desc = "Organize Imports",
    has = "textDocument/codeAction",
  },
  {
    "<leader>cc",
    function() vim.lsp.codelens.run() end,
    desc = "Run Codelens",
    mode = { "n", "x" },
    has = "textDocument/codeLens",
  },
  {
    "<leader>cC",
    function()
      local filter = { bufnr = vim.api.nvim_get_current_buf() }
      vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled(filter), filter)
    end,
    desc = "Toggle Codelens",
    has = "textDocument/codeLens",
  },
  {
    "<leader>cr",
    function() vim.lsp.buf.rename() end,
    desc = "Rename",
    has = "textDocument/rename",
  },
  {
    "<leader>cR",
    function() Snacks.rename.rename_file() end,
    desc = "Rename File",
    has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
  },
  {
    "]]",
    function() Snacks.words.jump(vim.v.count1) end,
    desc = "Next Reference",
    has = "textDocument/documentHighlight",
  },
  {
    "[[",
    function() Snacks.words.jump(-vim.v.count1) end,
    desc = "Prev Reference",
    has = "textDocument/documentHighlight",
  },
  { "<leader>ss", picker("lsp_symbols"), desc = "LSP Symbols", has = "textDocument/documentSymbol" },
  { "<leader>sS", picker("lsp_workspace_symbols"), desc = "LSP Workspace Symbols", has = "workspace/symbol" },
}

local function supports(client, has, buf)
  if not has then
    return true
  end
  for _, method in ipairs(type(has) == "table" and has or { has }) do
    if client:supports_method(method, buf) then
      return true
    end
  end
  return false
end

-- Sets the keys this client allows on buf and turns on inlay hints and code
-- lenses where it draws them. Running it again for the same buffer is
-- harmless, which is what lets a capability registered later add its key.
function M.attach(buf, client)
  for _, key in ipairs(M.keys) do
    if supports(client, key.has, buf) then
      vim.keymap.set(key.mode or "n", key[1], key[2], { buf = buf, desc = key.desc })
    end
  end
  if vim.bo[buf].buftype == "" and client:supports_method("textDocument/inlayHint", buf) then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end
  if client:supports_method("textDocument/codeLens", buf) then
    vim.lsp.codelens.enable(true, { bufnr = buf })
  end
end

local names = {
  [vim.diagnostic.severity.ERROR] = "Error",
  [vim.diagnostic.severity.WARN] = "Warn",
  [vim.diagnostic.severity.INFO] = "Info",
  [vim.diagnostic.severity.HINT] = "Hint",
}

function M.diagnostics()
  local text = {}
  for severity, name in pairs(names) do
    text[severity] = I.diagnostics[name]
  end
  return {
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = function(diagnostic) return I.diagnostics[names[diagnostic.severity]] end,
    },
    signs = { text = text },
    float = { source = "if_many" },
  }
end

-- blink's completion capabilities, plus file renames, which a server only
-- offers to a client that says it can send them.
function M.capabilities()
  return vim.tbl_deep_extend("force", require("blink.cmp").get_lsp_capabilities(), {
    workspace = { fileOperations = { didRename = true, willRename = true } },
  })
end

-- The program a server runs, or nil when neither servers.programs nor
-- nvim-lspconfig's command names one.
function M.program(name)
  local listed = require("ach.servers").programs[name]
  if listed then
    return listed
  end
  local config = vim.lsp.config[name]
  local cmd = config and config.cmd
  return type(cmd) == "table" and cmd[1] or nil
end

local enabled, configured = {}, false

-- Enables each of the file type's servers whose program is on the path, once
-- per session. A server that is missing now is tried again on the next file
-- of its language, which is when the installer has had another go. The
-- capabilities are set before the first server starts; they load blink.cmp,
-- which would otherwise wait for the first InsertEnter.
function M.enable_for(ft)
  if not configured then
    vim.lsp.config("*", { capabilities = M.capabilities() })
    configured = true
  end
  for _, name in ipairs(require("ach.lang").servers_for_ft(ft)) do
    if not enabled[name] then
      local program = M.program(name)
      if program and vim.fn.executable(program) == 1 then
        enabled[name] = true
        vim.lsp.enable(name)
      end
    end
  end
end

function M.reset()
  enabled, configured = {}, false
end

local did_setup = false

function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  vim.diagnostic.config(M.diagnostics())
  for name, settings in pairs(require("ach.servers").settings) do
    vim.lsp.config(name, settings)
  end
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ach_lsp", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        M.attach(ev.buf, client)
      end
    end,
  })
  local register = vim.lsp.handlers["client/registerCapability"]
  vim.lsp.handlers["client/registerCapability"] = function(err, result, ctx)
    local ret = register(err, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then
      for buf in pairs(client.attached_buffers) do
        M.attach(buf, client)
      end
    end
    return ret
  end
end

return M
