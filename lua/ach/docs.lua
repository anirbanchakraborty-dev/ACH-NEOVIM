-- What the documentation post says that the source cannot: its title and
-- summary, the short introductions above the generated sections, the category
-- and one-sentence description of every plugin in lazy-lock.json, each
-- language's debugger, and which key card section a key the card does not
-- name falls in. scripts/docs reads it, and tests/test_docs.lua fails while a
-- plugin in lazy-lock.json has no entry here. It is plain data, so it loads
-- without the configuration.
local M = {}

M.post = {
  title = "ACH-NEOVIM: My Neovim Configuration for macOS",
  summary = "How I set up Neovim on my Mac: installing it, every key, every plugin with its code, and every language,"
    .. " written from the configuration's own source.",
  tags = { "neovim", "lua", "editor", "macos" },
}

-- Markdown lines, copied into the post as they are. They hold no < > { },
-- which MDX would read as code.
M.intro = {
  note = {
    "I generate this page with `scripts/docs`, from the configuration's own source: the plugin specs, the language"
      .. " table, the keys the configuration sets, and four pages I write by hand in `docs/site/`. Edit the source,"
      .. " not this page.",
  },
  keymaps = {
    "Every key this configuration sets, with the description the menus show for it and the modes it works in,"
      .. " grouped the way the key card in `docs/key-card.md` groups them. A key is written the way it is pressed:"
      .. " `Space f f` is Space, then f, then f, and `Ctrl-h` is h pressed while Ctrl is held.",
    "",
    "The Mode column uses Neovim's one-letter names. n is normal mode, where keys move and edit. x is visual mode,"
      .. " after selecting text with `v`. s is select mode, which snippets use for the parts to fill in. o is"
      .. " operator-pending mode, after an operator such as `d` and before the motion that says what it acts on."
      .. " i is insert mode, for typing. c is the command line, after `:`. t is a terminal window.",
    "",
    "Inside Neovim each key also shows an icon. This page leaves the icons out, because they come from the"
      .. " JetBrains Mono Nerd Font and this website does not load that font, so each would draw as an empty box."
      .. " Keys a plugin sets only inside its own window, and text objects such as `i (` in `d i (`, are not listed"
      .. " here. Inside Neovim, `Space s k` searches every key, those included.",
  },
  plugins = {
    "Every plugin in `lazy-lock.json`, grouped by what it does. Each name links to the plugin's repository. The"
      .. " Options tab shows `opts`, the settings lazy.nvim hands to the plugin, and the Full Spec tab shows the"
      .. " whole spec: where the plugin comes from, when it loads, its keys and its options. Either one can be"
      .. " copied into a file in `lua/ach/plugins/`.",
    "",
    "Some plugins are set up in pieces, one in each file that needs a part of them, and each piece is shown with"
      .. " the file it lives in. A plugin that only comes in for another plugin's sake shows the line that brings it"
      .. " in.",
  },
  languages = {
    "One subsection for each entry in `lua/ach/languages.lua`. Nothing here is installed until a file of that"
      .. " language is opened. Then its Tree-sitter parser, its language servers, its formatters and its linters"
      .. " install in the background, without asking, and switch on when they are ready. A compiler or runtime"
      .. " that only Homebrew provides is asked about first, once, in one line that names it and its rough size.",
    "",
    "Each table names the parts: the file types the entry covers, the parsers that read its syntax, the language"
      .. " servers that check the code as it is typed, the formatters that tidy it on save, the linters that report"
      .. " problems, the debugger, and whether Harper, a grammar checker, reads it. The Entry tab is the language's"
      .. " entry in `lua/ach/languages.lua`. The Options tab, where there is one, holds its servers' settings from"
      .. " `lua/ach/servers.lua`.",
  },
}

-- LazyVim's nine categories, then this configuration's own.
M.categories = {
  "Coding",
  "Colorscheme",
  "Editor",
  "Formatting",
  "Linting",
  "LSP",
  "TreeSitter",
  "UI",
  "Util",
  "Debugging",
  "Language Plugins",
  "Git",
  "Claude Code",
  "LaTeX",
  "Markdown",
}

-- Every plugin in lazy-lock.json, by the name the lock gives it.
M.plugins = {
  ["snacks.nvim"] = {
    category = "Util",
    desc = "Many small tools in one plugin. Here it gives the file picker, the dashboard, notifications, toggles,"
      .. " the terminal, the file tree, indent guides, the git keys and the image previews.",
  },
  ["lazy.nvim"] = {
    category = "Util",
    desc = "The plugin manager. It installs each plugin at the commit `lazy-lock.json` names, and loads each one"
      .. " when it is first needed.",
  },
  ["plenary.nvim"] = {
    category = "Util",
    desc = "A library of Lua functions other plugins build on; octo.nvim needs it.",
  },
  ["persistence.nvim"] = {
    category = "Util",
    desc = "Saves which files were open in each folder, so `Space q s` brings them back.",
  },
  ["lazydev.nvim"] = {
    category = "Coding",
    desc = "Tells the Lua language server about Neovim's own Lua functions and the installed plugins, for"
      .. " completion and checking in these configuration files.",
  },
  ["blink.cmp"] = {
    category = "Coding",
    desc = "The completion menu, offering words from the language server, snippets, file paths and the open buffer.",
  },
  ["friendly-snippets"] = { category = "Coding", desc = "A collection of snippets for many languages." },
  ["mini.pairs"] = { category = "Coding", desc = "Types the closing bracket or quote when the opening one is typed." },
  ["mini.ai"] = {
    category = "Coding",
    desc = "Extends the `a` and `i` text objects, so `d i (` and its kind reach further, such as into the next pair.",
  },
  ["ts-comments.nvim"] = {
    category = "Coding",
    desc = "Makes `g c` use the right comment marker in a file that mixes languages.",
  },
  ["which-key.nvim"] = {
    category = "Editor",
    desc = "Shows the keys that can follow the ones already pressed, each with a description and an icon.",
  },
  ["flash.nvim"] = {
    category = "Editor",
    desc = "Jumps anywhere on the screen: `s`, then the first letters of the place, then the label shown there.",
  },
  ["grug-far.nvim"] = { category = "Editor", desc = "Search and replace across files, with a preview; `Space s r`." },
  ["trouble.nvim"] = {
    category = "Editor",
    desc = "Lists of problems, references and symbols to move through; `Space x x`.",
  },
  ["todo-comments.nvim"] = {
    category = "Editor",
    desc = "Highlights TODO, FIX, HACK and NOTE comments, and finds them all in a picker.",
  },
  ["oil.nvim"] = {
    category = "Editor",
    desc = "Shows a folder as a text buffer, where renaming a line renames the file; `Space f o`.",
  },
  ["multicursor.nvim"] = {
    category = "Editor",
    desc = "Several cursors that edit together; `Alt-Down` adds one on the line below.",
  },
  ["lualine.nvim"] = { category = "UI", desc = "The status bar along the bottom of the screen." },
  ["mini.icons"] = { category = "UI", desc = "An icon for each file type, folder and plugin." },
  ["edgy.nvim"] = {
    category = "UI",
    desc = "Keeps the side panels, such as the file tree, the problem list and the Claude Code panel, at fixed"
      .. " places and sizes.",
  },
  ["rainbow-delimiters.nvim"] = {
    category = "UI",
    desc = "Colours each level of nested brackets differently.",
  },
  ["mini.hipatterns"] = {
    category = "UI",
    desc = "Shows a colour code such as `#1a1b26` in the colour it names.",
  },
  ["tokyonight.nvim"] = {
    category = "Colorscheme",
    desc = "Tokyo Night, in its night style, with the navy background.",
  },
  ["conform.nvim"] = { category = "Formatting", desc = "Runs each language's formatters on save and on `Space c f`." },
  ["nvim-lint"] = { category = "Linting", desc = "Runs each language's linters and shows what they find." },
  ["nvim-lspconfig"] = {
    category = "LSP",
    desc = "Starting settings for each language server, added to from `lua/ach/servers.lua`.",
  },
  ["mason.nvim"] = {
    category = "LSP",
    desc = "Downloads language servers, formatters, linters and debuggers into Neovim's own folder, at the versions"
      .. " `mason-lock.json` names; `Space c m`.",
  },
  ["SchemaStore.nvim"] = {
    category = "LSP",
    desc = "The schemas that tell the JSON and YAML servers what a file such as `package.json` may hold.",
  },
  ["nvim-treesitter"] = {
    category = "TreeSitter",
    desc = "Installs the Tree-sitter parsers, which read each language's syntax for highlighting, indenting and"
      .. " selecting.",
  },
  ["nvim-treesitter-textobjects"] = {
    category = "TreeSitter",
    desc = "Text objects and moves by syntax: functions, classes and parameters.",
  },
  ["nvim-dap"] = { category = "Debugging", desc = "The debugger client: breakpoints, stepping and inspecting." },
  ["nvim-dap-ui"] = { category = "Debugging", desc = "The debugger's panels; `Space d u`." },
  ["nvim-nio"] = { category = "Debugging", desc = "A library for running Lua side by side, which nvim-dap-ui needs." },
  ["nvim-dap-virtual-text"] = {
    category = "Debugging",
    desc = "Shows each variable's value beside the code while the program is paused.",
  },
  ["mason-nvim-dap.nvim"] = {
    category = "Debugging",
    desc = "Reads which debug packages Mason has installed and sets up an adapter and launch choices for each.",
  },
  ["nvim-dap-python"] = { category = "Debugging", desc = "Debugs Python through debugpy." },
  ["rustaceanvim"] = {
    category = "Language Plugins",
    desc = "Starts rust-analyzer for Rust, adds Cargo's commands, and debugs through codelldb.",
  },
  ["haskell-tools.nvim"] = {
    category = "Language Plugins",
    desc = "Starts the Haskell language server, evaluates a module's examples, and debugs through hdb.",
  },
  ["nvim-jdtls"] = {
    category = "Language Plugins",
    desc = "Starts jdtls for Java, imports the project, and runs the debugger and the tests.",
  },
  ["nvim-metals"] = {
    category = "Language Plugins",
    desc = "Starts Metals for Scala, with its own debug server.",
  },
  ["lean.nvim"] = {
    category = "Language Plugins",
    desc = "Starts the Lean server and shows the proof state beside the file.",
  },
  ["gitsigns.nvim"] = {
    category = "Git",
    desc = "Change bars in the margin, and keys to move between changes and stage them; `] h` moves to the next.",
  },
  ["neogit"] = {
    category = "Git",
    desc = "git's status page inside Neovim, where changes are staged and committed; `Space g n`.",
  },
  ["diffview.nvim"] = {
    category = "Git",
    desc = "Every uncommitted change side by side, and a file's history; `Space g D`.",
  },
  ["octo.nvim"] = {
    category = "Git",
    desc = "GitHub's issues and pull requests, through `gh`; `Space g i` and `Space g p`.",
  },
  ["claudecode.nvim"] = {
    category = "Claude Code",
    desc = "Claude Code in a panel beside the code. It sees the open file and the selection, and shows each change"
      .. " it proposes side by side; `Space a c`.",
  },
  ["vimtex"] = {
    category = "LaTeX",
    desc = "Builds the PDF on `Space c b`, shows it in Skim, and jumps from the source to the PDF and back.",
  },
  ["render-markdown.nvim"] = {
    category = "Markdown",
    desc = "Draws headings, lists, tables and code blocks in place while a Markdown file is open.",
  },
  ["live-preview.nvim"] = {
    category = "Markdown",
    desc = "A preview in the browser that keeps up with the file as it changes; `Space c p`.",
  },
}

-- Which debugger serves each language, by its name in lua/ach/languages.lua.
M.debuggers = {
  c = "lldb-dap",
  swift = "lldb-dap",
  zig = "lldb-dap",
  rust = "codelldb",
  python = "debugpy",
  typescript = "js-debug",
  java = "java-debug and java-test",
  scala = "Metals' own debug server",
  haskell = "hdb",
  go = "delve",
  kotlin = "kotlin-debug-adapter",
  dotnet = "netcoredbg",
  php = "php-debug-adapter",
  elixir = "elixir-ls's debugger",
}

-- The key card section for a key the card does not name, by the start of the
-- key as the card spells it. The longest start that matches wins, and a key
-- no start matches goes under "Outside the menus".
M.key_sections = {
  { "Space Tab", "Windows and toggles" },
  { "Space u", "Windows and toggles" },
  { "Space w", "Windows and toggles" },
  { "Space a", "Claude Code" },
  { "Space b", "Files and buffers" },
  { "Space f", "Files and buffers" },
  { "Space q", "Files and buffers" },
  { "Space e", "Files and buffers" },
  { "Space E", "Files and buffers" },
  { "Space c", "Code" },
  { "Space x", "Code" },
  { "Space d", "Debugging" },
  { "Space g", "Git" },
  { "Space s", "Search and moving" },
  { "Space :", "Search and moving" },
  { "[", "Search and moving" },
  { "]", "Search and moving" },
  { "[ d", "Code" },
  { "] d", "Code" },
  { "[ e", "Code" },
  { "] e", "Code" },
  { "[ w", "Code" },
  { "] w", "Code" },
  { "[ q", "Code" },
  { "] q", "Code" },
  { "[ [", "Code" },
  { "] ]", "Code" },
  { "[ h", "Git" },
  { "] h", "Git" },
  { "g d", "Code" },
  { "g D", "Code" },
  { "g r", "Code" },
  { "g a", "Code" },
  { "g I", "Code" },
  { "g y", "Code" },
  { "K", "Code" },
  { "Ctrl-h", "Windows and toggles" },
  { "Ctrl-j", "Windows and toggles" },
  { "Ctrl-k", "Windows and toggles" },
  { "Ctrl-l", "Windows and toggles" },
}

return M
