-- Installs what a language needs the first time one of its files opens, then
-- starts Tree-sitter on the buffer. Under ACH_DRY_INSTALL=1, which
-- scripts/check sets outside --full, it installs nothing and records what it
-- would have installed in M.requests, so the regular suite never downloads.
local M = {}

M.dry = vim.env.ACH_DRY_INSTALL == "1"
M.requests = { parsers = {}, packages = {}, servers = {} }

local available -- nvim-treesitter's parser names, read once
local failed = {} -- parsers that failed this session, never retried
local pending = {} -- parser name -> callbacks waiting on its install

local function record(kind, names)
  local list = M.requests[kind]
  for _, name in ipairs(names) do
    if not vim.list_contains(list, name) then
      list[#list + 1] = name
    end
  end
  table.sort(list)
end

function M.available_parsers()
  if not available then
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then
      return {} -- not installed yet, as on the very first start
    end
    available = {}
    for _, name in ipairs(ts.get_available()) do
      available[name] = true
    end
  end
  return available
end

function M.installed_parsers()
  local set = {}
  if M.dry then
    return set
  end
  local ok, ts = pcall(require, "nvim-treesitter")
  for _, name in ipairs(ok and ts.get_installed("parsers") or {}) do
    set[name] = true
  end
  return set
end

-- Installs the parsers in names that exist, are missing and have not failed,
-- then calls done once. Two calls for the same parser share one install.
function M.ensure_parsers(names, done)
  done = done or function() end
  local known, installed = M.available_parsers(), M.installed_parsers()
  local want = {}
  for _, name in ipairs(names) do
    if known[name] and not installed[name] and not failed[name] and not vim.list_contains(want, name) then
      want[#want + 1] = name
    end
  end
  if #want == 0 then
    return done()
  end
  if M.dry then
    record("parsers", want)
    return done()
  end

  local remaining = #want
  local function one_done()
    remaining = remaining - 1
    if remaining == 0 then
      done()
    end
  end
  local new = {}
  for _, name in ipairs(want) do
    if not pending[name] then
      pending[name] = {}
      new[#new + 1] = name
    end
    table.insert(pending[name], one_done)
  end
  if #new == 0 then
    return
  end
  require("nvim-treesitter").install(new, { summary = false }):await(function()
    vim.schedule(function()
      local now = M.installed_parsers()
      for _, name in ipairs(new) do
        if not now[name] then
          failed[name] = true -- nvim-treesitter has already said why
        end
        local waiting = pending[name]
        pending[name] = nil
        for _, cb in ipairs(waiting) do
          cb()
        end
      end
    end)
  end)
end

function M.reset()
  M.requests = { parsers = {}, packages = {}, servers = {} }
  available, failed, pending = nil, {}, {}
end

-- Only a real file shows that the owner works in a language: a buffer with no
-- special type, a name, and a readable file behind that name. A picker's
-- preview, a help page, a scratch buffer and a file not yet written are not.
function M.is_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.filereadable(name) == 1
end

-- The parsers that the injection queries of langs name by a literal
-- injection.language, kept when nvim-treesitter can install them and langs
-- does not already hold them. A language that only a capture decides, as a
-- Markdown code block's does, is left to a file of that language.
function M.injected_parsers(langs)
  local known, found = M.available_parsers(), {}
  for _, lang in ipairs(langs) do
    local ok, files = pcall(vim.treesitter.query.get_files, lang, "injections")
    for _, file in ipairs(ok and files or {}) do
      for _, line in ipairs(vim.fn.readfile(file)) do
        if not line:match("^%s*;") then
          for name in line:gmatch('injection%.language%s+"([^"]+)"') do
            if known[name] and not vim.list_contains(langs, name) then
              found[name] = true
            end
          end
        end
      end
    end
  end
  local out = vim.tbl_keys(found)
  table.sort(out)
  return out
end

-- Installs the parsers a buffer's file type needs, then starts Tree-sitter on
-- it. Anything that is not a real file gets whatever parser is already there.
local function handle(buf, ft)
  local attach = function() require("ach.treesitter").attach(buf) end
  if not M.is_file(buf) then
    return attach()
  end
  vim.b[buf].ach_handled = true
  local entry = require("ach.lang").for_ft(ft)
  local parsers = vim.deepcopy(entry and entry.ts or {})
  -- A file type the table does not list still gets its parser when one exists.
  local own = vim.treesitter.language.get_lang(ft) or ft
  if M.available_parsers()[own] and not vim.list_contains(parsers, own) then
    parsers[#parsers + 1] = own
  end
  -- The file's own parsers first, so it is highlighted as soon as they are
  -- there, then the ones their injection queries name, which those parsers'
  -- own queries, now installed, say.
  M.ensure_parsers(parsers, function()
    attach()
    M.ensure_parsers(M.injected_parsers(parsers), attach)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ach_install", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev) handle(ev.buf, ev.match) end,
  })
  -- A new file is not a real file until it is written, so its first write is
  -- when it installs.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      if ft ~= "" and not vim.b[ev.buf].ach_handled then
        handle(ev.buf, ft)
      end
    end,
  })
end

return M
