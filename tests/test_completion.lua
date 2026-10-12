local function mapped(lhs, mode)
  return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil
end

local function blink_config()
  require("lazy").load({ plugins = { "blink.cmp" } })
  return require("blink.cmp.config")
end

local function read_json(path)
  local fd = assert(io.open(path, "r"))
  local data = fd:read("*a")
  fd:close()
  return vim.json.decode(data)
end

return {
  ["the compiled matcher is installed"] = function(t)
    require("lazy").load({ plugins = { "blink.cmp" } })
    if not pcall(require, "blink.cmp.fuzzy.rust") then
      t.human("blink.cmp's compiled matcher is missing: run scripts/fetch-matcher")
    end
  end,

  ["completion draws on the language server, paths, snippets and open files"] = function(t)
    local default = blink_config().sources.default
    local missing = {}
    for _, name in ipairs({ "lsp", "path", "snippets", "buffer" }) do
      if not vim.tbl_contains(default, name) then
        missing[#missing + 1] = name
      end
    end
    t.eq(missing, {}, "completion sources")
  end,

  ["our snippets reach blink"] = function(t)
    local opts = vim.deepcopy(blink_config().sources.providers.snippets.opts)
    -- Only the configured folder, so a friendly-snippets prefix cannot stand in for ours.
    opts.friendly_snippets = false
    local registry = require("blink.cmp.sources.snippets.default.registry").new(opts)
    local want = { all = { "today" }, lua = { "mod" }, tex = { "align", "eq", "ex", "frac", "mk", "thm" } }
    local missing = {}
    for ft, prefixes in pairs(want) do
      local have = {}
      for _, s in ipairs(registry:get_snippets_for_ft(ft)) do
        -- blink splits a list of prefixes into one snippet each; accept either form.
        for _, p in ipairs(type(s.prefix) == "table" and s.prefix or { s.prefix }) do
          have[p] = true
        end
      end
      for _, p in ipairs(prefixes) do
        if not have[p] then
          missing[#missing + 1] = ft .. " " .. p
        end
      end
    end
    table.sort(missing)
    t.eq(missing, {}, "snippets blink cannot see")
  end,

  ["every snippet file parses and every snippet has a prefix and a body"] = function(t)
    local dir = t.root .. "/snippets"
    local bad = {}
    for _, entry in ipairs(read_json(dir .. "/package.json").contributes.snippets) do
      local ok, snippets = pcall(read_json, dir .. "/" .. entry.path)
      if not ok then
        bad[#bad + 1] = entry.path .. ": " .. tostring(snippets)
      else
        for name, s in pairs(snippets) do
          if not s.prefix or not s.body then
            bad[#bad + 1] = entry.path .. ": " .. name
          end
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "broken snippets")
  end,

  ["the completion menu draws the icon database's kind icons"] = function(t)
    local kinds, drawn = require("ach.icons").kinds, blink_config().appearance.kind_icons
    for _, kind in ipairs({ "Function", "Snippet", "Text" }) do
      t.eq(drawn[kind], kinds[kind], "the " .. kind .. " icon")
    end
  end,

  ["brackets pair and text objects are ready after start"] = function(t)
    t.ok(mapped("(", "i"), "mini.pairs maps ( in insert mode")
    t.ok(mapped("a", "o") and mapped("i", "x"), "mini.ai maps a and i for operators and selections")
  end,
}
