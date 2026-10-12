local I = require("ach.icons")
local glyphs = require("ach.glyphs")

-- Every reference the database holds, with the colour beside it and where it sits.
local function references()
  local out = {}
  local function add(where, ref, colour) out[#out + 1] = { where = where, ref = ref, colour = colour } end
  for desc, e in pairs(I.keys) do
    add("keys[" .. desc .. "]", e[1], e[2])
  end
  for name, e in pairs(I.groups) do
    add("groups[" .. name .. "]", e[1], e[2])
  end
  for id, ref in pairs(I.toggles) do
    add("toggles[" .. id .. "]", ref, "green")
  end
  for i, e in ipairs(I.keywords) do
    add("keywords[" .. i .. "]", e[2], e[3])
  end
  for _, kind in ipairs({ "filetypes", "extensions", "filenames" }) do
    for name, e in pairs(I[kind]) do
      add(kind .. "[" .. name .. "]", e[1], e[2])
    end
  end
  return out
end

-- The first rule whose pattern finds the lower-cased description: which-key's own test.
local function first_rule(rules, desc)
  local lower = desc:lower()
  for _, rule in ipairs(rules) do
    if lower:find(rule.pattern) then
      return rule
    end
  end
end

-- The reference of the first keyword pattern that finds the description, or false.
local function keyword(desc)
  for _, rule in ipairs(I.keywords) do
    if desc:lower():find(rule[1]) then
      return rule[2]
    end
  end
  return false
end

return {
  ["every glyph is one character the font draws"] = function(t)
    local bad = {}
    local function check(where, glyph)
      local cps = type(glyph) == "string" and vim.fn.str2list(glyph, true) or {}
      if #cps ~= 1 or not glyphs.known(cps[1]) then
        bad[#bad + 1] = where
      end
    end
    for _, category in ipairs(I.vocabulary) do
      for name, glyph in pairs(I[category]) do
        check(category .. "." .. name, glyph)
      end
    end
    for i, glyph in ipairs(I.lazy_list) do
      check("lazy_list[" .. i .. "]", glyph)
    end
    table.sort(bad)
    t.eq(bad, {}, "glyphs the font does not draw")
  end,

  ["holds at least the foundation's 849 glyphs, 347 keys and 84 keywords"] = function(t)
    local total = 0
    for _, category in ipairs(I.vocabulary) do
      t.eq(type(I[category]), "table", "the table M." .. category)
      total = total + vim.tbl_count(I[category])
    end
    t.ok(#I.vocabulary >= 30, ("%d tables, at least 30 expected"):format(#I.vocabulary))
    t.ok(total >= 849, ("%d glyphs, at least 849 expected"):format(total))
    t.ok(vim.tbl_count(I.keys) >= 347, ("%d keys, at least 347 expected"):format(vim.tbl_count(I.keys)))
    t.ok(vim.tbl_count(I.groups) >= 18, ("%d groups, at least 18 expected"):format(vim.tbl_count(I.groups)))
    t.ok(vim.tbl_count(I.toggles) >= 19, ("%d toggles, at least 19 expected"):format(vim.tbl_count(I.toggles)))
    t.ok(#I.keywords >= 84, ("%d keywords, at least 84 expected"):format(#I.keywords))
  end,

  ["every reference names a glyph and every colour is one which-key draws"] = function(t)
    local colours, bad = {}, {}
    for _, c in ipairs(I.colors) do
      colours[c] = true
    end
    for _, r in ipairs(references()) do
      if not I.get(r.ref) then
        bad[#bad + 1] = r.where .. " names " .. tostring(r.ref)
      elseif not colours[r.colour] then
        bad[#bad + 1] = r.where .. " has the colour " .. tostring(r.colour)
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "broken references")
  end,

  ["descriptions that differ only in case share an icon and colour"] = function(t)
    local seen, bad = {}, {}
    local descs = vim.tbl_keys(I.keys)
    table.sort(descs)
    for _, desc in ipairs(descs) do
      local lower, icon = desc:lower(), I.key(desc)
      local other = seen[lower]
      if other and (other.icon ~= icon.icon or other.color ~= icon.color) then
        bad[#bad + 1] = desc
      end
      seen[lower] = other or icon
    end
    t.eq(bad, {}, "descriptions which-key cannot tell apart")
  end,

  ["which-key's first matching rule gives each listed key its own icon"] = function(t)
    local rules, bad = I.which_key_rules(), {}
    for desc in pairs(I.keys) do
      local want, got = I.key(desc), first_rule(rules, desc)
      if not got or got.icon ~= want.icon or got.color ~= want.color then
        bad[#bad + 1] = desc
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "keys that would draw another icon")
  end,

  ["every keyword is a valid pattern and routes the probe descriptions"] = function(t)
    for i, rule in ipairs(I.keywords) do
      t.ok(pcall(string.find, "", rule[1]), ("keywords[%d] %q is a valid Lua pattern"):format(i, rule[1]))
    end
    local probes = {
      ["Git Blame Line"] = "git.blame",
      ["Lazygit (Root Dir)"] = "git.lazygit",
      ["Format Injected Langs"] = "code.format",
      ["Run Nearest Test"] = "code.test",
      ["Toggle Breakpoint"] = "dap.Breakpoint",
      ["Mason"] = "mason.mason",
      ["Rename File"] = "code.rename",
      ["Goto Definition"] = "code.definition",
      ["Next Hunk"] = "git.hunk",
      ["Claude Code: Send Selection"] = "claude.claude",
      ["Markdown Preview"] = "ui.preview",
      ["Open Tab"] = "tabs.tab",
      ["Table of Contents"] = false,
      ["Run Last"] = "actions.run",
      ["Toggle AI"] = "claude.ai",
    }
    local wrong = {}
    for desc, want in pairs(probes) do
      local got = keyword(desc)
      if got ~= want then
        wrong[#wrong + 1] = ("%s gave %s, wanted %s"):format(desc, tostring(got), tostring(want))
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "keyword routing")
  end,

  ["the status icons contain no forbidden glyph"] = function(t)
    local bad = {}
    for name, glyph in pairs(I.status) do
      if #glyphs.offending(glyph) > 0 then
        bad[#bad + 1] = name
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "status icons the bar may not show")
  end,

  ["lazy.nvim draws the database's icons"] = function(t)
    local icons = require("lazy.core.config").options.ui.icons
    t.eq(icons.plugin, I.lazy.plugin .. " ", "the plugin icon")
    t.eq(icons.loaded, I.lazy.loaded, "the loaded marker")
    t.eq(icons.list, I.lazy_list, "the list bullets")
  end,

  ["a toggle takes its icon from the database, green when on and grey when off"] = function(t)
    local toggle = I.toggle({ opts = { id = "spell" } })
    t.eq(toggle.opts.icon, I.spell.spell, "the icon")
    t.eq(toggle.opts.color, { enabled = "green", disabled = "grey" }, "the colours")
    local other = I.toggle({ opts = { id = "not_in_the_database" } })
    t.eq(other.opts.icon, nil, "a toggle the database does not list keeps its own icon")
  end,

  ["the helpers return the shapes their plugins expect"] = function(t)
    t.eq(I.spaced({ a = "x" }), { a = "x " }, "spaced")
    t.eq(I.todo_keywords().TODO, { icon = I.todo.TODO .. " " }, "todo-comments")
    local mini = I.mini()
    t.eq(mini.filetype.verilog, { glyph = I.hardware.gate_and, hl = "MiniIconsGreen" }, "mini.icons by file type")
    t.eq(mini.extension.sv, { glyph = I.hardware.ic, hl = "MiniIconsGreen" }, "mini.icons by extension")
    t.eq(mini.file["lazy-lock.json"], { glyph = I.lazy.lazy, hl = "MiniIconsBlue" }, "mini.icons by file name")
  end,
}
