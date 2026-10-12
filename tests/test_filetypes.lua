-- File types. Neovim must recognise every language's sample, the file types it
-- cannot detect by itself are added, a parser that serves several file types
-- is registered for each, and every file type in the table has an icon of its
-- own rather than mini.icons' default.

local function samples(t)
  return dofile(t.root .. "/tests/fixtures/samples.lua")
end

-- Opens a file in a new buffer, returns the file type Neovim gave it, then
-- wipes the buffer so the next sample starts clean.
local function detect(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local ft = vim.bo.filetype
  vim.cmd("bwipeout!")
  return ft
end

return {
  ["every language has a sample, and every sample a language"] = function(t)
    local lang = require("ach.lang")
    local s = samples(t)
    local missing, extra = {}, {}
    for _, e in ipairs(lang.entries()) do
      if not s.samples[e.name] then
        missing[#missing + 1] = e.name
      end
    end
    for name in pairs(s.samples) do
      if not lang.get(name) then
        extra[#extra + 1] = name
      end
    end
    table.sort(missing)
    table.sort(extra)
    t.eq(missing, {}, "languages with no sample")
    t.eq(extra, {}, "samples with no language")
  end,

  ["each sample opens with a file type of its language"] = function(t)
    local lang = require("ach.lang")
    local s = samples(t)
    local wrong = {}
    for _, e in ipairs(lang.entries()) do
      if s.samples[e.name] then
        local ft = detect(s.write(t.tmpdir(), e.name))
        if not vim.tbl_contains(e.ft, ft) then
          wrong[#wrong + 1] = ("%s opened as %q"):format(e.name, ft)
        end
      end
    end
    t.eq(wrong, {}, "samples Neovim did not recognise")
  end,

  ["the file types Neovim lacks are added"] = function(t)
    local want = {
      ["a.bsv"] = "bsv",
      ["a.hlsl"] = "hlsl",
      ["a.hlsli"] = "hlsl",
      ["a.mdx"] = "markdown.mdx",
      ["a.mli"] = "ocamlinterface",
      ["a.veryl"] = "veryl",
      ["a.xdc"] = "xdc",
    }
    local got = {}
    for name in pairs(want) do
      got[name] = vim.filetype.match({ filename = "/work/" .. name })
    end
    t.eq(got, want)
  end,

  ["Helm templates, Ansible playbooks and compose files are recognised by name and place"] = function(t)
    local dir = t.tmpdir()
    vim.fn.mkdir(dir .. "/chart/templates", "p")
    vim.fn.writefile({ "apiVersion: v2", "name: sample", "version: 0.1.0" }, dir .. "/chart/Chart.yaml")
    t.eq(vim.filetype.match({ filename = dir .. "/chart/templates/service.yaml" }), "helm", "a template inside a chart")
    t.eq(vim.filetype.match({ filename = dir .. "/site/templates/page.yaml" }), "yaml", "a templates folder with no Chart.yaml")
    t.eq(vim.filetype.match({ filename = dir .. "/infra/playbooks/site.yml" }), "yaml.ansible", "a playbook")
    t.eq(vim.filetype.match({ filename = dir .. "/infra/roles/web/tasks/main.yml" }), "yaml.ansible", "a role's tasks")
    t.eq(vim.filetype.match({ filename = dir .. "/app/docker-compose.yml" }), "yaml.docker-compose", "a docker-compose file")
    t.eq(vim.filetype.match({ filename = dir .. "/app/compose.yaml" }), "yaml.docker-compose", "a compose file")
    t.eq(vim.filetype.match({ filename = dir .. "/app/settings.yaml" }), "yaml", "any other YAML file")
  end,

  ["a parser that serves several file types is registered for each"] = function(t)
    local want = {
      edn = "clojure",
      mysql = "sql",
      objcpp = "objc",
      plaintex = "latex",
      plsql = "sql",
      quarto = "markdown",
      rmd = "markdown",
      sdc = "tcl",
      xdc = "tcl",
    }
    local got = {}
    for ft in pairs(want) do
      got[ft] = vim.treesitter.language.get_lang(ft)
    end
    t.eq(got, want)
  end,

  ["every file type in the table has an icon of its own"] = function(t)
    local icons = require("mini.icons")
    local plain = {}
    for _, e in ipairs(require("ach.lang").entries()) do
      for _, ft in ipairs(e.ft) do
        local _, _, is_default = icons.get("filetype", ft)
        if is_default then
          plain[#plain + 1] = ft
        end
      end
    end
    table.sort(plain)
    t.eq(plain, {}, "file types drawn with mini.icons' default icon")
  end,
}
