# ACH-NEOVIM design

Written 2026-10-10 and revised the same day, when the owner asked for a distribution of its own that uses LazyVim as inspiration only. Revised again on 2026-10-11, when the owner chose installs that happen only when a file needs them, a question before any compiler is installed, and documentation as a blog post. A draft for the owner's review. Nothing described here is installed yet, and nothing will be until this document and the implementation plans that follow it are approved.

## What this is for

ACH-NEOVIM is a Neovim distribution for one person's Mac, kept in its own public repository. It is written from scratch on lazy.nvim, the plugin manager that LazyVim itself is built on. LazyVim is the reference it learned from, not a dependency: nothing here imports LazyVim, and every plugin is chosen and configured in this repository. Where LazyVim made a good choice, such as a plugin or a key layout that thousands of people already know, ACH-NEOVIM makes the same choice on purpose and configures it itself.

It is its owner's editor for code, LaTeX, Markdown and notes. It is maintained by Claude Code, working in the owner's sessions. Every change is tested before it is committed, and plugin versions move only when an update is made on purpose.

The work succeeds when five things are true:

- Every feature in the table under Features works, and together they cover everything the owner does in an editor apart from Org mode.
- Every programming language the owner might open gets the full set of help wherever a tool for it exists anywhere. That set is structure-aware highlighting, intellisense, completion, formatting, linting and grammar checking, and the languages include the hardware description languages.
- Claude Code works inside the editor as well as it does inside VS Code.
- Each way it claims to beat LazyVim, listed below, is backed by a test that passes.
- Someone else can install it from the documentation post alone, step by step, and reach the same setup.

Org mode is out of scope on purpose. Notes are Markdown. An agenda, capture templates and a linked-notes database are not imitated.

## Better than LazyVim, and how that is measured

"Better" is only worth claiming where it can be checked, so each claim below names the test that holds it.

- **It starts at least as fast, while configuring far more.** ACH-NEOVIM sets up roughly ninety languages, against the handful a stock LazyVim enables, and still has to start no slower than a stock LazyVim on the same Mac. The benchmark installs LazyVim's starter at a pinned commit into a throwaway folder, times both over ten starts each, and records the result. The test fails if ACH-NEOVIM's median start is slower.
- **Nothing downloads before it is needed.** LazyVim compiles a long list of parsers and installs a set of tools the first time it starts. Here nothing language-specific installs at first start. A language's parser, the parsers its highlighting borrows and its tools arrive the first time a real file in that language is opened, and only then. A compiler is never installed without asking first. The test starts from empty folders and checks that no parser beyond the ones Neovim ships with, and no language tool, is present until a file is opened.
- **One table describes every language.** LazyVim spreads its languages across 49 separate packs, each written its own way. Here every language is one entry in `lua/ach/languages.lua`: its file types, parser, servers, formatters, linters and debugger. Adding a language is adding an entry. A test checks every name in the table against the plugin that must recognise it, so a misspelt server or formatter fails the check instead of failing silently in use.
- **Everything is pinned.** Plugins, language tools and parser revisions are all locked, so a new Mac gets exactly what this one runs. LazyVim pins plugins only.
- **It is tested.** A headless test suite, described under Testing, runs before every commit. A personal configuration built on LazyVim has no such thing unless its owner writes one.
- **It says what is missing.** `:checkhealth ach` reports, language by language, which layers work, which tool is missing and the exact command that installs it.

## What is its own

These are the owner's touches, which no stock distribution has:

- the deep-navy theme and the ACH block-letter banner, with the research caption beneath it
- a status bar that shows more than LazyVim's, described below
- the hardware and systems languages treated as first-class rather than as afterthoughts: SystemVerilog, Verilog, VHDL, Veryl, Bluespec, timing constraints, assembly, LLVM IR, MLIR and their neighbours
- grammar checking through Harper, in prose and in code comments
- LaTeX books built with the owner's own build scripts, with Skim jumping between source and PDF
- a lookup that opens Intel's manual at the instruction under the cursor
- research feeds from IACR ePrint and arXiv in a reader inside the editor
- Claude Code in the editor, with its connection shown in the status bar
- a one-page key card and a description on every key, written for someone new to Neovim
- documentation generated from the configuration's own source, with the hand-written parts in the owner's voice, described under Documentation.

## Where it lives and how it is wired

The repository is `github.com/anirbanchakraborty-dev/ACH-NEOVIM`. It is public and MIT-licensed. Its code is written here. Where a function adapts one of LazyVim's, which is Apache-2.0 licensed, the file says so and the README credits LazyVim. On the owner's Mac it is checked out as a git submodule inside a private repository, and `~/.config/nvim` is a symbolic link to that checkout, so the repository is the configuration itself. Anyone else installs it by cloning it into `~/.config/nvim`.

Nothing writes into the repository while the editor runs, apart from the lock files when an update is made on purpose. Plugins live under `~/.local/share/nvim`. History, undo files, sessions and logs live under `~/.local/state/nvim`. These are Neovim's standard places.

Ghostty is the terminal window the editor runs in. Its settings live in the same repository, at `ghostty/config.ghostty`, with a link to it from `~/.config/ghostty/config.ghostty`, the name Ghostty 1.2 and later read first. They set:

- the font, JetBrains Mono Nerd Font
- the window background, to the theme's navy, so no seam shows around the editor
- the left Option key to act as Alt, with the right one still typing accented letters
- the sixteen terminal colours, the same ones the theme gives Neovim's own terminal.

Two committed lock files pin every version. `lazy-lock.json` covers the plugins, including nvim-treesitter, whose own commit fixes the revision of every parser it builds. `mason-lock.json` covers the language tools that Mason installs. The two parsers that come from outside nvim-treesitter, Veryl's and Bluespec's, are pinned by commit in the language table.

Anything specific to the owner's private repository stays in that repository. With `exrc` on, Neovim reads a trusted `.nvim.lua` file at the root of whatever folder it was started in. The private repository keeps its own such file, which is never copied here. It adds three things:

- a dashboard button for the notes folder
- opening generated files read-only, so a hand edit cannot be lost to the next build
- the build command for its LaTeX books.

The public repository names no private folder.

Homebrew installs Neovim, Ghostty and the command-line tools the configuration calls. Neovim is at 0.12.6 today, and the configuration requires 0.12 or later, because it uses Neovim's own server configuration interface and its built-in undo tree. The tools include the tree-sitter command-line program, which nvim-treesitter needs to build parsers, ImageMagick for drawing math and images, lazygit, newsboat and Skim. The owner's Mac setup script and its Brewfile record each one at the moment it is installed. Compilers and language runtimes are not among them. One installs only when a file needs it and the owner says yes, as described under Every language.

## How it looks

### Theme

The colour scheme is tokyonight in its `night` style, with the deep-navy overrides from Josean Martinez's post "How I Setup Neovim On My Mac To Make It Amazing in 2024". It is always navy. It does not follow macOS into light mode, because the palette exists only in dark.

| Role | Colour |
| --- | --- |
| Background | `#011628` |
| Darker panels: floating windows, popups, sidebar, status line | `#011423` |
| Cursor line | `#143652` |
| Search match | `#0A64AC` |
| Selection | `#275378` |
| Window borders | `#547998` |
| Text, and text in floating windows | `#CBE0F0` |
| Secondary text and sidebar text | `#B4D0E9` |
| Line numbers | `#627E97` |

The theme makes three changes on top of the post, each for legibility. Contrast was measured with the WCAG 2 formula, under which 4.5 to 1 is the usual floor for body text.

| What | From | To | Contrast before | Contrast after |
| --- | --- | --- | --- | --- |
| Comments, on the background | `#565f89` | `#7b84ac` | 2.96 | 5.00 |
| Comments, on the cursor line | `#565f89` | `#7b84ac` | 2.02 | 3.42 |
| Inlay hints and other quiet text (tokyonight's `dark3`) | `#545c7e` | `#6c759d` | 2.80 | 4.07 |
| Status line text in an inactive window (`semilightgray`) | undefined in the post | `#a9b1d6` | none | 6.17 on `#2c3043` |

Inlay hints are left just under 4.5 on purpose, because a hint should recede behind the code it annotates. For reference, body text measures 13.48, line numbers 4.32, text over a selection 5.96 and text over a search match 4.51.

The status line uses the post's lualine palette:

| Status line role | Colour |
| --- | --- |
| Blue | `#65D1FF` |
| Green | `#3EFFDC` |
| Violet | `#FF61EF` |
| Yellow | `#FFDA7B` |
| Red | `#FF4A4A` |
| Text | `#c3ccdc` |
| Background | `#112638` |
| Inactive window background | `#2c3043` |

Math and images rendered inside the editor are drawn in the text colour, `#CBE0F0`. A formula then reads as part of the page rather than as a pasted picture.

### Status bar

The status bar is a row of coloured blocks with square ends. Each block is a solid rectangle, and one blank cell of the bar's own navy separates neighbouring blocks, so the bar reads as tiles rather than as a ribbon of arrows. The outermost block on each side takes the colour of the current mode: blue in normal mode, green while inserting or in a terminal, violet while selecting, yellow on the command line and red while replacing.

From left to right it shows:

- the mode, with the Vim icon
- the git branch, and the lines added, changed and removed, each count with its own green, yellow or red icon
- the project folder, the file type's own coloured icon, the file's path relative to the project, a mark when the file is unsaved or read-only, and where the cursor sits in the code's structure, such as the function it is inside
- the count of errors, warnings, notes and hints, each in its own colour and shown only when it is not zero.

From the right edge inward it shows:

- the line and column, and how far through the file the cursor is
- the indentation in use, such as `SPC 4` or `TAB 4`, and the file's encoding and line endings only when they are not the usual UTF-8 and Unix ones
- a word count in Markdown, LaTeX, plain text and commit messages
- the language servers attached to the file, with a spinner while one is working, then the formatter that will run on save and the linter that is watching, so it is visible at a glance what is checking the code
- a violet `✦ Claude` when Claude Code is connected to this editor, dimmed when the editor is waiting for Claude Code to connect, and nothing when the integration is off
- a red recording dot with the register name while a macro is being recorded, the search position such as `3/17` while searching, and the size of the selection while selecting
- plugin updates waiting, and the debugger's state while debugging.

There is no clock, since the Mac's menu bar already shows one.

No icon in the status bar is an angle bracket, a chevron, an arrowhead or a triangle. This rule covers the status bar only. Everywhere else, plugins keep the icons they ship with. The test enforces it by drawing the status bar headless and checking every character against the Nerd Fonts 3.5.1 glyph names, so an icon that a plugin update swaps in is caught too. When a file type's own icon falls foul of the rule, as XML's angle-bracket icon does, the status bar shows a plain file icon in its place.

### Dashboard

The start screen's banner uses block lettering with a stippled drop shadow. The lettering follows one rule. Each cell of a five-by-seven letter grid is two characters wide, a filled cell is drawn as `██`, and an empty cell whose upper-left neighbour is filled gets the shadow `░░`. Over the letters of ACH NEOVIM it gives this:

```
                    ██████        ████████    ██      ██
                  ██  ░░░░██    ██  ░░░░░░░░  ██░░    ██░░
                  ██░░    ██░░  ██░░          ██░░    ██░░
                  ██████████░░  ██░░          ██████████░░
                  ██░░░░░░██░░  ██░░          ██░░░░░░██░░
                  ██░░    ██░░  ██░░          ██░░    ██░░
                  ██░░    ██░░    ████████    ██░░    ██░░
                    ░░      ░░      ░░░░░░░░    ░░      ░░

██      ██    ██████████      ██████      ██      ██    ██████    ██      ██
████    ██░░  ██░░░░░░░░░░  ██  ░░░░██    ██░░    ██░░    ██░░░░  ████  ████░░
██░░██  ██░░  ██░░          ██░░    ██░░  ██░░    ██░░    ██░░    ██░░██  ██░░
██░░  ████░░  ████████      ██░░    ██░░  ██░░    ██░░    ██░░    ██░░  ░░██░░
██░░    ██░░  ██░░░░░░░░    ██░░    ██░░  ██░░    ██░░    ██░░    ██░░    ██░░
██░░    ██░░  ██░░          ██░░    ██░░    ██  ██  ░░    ██░░    ██░░    ██░░
██░░    ██░░  ██████████      ██████  ░░      ██  ░░    ██████    ██░░    ██░░
  ░░      ░░    ░░░░░░░░░░      ░░░░░░          ░░        ░░░░░░    ░░      ░░
```

The letters are drawn in tokyonight blue, `#7aa2f7`, at 7.27 to 1 against the background. The shadow is the border colour, `#547998`.

Below the banner, from top to bottom, come:

- the caption: `░░  computer architecture · post-quantum cryptography  ░░`
- a row of buttons: find a file, recent files, projects, search text, the configuration, plugins, language tools and quit. A notes button is added by the private repository's `.nvim.lua` when the editor starts there
- the eight most recent files and eight projects
- a footer with a tip that changes at each start, and a line saying how many plugins loaded and how long startup took.

The tips say where the configuration and state live, how to see every key, and how to connect Claude Code.

## Features

Every row is a plugin this configuration chooses and configures itself. Most are the plugins LazyVim also picks, because they are the best available, and the configuration around them is written here.

| What it does | How |
| --- | --- |
| Search for anything | snacks picker: fuzzy search for files, text, buffers, help and keys, with a preview |
| Completion popup | blink.cmp |
| Act on text, jump to text | picker actions · flash.nvim, to jump anywhere on screen in two or three keys |
| Edit search results in place | grug-far: project-wide search and replace, edited in place |
| Grow a selection, edit in several places | selection that grows by syntax through Tree-sitter · multicursor.nvim |
| Undo history | Neovim's built-in undo tree · Neovim keeps undo history on disk itself |
| Spelling and grammar | Neovim's built-in spell checker for prose · Harper for grammar in prose and in code comments |
| Snippets | snippets through blink.cmp, including LaTeX snippets |
| Files and folders | oil.nvim, which edits a folder like a text file · snacks explorer, a file tree with git status |
| Projects | project picker · one Ghostty tab per project · a session saved per folder |
| Git | Neogit, a full git interface, with diffview · lazygit · gitsigns · octo.nvim for GitHub issues and pull requests through the existing `gh` login · file history · links to the current line on GitHub |
| Language servers, problems, formatting | Neovim's built-in language server client with Mason installers · trouble.nvim for the problem list · conform.nvim for formatting on save, with one rule per language |
| Debugging | nvim-dap and its interface: debugpy for Python, lldb-dap for C and C++ |
| Terminal | a terminal at the bottom from snacks, plus Ghostty splits |
| LaTeX | VimTeX with Skim, a free PDF viewer: build, and jump from source to PDF and back, using the existing book build scripts |
| Markdown | render-markdown, which draws headings, tables and checkboxes in place · math and images drawn inside the editor · a browser preview |
| x86 instruction lookup | a small command that opens Intel's manual in Skim at the instruction under the cursor |
| Research feeds | newsboat in a floating terminal, with the owner's research feeds |
| Keys and help | which-key with icons · searchable keys and help |
| Status line and visual aids | lualine as described above · snacks indent guides · rainbow-delimiters · colour swatches · todo-comments |
| Docked panels | edgy.nvim: help, terminal and diagnostics dock into fixed panes |
| Option as Alt, text size | Ghostty settings |
| Claude Code | claudecode.nvim: Claude Code inside the editor, described below |

## Every language

Each language gets six layers, wherever a tool for that layer exists:

- **Highlighting** comes from a Tree-sitter parser. The parser reads the code's structure rather than matching keywords, and it also drives folding, indentation and growing a selection by syntax.
- **Intellisense** comes from the language's own language server, through Neovim's built-in client. It covers completion, jumping to a definition, listing references, documentation on hover, help with a function's arguments, rename, code actions and inlay hints.
- **Completion** is drawn by blink.cmp as you type. It is fed by the language server, by snippets, by file paths and by words already in the open files.
- **Formatting** runs on save through conform.nvim, using the language's standard formatter, one choice per language, recorded in the table.
- **Linting** means warnings as you type. They come from the language server's own diagnostics, plus nvim-lint for linters that stand alone.
- **Grammar and spelling** come from Harper and Neovim's spell checker. Harper runs on the Mac, and its language server installs through Mason the first time a file it reads is opened. It checks grammar in whole Markdown, LaTeX and commit-message files, and in the comments of most programming languages, among them C, C++, Python, Rust, Go, Java, Scala, Haskell and shell scripts. The languages table records which languages' comments it actually reads. The spell checker covers spelling in prose.

Every language is one entry in a single table, `lua/ach/languages.lua`, and a small engine turns that table into the settings each plugin needs. The list starts from every language LazyVim 16.0.1 has a pack for, 49 of them, rewritten as entries in that table. A hardware and systems set comes on top:

- SystemVerilog and Verilog through Verible, which gives a language server, a linter and a formatter. nvim-treesitter's `systemverilog` parser highlights both, since SystemVerilog contains Verilog. Mason also carries slang-server, the alternative if Verible's diagnostics fall short.
- VHDL through rust_hdl, whose server is `vhdl_ls`.
- Veryl through its own language server, veryl-ls. nvim-treesitter has no Veryl parser, so the parser is built from the Veryl project's own grammar, `veryl-lang/tree-sitter-veryl`, pinned by commit.
- Chisel and SpinalHDL through Scala's language server, Metals, which the nvim-metals plugin installs itself rather than through Mason.
- Amaranth and cocotb through Python.
- Clash through Haskell's language server.
- SystemC and CUDA through clangd.
- Tcl, timing-constraint files, device trees, linker scripts, LLVM IR, MLIR, TableGen and FIRRTL. nvim-treesitter has a parser for each, timing constraints being Tcl, and Tcl also gets the tclint linter and its server from Mason.
- Assembly for x86, Arm and RISC-V, through asm-lsp from Mason, with the `asm` and `nasm` parsers for highlighting.

The table also covers languages LazyVim has no pack for, among them shell scripts, Perl, Swift, HTML, CSS, Makefiles, Protocol Buffers, GraphQL, GLSL, HLSL, WGSL, Starlark, just, Meson, Ninja and Kconfig. The plan lists every entry.

A language's parser and tools install themselves the first time a file of that language is opened, so the Mac does not carry hundreds of servers that are never used. The parsers that the file's highlighting borrows install with it, such as the regular-expression parser inside JavaScript or the YAML parser for a Markdown file's front matter. Neovim ships parsers for C, Lua, Markdown, Vimscript, its help pages and Tree-sitter queries, so its own help needs nothing. That first open needs the network and takes from a few seconds to a minute. The file opens straight away and the help arrives when the install finishes. Only a file on disk starts an install. A preview in the picker, a help page or a scratch buffer starts nothing.

Some languages need a compiler or runtime that only Homebrew provides, such as GHC for Haskell, a Java runtime for Java and Scala, or Go, Julia and Zig. Those are never installed up front and never silently. The first time a real file needs one, the editor asks once, in one line that names the language, the Homebrew packages and their rough installed size. The sizes are approximate figures written into the table, not measurements. On yes, Homebrew installs it in the background while editing carries on, one Homebrew run at a time because Homebrew allows only one, and the language's tools start when it finishes. On no, the editor does not ask about that runtime again for the rest of the session. Something Homebrew cannot install, such as Apple's command-line developer tools, gets only its command printed. `:checkhealth ach` names every missing runtime with the command that installs it, and `scripts/on-demand` prints every Homebrew formula the editor may offer, so a Mac setup script can declare them without installing them.

Some languages have no tool for a layer anywhere. Bluespec is the main case. nvim-treesitter has no Bluespec parser and Mason has no Bluespec server. The community grammar `yuyuranium/tree-sitter-bsv` is tried, pinned by commit, and kept only if it passes the test. Otherwise Bluespec gets classic syntax colouring only. Nothing is claimed beyond what is delivered. The full test writes `docs/languages.md`, a table with one row per language that names the tool behind each layer or says that none exists. The test fails if a layer that worked before stops working.

## Claude Code inside the editor

The integration is claudecode.nvim, from Coder, configured here directly. It speaks the same protocol Claude Code uses with its VS Code extension. Through it:

- Claude sees which file is open, the text that is selected and the diagnostics on screen.
- A file or selection can be sent to Claude with one key.
- When Claude proposes a change to a file, the change opens in Neovim as a side-by-side comparison. One key accepts it and another rejects it.
- Claude Code runs in a panel beside the code. Claude Code started in a Ghostty split connects to the same editor through its `/ide` command.
- The status bar shows whether Claude Code is connected.

The keys follow LazyVim's layout under `Space a`, so instructions written for either apply:

| Key | Does |
| --- | --- |
| `Space a c` | open or close the Claude Code panel |
| `Space a f` | move the cursor into the panel |
| `Space a r` | resume an earlier conversation |
| `Space a C` | continue the most recent conversation |
| `Space a b` | add the current file to the conversation |
| `Space a s` | send the selection, or add the file under the cursor in the file tree |
| `Space a a` | accept the proposed change (saving with `:w` does the same) |
| `Space a d` | reject it (closing with `:q` does the same) |

It is the same Claude Code command-line program in either case, so its settings, permissions, hooks and project instructions apply unchanged. The plugin's server binds only to `127.0.0.1`, so nothing else on the network can reach it. It also rejects any connection that does not carry the random 128-bit token it writes to a lock file under `~/.claude/ide/`.

Inline AI completion of the kind Copilot offers is not part of this.

## Keys, and how they are taught

Space is the leader key. Press it, pause, and which-key draws every next key with a word and an icon. The layout follows LazyVim's, because it is well designed and widely documented, so a tutorial written for LazyVim mostly works here too. The menus are these:

| Space menu | For |
| --- | --- |
| `Space f` | find, recent, new, the file tree, projects (`Space f p`) |
| `Space b` | switch, close, close others |
| `Space s` | this file, the project, help, keys, symbols |
| `Space g` | Neogit, lazygit, blame, hunks, history, GitHub |
| `Space c` | code actions, rename, format, LaTeX build |
| `Space x` | the problem list for this file and the project |
| `Space u` | line numbers, wrap, spelling, inlay hints, format on save |
| `Space s h`, `Space s k` | help pages, every key |
| `Space d` | debugging: breakpoints, step, inspect |
| `Space q` and Ghostty tabs | sessions per folder, one tab per project |
| `Space a` | Claude Code |

Every key the configuration defines carries a description, and a test fails if one does not, so which-key never shows a bare command. A one-page key card, `docs/key-card.md`, sets out the idea, the menus, the keys used every day, the keys outside the menus, and the few things that catch people out.

Ghostty's own keys are named alongside: `Command-T` for a new tab, `Command-D` to split to the right, `Command-Shift-D` to split downward, `Command-equals` and `Command-minus` for text size, and `Command-0` to reset it.

How Claude teaches: the owner is new to Neovim. Whenever Claude guides a step, it writes each key and what it does, every time, even for a key used the day before. Each step also points at the two aids: Space-and-pause, and the key card.

## Testing

`scripts/check` runs Neovim headless, with no window, against the real configuration, and exits 0 when everything passes, 1 on a failure, and 2 when something needs a human, such as a missing runtime. The fast mode is meant to finish in about a minute. It checks these:

- The configuration loads with no errors or warnings.
- Every plugin in `lazy-lock.json` is installed at its locked commit and loads.
- Startup time is measured over ten starts, and the median must stay within one and a half times the baseline recorded on the first passing run, which is committed in `tests/baseline.json`, and no slower than the stock LazyVim median recorded beside it.
- Starting from empty folders installs no parser beyond Neovim's own and no language tool. Opening a sample file then requests only that language's parser, the parsers its highlighting borrows and its tools. A picker preview or a help page requests nothing, and a missing compiler is asked about, never installed silently.
- The colours actually set match the tables above, and the contrast figures recomputed from them meet the stated values.
- The status bar draws its blocks in the stated colours and contains no forbidden icon.
- The banner file matches what the lettering rule produces.
- The dashboard draws all its parts.
- Every key the configuration defines has a description.
- Every name in the language table is known to the plugin that must use it, and each language's sample file in `tests/fixtures/` gets its file type and its parser.
- claudecode.nvim starts its server bound to `127.0.0.1` alone, writes its lock file and stops cleanly. No request is sent to Claude.

The full mode, `scripts/check --full`, also installs every language's parsers and Mason tools. It never installs a compiler or runtime through Homebrew. A language whose runtime is absent is recorded in `docs/languages.md` as needing it, which is not a failure. It then confirms on each sample file that the server attaches, the formatter changes a deliberately misformatted line and the linter reports a deliberately planted warning. Last, it rewrites `docs/languages.md`. It takes much longer and runs after every update.

The private repository's test runner calls the fast mode.

## Maintenance

Updates happen when the owner asks, or when a check starts failing. An update follows the same procedure every time:

- Read the change logs of the plugins that would move, and LazyVim's, since LazyVim usually adapts to a breaking plugin change within days and its fix shows what changed.
- Update plugins and Mason tools in a headless run.
- Run the full check.
- Commit both lock files with a message that says what moved.

If anything fails, the lock files are restored, which puts every plugin back where it was, and the failure is reported rather than worked around. Neovim itself updates through Homebrew, and the fast check runs after each `brew upgrade` that moves it.

## Documentation

The configuration is documented in one post on the owner's website, at `/blog/ach-neovim`, laid out the way lazyvim.org documents LazyVim. It has seven sections: Getting Started, Installation step by step, What's New, Keymaps, Configuration, Plugins grouped by category, and Languages, with one subsection per language. Every plugin shows the code someone would copy to get it, in two tabs, as LazyVim's pages do. **Options** holds the plugin's `opts` table, and **Full Spec** holds the whole lazy.nvim spec. Every language shows its entry in the language table the same way, with a second tab for its servers' settings wherever it has any.

The post is generated, not written by hand. `scripts/docs --out <file>` reads the configuration's own source with the Lua parser Neovim ships, and prints the exact text of each spec, so the code on the page is the code that runs and the post cannot drift from the repository. Run twice at the same commit, it writes the same bytes. The key tables come from a snapshot of the keys Neovim really has mapped, spelled the way the key card spells them. `scripts/check --keymaps` refreshes the snapshot, and a test fails when the two disagree. They leave out the icons, because the website does not load a Nerd Font. A test fails when a plugin in `lazy-lock.json` has no description and category, so a new plugin cannot go undocumented.

Getting Started, Installation, What's New and Configuration are hand-written, in `docs/site/`, and the generator splices them in. They are in the owner's own voice, in the first person, and tell the reader plainly what to do and what not to do. Every one of those instructions rests on something the configuration actually does.

The terminal the editor runs in, Ghostty with zsh, gets its own post on the same site, built around the owner's public Mac setup script, which installs it.

Nothing public changes until the owner has read the final text and said yes.

## Not included

- Org mode and everything built on it.
- A light theme.
- Inline AI completion.
- Continuous integration on GitHub, since the language tools are too heavy to install on every push and the checks run on the owner's Mac.
- Support for systems other than macOS, although nothing here deliberately breaks Linux.

## Risks

**Owning every piece.** Without LazyVim underneath, nobody upstream fixes this configuration when a plugin changes. The lock files mean nothing changes by surprise, the tests catch what an update breaks, and LazyVim's own fixes serve as a guide to what changed.

**Tree-sitter churn.** nvim-treesitter rewrote itself on a new main branch, and its interface is still moving. The lock file pins it, and an update that breaks a parser shows up in the full check.

**Young HDL tools.** Some hardware tools are young, Veryl's server above all, and may lag their language. The languages table records what actually works.

**Terminal support for math and images.** Math and images inside the editor need the kitty graphics protocol. Ghostty has it and macOS Terminal does not, so they appear only in Ghostty.

**Claude Code integration.** claudecode.nvim is a third-party plugin following a protocol Anthropic has not published as a standard. A Claude Code update can break it before the plugin catches up. The fast check catches a server that fails to start, but not a protocol change. That shows as `/ide` failing to connect, and the fix is a plugin update.
