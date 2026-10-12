-- Intel's manual on Space c x and newsboat on Space N. No test opens Skim or
-- newsboat: vim.system and snacks' terminal.toggle are replaced by recorders,
-- and the one test that reads the real manual runs only under --full.

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

-- Nine pages of made-up manual, laid out the way pdftotext prints the real
-- one: a form feed ends every page.
local function manual()
  return table.concat({
    -- 1: the title page, with no heading.
    "Intel 64 and IA-32 Architectures Software Developer's Manual",
    -- 2: a heading on the first line and Opcode on the next.
    "ADD—Add\nOpcode Instruction Op/En 64-bit Mode",
    -- 3: ADD's second page, which also carries its heading; the first is kept.
    "ADD—Add\nOpcode Instruction Op/En 64-bit Mode",
    -- 4: a family, with a blank line before Opcode.
    "CMOVcc—Conditional Move\n\nOpcode Instruction",
    -- 5: a running header above the heading, which names four instructions.
    "INSTRUCTION SET REFERENCE, A-L\nINT n/INTO/INT3/INT1—Call to Interrupt Procedure\nOpcode",
    -- 6: a heading with Opcode four lines below it, too far to count.
    "OPERATION—How to Read the Tables\nOne\nTwo\nThree\nOpcode is the first column",
    -- 7: the prefetch family.
    "PREFETCHh—Prefetch Data Into Caches\nOpcode",
    -- 8: two hyphens for the dash, and Opcode three lines below.
    "XOR -- Logical Exclusive OR\nVol. 2D\nTable 4-1\nOpcode",
    -- 9: the jumps, with opcode in lower case and indented.
    "Jcc—Jump if Condition Is Met\n   opcode instruction",
  }, "\f") .. "\f"
end

-- Writes a file standing in for the manual, so it has a size and a date.
local function stand_in(t, text)
  local pdf = t.tmpdir() .. "/sdm.pdf"
  vim.fn.writefile({ text or "a stand-in for the manual" }, pdf)
  return pdf
end

return {
  ["the index finds each instruction's first page, expands families and skips other pages"] = function(t)
    local index = require("ach.x86").parse(manual())
    t.eq(index.add, 2, "ADD's first page")
    t.eq(index.cmovne, 4, "CMOVNE, from the CMOVcc family")
    t.eq(index.cmovz, 4, "CMOVZ, from the same family")
    t.eq(index.cmovcc, nil, "a family's own name is not an instruction")
    for _, name in ipairs({ "int", "into", "int3", "int1" }) do
      t.eq(index[name], 5, name .. ", one of four names in a heading under a running header")
    end
    t.eq(index.operation, nil, "a heading with no Opcode close below it")
    t.eq(index.prefetch, 7, "PREFETCH")
    t.eq(index.prefetchnta, 7, "PREFETCHNTA")
    t.eq(index.xor, 8, "XOR, with two hyphens for the dash")
    t.eq(index.ja, 9, "JA, with opcode in lower case")
    t.eq(index.jrcxz, 9, "JRCXZ, one of the jumps beyond the condition codes")
    t.eq(index.intel, nil, "the title page")
  end,

  ["the index is built once, read back after that, and built again when the manual changes"] = function(t)
    local x86 = require("ach.x86")
    local pdf = stand_in(t)
    local runs, reply = {}, { code = 0, stdout = manual(), stderr = "" }
    local function build()
      local got, over = nil, false
      x86.index(pdf, function(index)
        got, over = index, true
      end)
      vim.wait(2000, function() return over end, 10)
      t.ok(over, "the index is handed back")
      return got
    end
    with({
      { x86, "cache", t.tmpdir() .. "/cache" },
      {
        vim,
        "system",
        function(cmd, _, on_exit)
          runs[#runs + 1] = cmd
          on_exit(reply)
          return {}
        end,
      },
    }, function()
      local said = notices(function() t.eq(build().add, 2, "the first call reads the manual") end)
      t.eq(runs, { { "pdftotext", "-q", "-enc", "UTF-8", pdf, "-" } }, "with pdftotext, printing to its output")
      t.eq(said[1].msg, "Reading Intel's manual to index it. This happens once.", "and says so")
      t.eq(build().add, 2, "the second call has the index")
      t.eq(#runs, 1, "without reading the manual again")
      vim.fn.writefile({ "a newer manual, which is longer than the first" }, pdf)
      reply = { code = 1, stdout = "", stderr = "Syntax Error: Couldn't find trailer dictionary" }
      local failed = notices(function() t.eq(build(), nil, "a manual pdftotext cannot read gives no index") end)
      t.eq(#runs, 2, "a changed manual is read again")
      t.eq(failed[#failed].level, vim.log.levels.ERROR, "the failure is an error")
      local msg = failed[#failed].msg
      t.ok(msg:find("pdftotext could not read " .. pdf, 1, true) ~= nil, "naming the program and the file")
    end)
  end,

  ["Space c x opens the manual at the instruction under the cursor, and otherwise asks which"] = function(t)
    local x86 = require("ach.x86")
    local pdf = stand_in(t)
    local runs, asked = {}, nil
    tidy(function()
      with({
        { vim.fn, "executable", only({ pdftotext = true, displayline = true }) },
        { x86, "pdf", pdf },
        {
          x86,
          "index",
          function(_, done) done({ xor = 8, add = 2 }) end,
        },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
        {
          vim.ui,
          "select",
          function(items, opts, choose)
            asked = { items = items, prompt = opts.prompt }
            choose("xor")
          end,
        },
      }, function()
        vim.cmd.enew()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "  add rax, 1" })
        vim.api.nvim_win_set_cursor(0, { 1, 3 })
        press("<leader>cx")
        t.eq(#runs, 1, "one program runs")
        t.eq(runs[1][1], "osascript", "osascript")
        t.eq(vim.list_slice(runs[1], #runs[1] - 1), { pdf, "2" }, "asking for ADD's page")
        t.eq(asked, nil, "and nothing is asked")
        vim.api.nvim_win_set_cursor(0, { 1, 7 })
        press("<leader>cx")
        t.eq(asked and asked.items, { "add", "xor" }, "on rax, every instruction is offered, in order")
        t.eq(asked and asked.prompt, "x86 instruction", "under a prompt that says what to pick")
        t.eq(#runs, 2, "and the pick runs osascript again")
        t.eq(vim.list_slice(runs[2], #runs[2] - 1), { pdf, "8" }, "for XOR's page")
      end)
    end)
  end,

  ["Space c x without the manual says where to put it and runs nothing"] = function(t)
    local x86 = require("ach.x86")
    local missing = t.tmpdir() .. "/intel-sdm.pdf"
    local runs, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({ pdftotext = true, displayline = true }) },
        { x86, "pdf", missing },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
      }, function()
        vim.cmd.enew()
        said = notices(function() press("<leader>cx") end)
      end)
    end)
    t.eq(#runs, 0, "nothing runs")
    t.eq(#said, 1, "one notice")
    t.eq(said[1].level, vim.log.levels.WARN, "a warning")
    t.ok(said[1].msg:find(missing, 1, true) ~= nil, "naming where the manual goes")
    t.ok(said[1].msg:find(x86.source, 1, true) ~= nil, "and where Intel publishes it")
  end,

  ["Space c x names Poppler and Skim when they are missing, and runs nothing"] = function(t)
    require("ach.x86")
    local runs, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({}) },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
      }, function()
        vim.cmd.enew()
        said = notices(function() press("<leader>cx") end)
      end)
    end)
    t.eq(vim.tbl_map(function(s) return s.msg end, said), {
      "Poppler is not installed. Install it with: brew install poppler",
      "Skim is not installed. Install it with: brew install --cask skim",
    }, "both install lines")
    t.eq(#runs, 0, "nothing runs")
  end,

  ["Skim is asked for the page through osascript, with the file and the page as arguments"] = function(t)
    local x86 = require("ach.x86")
    local odd = '/tmp/it\'s a "manual".pdf'
    local runs = {}
    with({
      {
        vim,
        "system",
        function(cmd)
          runs[#runs + 1] = cmd
          return {}
        end,
      },
    }, function() x86.open(odd, 42) end)
    local cmd = runs[1]
    t.eq(cmd[1], "osascript", "osascript runs the script")
    local lines = {}
    for i = 2, #cmd - 2, 2 do
      t.eq(cmd[i], "-e", "each line of the script follows -e")
      lines[#lines + 1] = cmd[i + 1]
    end
    t.eq(lines, x86.script, "the script, line by line")
    local script = table.concat(lines, "\n")
    t.ok(script:find("go theDoc to page", 1, true) ~= nil, "which tells Skim to go to a page")
    t.eq({ cmd[#cmd - 1], cmd[#cmd] }, { odd, "42" }, "the file and the page come last, as arguments")
    t.eq(script:find("it's", 1, true), nil, "and the file's name is nowhere in the script")
  end,

  ["the AppleScript that asks Skim for a page compiles"] = function(t)
    local x86 = require("ach.x86")
    if vim.fn.executable("displayline") ~= 1 then
      t.skip("Skim is not installed, and the script uses Skim's own commands")
    end
    local argv = { "osacompile", "-o", t.tmpdir() .. "/x86.scpt" }
    for _, line in ipairs(x86.script) do
      vim.list_extend(argv, { "-e", line })
    end
    local r = vim.system(argv, { text = true }):wait(30000)
    t.eq(r.code, 0, "osacompile accepts it: " .. (r.stderr or ""))
  end,

  ["the real manual gives a page for the instructions looked up most"] = function(t)
    if not t.full then
      t.skip("reads all of Intel's manual, which takes a while; scripts/check --full runs it")
    end
    local x86 = require("ach.x86")
    if vim.fn.executable("pdftotext") ~= 1 then
      t.human("install Poppler, which reads the manual: brew install poppler")
    end
    if vim.fn.filereadable(x86.pdf) ~= 1 then
      t.human(("save Intel's combined manual from %s as %s"):format(x86.source, x86.pdf))
    end
    local got, over = nil, false
    with({ { x86, "cache", t.tmpdir() } }, function()
      notices(function()
        x86.index(x86.pdf, function(index)
          got, over = index, true
        end)
        vim.wait(180000, function() return over end, 200)
      end)
    end)
    t.ok(over, "the manual is read within three minutes")
    t.ok(got ~= nil, "pdftotext reads it")
    for _, name in ipairs({ "add", "mov", "xor", "cmovne", "ja", "int3", "prefetchnta", "vbroadcastss" }) do
      t.ok(type(got[name]) == "number", name .. " has a page")
    end
    t.ok(got.add < got.xor, "ADD comes before XOR, as the manual is in alphabetical order")
  end,

  ["Space N opens newsboat in a floating terminal"] = function(t)
    local home = t.tmpdir()
    vim.fn.mkdir(home .. "/.newsboat", "p")
    vim.fn.writefile({ "https://rss.arxiv.org/rss/cs.AR" }, home .. "/.newsboat/urls")
    local opened = {}
    tidy(function()
      with({
        { vim.env, "HOME", home },
        { vim.env, "XDG_CONFIG_HOME", nil },
        { vim.env, "BROWSER", nil },
        { vim.fn, "executable", only({ newsboat = true }) },
        {
          Snacks.terminal,
          "toggle",
          function(cmd, opts) opened[#opened + 1] = { cmd = cmd, opts = opts } end,
        },
      }, function() press("<leader>N") end)
    end)
    t.eq(#opened, 1, "one terminal")
    t.eq(opened[1].cmd, "newsboat", "running newsboat")
    t.eq(opened[1].opts.win.position, "float", "in a floating window")
    t.eq(opened[1].opts.cwd, home, "started from the home folder, so pressing again finds the same one")
    t.eq(opened[1].opts.env, { BROWSER = "open" }, "and articles open in the default browser")
  end,

  ["Space N without newsboat prints the line that installs it and opens nothing"] = function(t)
    local opened, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({}) },
        {
          Snacks.terminal,
          "toggle",
          function(cmd) opened[#opened + 1] = cmd end,
        },
      }, function()
        said = notices(function() press("<leader>N") end)
      end)
    end)
    t.eq(said, {
      { msg = "newsboat is not installed. Install it with: brew install newsboat", level = vim.log.levels.WARN },
    }, "the install line")
    t.eq(#opened, 0, "nothing opens")
  end,

  ["the feed list is looked for where newsboat looks, and Space N names it when it is missing"] = function(t)
    local news = require("ach.news")
    local home = t.tmpdir()
    local opened, said = {}, {}
    with({
      { vim.env, "HOME", home },
      { vim.env, "XDG_CONFIG_HOME", nil },
    }, function()
      t.eq(news.urls(), home .. "/.newsboat/urls", "with no ~/.config/newsboat, the older place")
      vim.fn.mkdir(home .. "/.config/newsboat", "p")
      t.eq(news.urls(), home .. "/.config/newsboat/urls", "with that folder, the folder")
      vim.env.XDG_CONFIG_HOME = home .. "/elsewhere"
      t.eq(news.urls(), home .. "/.newsboat/urls", "XDG_CONFIG_HOME moves where the folder is looked for")
      vim.fn.mkdir(home .. "/elsewhere/newsboat", "p")
      t.eq(news.urls(), home .. "/elsewhere/newsboat/urls", "and the folder there is used")
      vim.env.XDG_CONFIG_HOME = "relative"
      t.eq(news.urls(), home .. "/.config/newsboat/urls", "a relative XDG_CONFIG_HOME is ignored, as newsboat does")
      tidy(function()
        with({
          { vim.fn, "executable", only({ newsboat = true }) },
          {
            Snacks.terminal,
            "toggle",
            function(cmd) opened[#opened + 1] = cmd end,
          },
        }, function()
          said = notices(function() press("<leader>N") end)
        end)
      end)
    end)
    t.eq(#opened, 0, "with no feed list, nothing opens")
    t.eq(#said, 1, "one notice")
    t.eq(said[1].level, vim.log.levels.WARN, "a warning")
    t.ok(said[1].msg:find(home .. "/.config/newsboat/urls", 1, true) ~= nil, "naming the file newsboat reads")
  end,
}
