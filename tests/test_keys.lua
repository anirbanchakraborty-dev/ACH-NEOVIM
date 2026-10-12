local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")
local I = require("ach.icons")

-- Every key a plugin spec declares, one entry per mode, in a stable order.
local function plugin_keys()
  local out = {}
  for name, plugin in pairs(Config.plugins) do
    for _, k in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
      k.plugin = name
      out[#out + 1] = k
    end
  end
  table.sort(out, function(a, b) return a.plugin .. a.id < b.plugin .. b.id end)
  return out
end

-- The which-key groups, found by walking the nested spec tables.
local function groups(spec, out)
  out = out or {}
  for _, item in ipairs(spec or {}) do
    if type(item) == "table" then
      if type(item[1]) == "string" and item.group then
        out[item[1]] = item.group
      end
      groups(item, out)
    end
  end
  return out
end

local function mapped(lhs, mode) return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil end

-- which-key hides a key with this description, so it never shows an icon.
local function shown(desc) return desc and desc ~= "" and desc ~= "which_key_ignore" end

-- The first of the icon database's which-key rules that finds the description.
local function database_icon(rules, desc)
  local lower = desc:lower()
  for _, rule in ipairs(rules) do
    if lower:find(rule.pattern) then
      return rule
    end
  end
end

-- Every description in which-key's presets: operators, motions, text objects and the rest.
local function preset_descs(spec, out)
  out = out or {}
  for k, v in pairs(spec) do
    if k == "desc" and type(v) == "string" then
      out[#out + 1] = v
    elseif type(v) == "table" then
      preset_descs(v, out)
    end
  end
  return out
end

return {
  ["keys set by this configuration all have descriptions"] = function(t)
    t.eq(require("ach.testhook").keymaps_without_desc, {}, "keys without a description")
  end,

  ["every plugin key has a description"] = function(t)
    local bare = {}
    for _, k in ipairs(plugin_keys()) do
      if not k.desc or k.desc == "" then
        bare[#bare + 1] = k.plugin .. ": " .. k.id
      end
    end
    t.eq(bare, {}, "plugin keys without a description")
  end,

  ["every Space key has a description"] = function(t)
    local bare = {}
    for _, mode in ipairs({ "n", "x", "o" }) do
      for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
        local lhs = vim.fn.keytrans(m.lhsraw or m.lhs)
        if lhs:find("^<Space>") and (m.desc == nil or m.desc == "") then
          bare[#bare + 1] = mode .. " " .. lhs
        end
      end
    end
    t.eq(bare, {}, "Space keys without a description")
  end,

  ["no core key replaces a plugin's key"] = function(t)
    local lost = {}
    for _, k in ipairs(plugin_keys()) do
      if not k.ft then
        local m = vim.fn.maparg(k.lhs, k.mode, false, true)
        if m.desc ~= k.desc then
          lost[#lost + 1] = ("%s %s from %s now reads %q"):format(k.mode, k.lhs, k.plugin, m.desc or "nothing")
        end
      end
    end
    t.eq(lost, {}, "plugin keys overridden")
  end,

  ["each Space menu has a which-key group"] = function(t)
    local wk = Config.plugins["which-key.nvim"]
    t.ok(wk, "which-key.nvim is in the plugin list")
    local have = groups(Plugin.values(wk, "opts", false).spec)
    local missing = {}
    local menus = { "<leader><tab>", "<leader>a", "<leader>b", "<leader>c", "<leader>d", "<leader>f" }
    vim.list_extend(menus, { "<leader>g", "<leader>m", "<leader>q", "<leader>s" })
    vim.list_extend(menus, { "<leader>u", "<leader>w", "<leader>x" })
    for _, lhs in ipairs(menus) do
      if not have[lhs] then
        missing[#missing + 1] = lhs
      end
    end
    t.eq(missing, {}, "Space menus without a group")
  end,

  ["which-key is loaded by the time the first key is pressed"] = function(t)
    t.ok(package.loaded["which-key"], "which-key loaded at VeryLazy")
  end,

  ["the keys the spec names exist"] = function(t)
    local want = {
      "<leader><space>",
      "<leader>ff",
      "<leader>fr",
      "<leader>fn",
      "<leader>fp",
      "<leader>fc",
      "<leader>bb",
      "<leader>bd",
      "<leader>bo",
      "<leader>sh",
      "<leader>sk",
      "<leader>sg",
      "<leader>uf",
      "<leader>uF",
      "<leader>uw",
      "<leader>us",
      "<leader>ul",
      "<leader>uh",
      "<leader>uu",
      "<leader>xl",
      "<leader>xq",
      "<leader>qq",
      "<leader>?",
      "<leader>ft",
      "<leader>cd",
    }
    local missing = {}
    for _, lhs in ipairs(want) do
      if not mapped(lhs) then
        missing[#missing + 1] = lhs
      end
    end
    t.eq(missing, {}, "keys the spec names")
  end,

  ["Space u f flips format on save"] = function(t)
    local m = vim.fn.maparg("<leader>uf", "n", false, true)
    t.ok(m.callback, "Space u f has a function behind it")
    local before = vim.g.autoformat
    m.callback()
    t.eq(vim.g.autoformat, not before, "after one press")
    m.callback()
    t.eq(vim.g.autoformat, before, "after two presses")
  end,

  ["Space u F flips format on save for this buffer only"] = function(t)
    local m = vim.fn.maparg("<leader>uF", "n", false, true)
    t.ok(m.callback, "Space u F has a function behind it")
    m.callback()
    t.eq(vim.b.autoformat, false, "the buffer is off after one press")
    t.ok(vim.g.autoformat ~= false, "the global setting is untouched")
    m.callback()
    t.eq(vim.b.autoformat, true, "the buffer is back on after two presses")
  end,

  ["the undo tree opens through packadd"] = function(t)
    vim.cmd.packadd("nvim.undotree")
    t.eq(vim.fn.exists(":Undotree"), 2, ":Undotree after packadd nvim.undotree")
  end,

  ["every key this configuration sets draws its own icon in which-key"] = function(t)
    local wk_icons = require("which-key.icons")
    local descs = {}
    for _, k in ipairs(require("ach.testhook").keymaps) do
      if shown(k.desc) then
        descs[k.desc] = true
      end
    end
    for _, k in ipairs(plugin_keys()) do
      if shown(k.desc) then
        descs[k.desc] = true
      end
    end
    local wrong = {}
    for desc in pairs(descs) do
      local want = I.key(desc)
      local icon, hl = wk_icons.get({ desc = desc })
      if not want then
        wrong[#wrong + 1] = desc .. ": no line in M.keys"
      elseif icon ~= want.icon or hl ~= "WhichKeyIcon" .. want.color:sub(1, 1):upper() .. want.color:sub(2) then
        wrong[#wrong + 1] = desc .. ": which-key draws another icon"
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "keys without their own icon")
  end,

  ["every key which-key can show has an icon from the database"] = function(t)
    local rules, descs = I.which_key_rules(), {}
    for _, mode in ipairs({ "n", "x", "o", "s" }) do
      for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
        if shown(m.desc) and not m.lhs:find("<Plug>", 1, true) then
          descs[m.desc] = mode .. " " .. vim.fn.keytrans(m.lhsraw or m.lhs)
        end
      end
    end
    for _, desc in ipairs(preset_descs(require("which-key.plugins.presets"))) do
      descs[desc] = descs[desc] or "which-key preset"
    end
    local bare = {}
    for desc, where in pairs(descs) do
      if not database_icon(rules, desc) then
        bare[#bare + 1] = where .. ": " .. desc
      end
    end
    table.sort(bare)
    t.eq(bare, {}, "keys the database gives no icon")
  end,

  ["every toggle and every which-key group draws the database's icon"] = function(t)
    local wk = Config.plugins["which-key.nvim"]
    t.ok(wk, "which-key.nvim is in the plugin list")
    local bad = {}
    for id, toggle in pairs(Snacks.toggle.toggles) do
      local ref = I.toggles[id]
      if not ref or toggle.opts.icon ~= I.get(ref) then
        bad[#bad + 1] = "toggle " .. id
      end
    end
    local function walk(spec)
      for _, item in ipairs(spec or {}) do
        if type(item) == "table" then
          if type(item[1]) == "string" and item.group then
            local want, got = I.group(item.group), item.icon
            if not want or type(got) ~= "table" or got.icon ~= want.icon or got.color ~= want.color then
              bad[#bad + 1] = "group " .. item.group
            end
          end
          walk(item)
        end
      end
    end
    walk(Plugin.values(wk, "opts", false).spec)
    table.sort(bad)
    t.eq(bad, {}, "toggles and groups without the database's icon")
  end,
}
