# Neovim Configuration Repository

## Project Overview

A comprehensive, auto-installing Neovim configuration for macOS. One-command `install.sh` sets up everything (Neovim, dependencies, fonts). The config auto-installs LSP servers, formatters, and treesitter parsers on first launch — zero manual tool installation. Targets 23+ languages.

**Platform:** macOS only (Homebrew + npm for package management)
**Terminal:** iTerm2 with MesloLGS NF (Nerd Font — fully compatible, do NOT change or reinstall fonts)
**Neovim version:** Latest stable (dynamically validated against GitHub releases API)

---

## Git Rules

- **NEVER** add `Co-Authored-By: Claude` or any Claude/AI attribution to commit messages
- The repository author is Anirban — all commits should reflect only their authorship
- Do not add AI-generated disclaimers to any files

---

## File Structure

```
ACH-NEOVIM/
├── install.sh                  # One-command installer (checks deps before installing)        [done]
├── uninstall.sh                # Clean removal script                                         [done]
├── .gitignore                                                                                 [done]
├── LICENSE                                                                                    [done]
├── README.md                                                                                  [done]
├── CLAUDE.md                   # Project instructions for AI assistants                       [done]
└── nvim/
    ├── init.lua                # Entry point — require("config.lazy")                         [done]
    └── lua/
        ├── config/
        │   ├── icons.lua       # Central Nerd Font icon definitions (single source of truth)  [done]
        │   ├── lazy.lua        # Bootstrap lazy.nvim + load plugins/                          [done]
        │   ├── options.lua     # Neovim options (leader=Space, relative numbers, etc.)        [done]
        │   ├── keymaps.lua     # Global keymaps                                               [todo]
        │   └── autocmds.lua    # Autocommands                                                 [todo]
        └── plugins/
            ├── colorscheme.lua # tokyonight (custom deep ocean palette)                       [done]
            ├── ui.lua          # snacks.nvim (dashboard + indent), noice, rainbow-delimiters, nvim-colorizer  [done]
            ├── lualine.lua     # lualine.nvim (custom ocean theme, no separators)             [done]
            ├── editor.lua      # fzf-lua (fuzzy finder)                                       [done]
            ├── coding.lua      # blink.cmp, mini.pairs, mini.surround, mini.ai, ts-comments, nvim-ts-autotag [todo]
            ├── lsp.lua         # mason + mason-lspconfig + mason-tool-installer + nvim-lspconfig              [todo]
            ├── treesitter.lua  # nvim-treesitter + textobjects (37+ parsers, auto_install=true)               [todo]
            ├── formatting.lua  # conform.nvim (format-on-save, 23+ language formatters)                       [todo]
            ├── linting.lua     # nvim-lint (eslint_d, ruff, shellcheck)                                       [todo]
            ├── terminal.lua    # toggleterm.nvim (float/h/v/tab + 8 language REPLs + build/run)               [todo]
            └── util.lua        # gitsigns, persistence.nvim, vim-sleuth                                       [todo]
```

---

## Architecture Decisions

### Native Neovim APIs
- Uses Neovim's **native built-in LSP client** (`vim.lsp`) — `nvim-lspconfig` is just a convenience config layer
- Diagnostics flow through `vim.diagnostic` (native) — `nvim-lint` feeds into the same system
- Formatting uses `conform.nvim` which hooks into native formatter infrastructure

### Plugin Stack (LazyVim 14+ modern standards)
| Component | Plugin | Why |
|-----------|--------|-----|
| Plugin manager | lazy.nvim | De facto standard, auto-bootstrap |
| Completion | blink.cmp | Rust-powered, faster than nvim-cmp, LazyVim 14+ default |
| Fuzzy finder | fzf-lua | Faster than telescope, LazyVim 14+ default — NOT telescope |
| File explorer | neo-tree.nvim | More flexible than nvim-tree |
| Dashboard | snacks.dashboard | LazyVim 14+ default |
| Terminal | toggleterm.nvim | Multiple orientations + named instances for language REPLs |
| Statusline | lualine.nvim | Custom-themed to match ocean colorscheme |
| Git | gitsigns.nvim + lazygit.nvim (via snacks) | Gutter signs + full TUI |
| Formatting | conform.nvim | Modern standard, replaced null-ls |
| Linting | nvim-lint | Async, feeds into native diagnostics |
| Comments | ts-comments.nvim | Treesitter-aware, handles embedded languages |
| Colorscheme | tokyonight.nvim | Custom deep ocean palette (NOT default tokyonight) |

### Special Cases
- **Swift (sourcekit-lsp):** NOT available in mason — configured directly via lspconfig pointing to system Xcode binary (`xcrun sourcekit-lsp`)
- **R language server:** Requires R runtime — optional dependency in install script
- **Nerd Font icons throughout:** Using Nerd Font glyphs (NOT emoji) for WhichKey, LSP diagnostics, lualine, file explorer, completion menu, etc.

---

## Custom Colorscheme — Deep Ocean Palette

Applied via tokyonight `on_colors` callback:
```
bg = "#011628"           -- deep navy background
bg_dark = "#011423"      -- floats/sidebars/popups/statusline
bg_highlight = "#143652" -- highlighted lines
bg_search = "#0A64AC"    -- search matches
bg_visual = "#275378"    -- visual selection
fg = "#CBE0F0"           -- main text
fg_dark = "#B4D0E9"      -- dimmer text for sidebars
fg_gutter = "#627E97"    -- line numbers / gutter
border = "#547998"       -- window borders
```

---

## Install Script Design (`install.sh`)

**Key principle:** Check each dependency before installing — `command -v` for CLI tools, `brew list` for casks. Never reinstall what's already present.

```bash
install_if_missing() {
  if ! command -v "$1" &>/dev/null; then
    echo "Installing $1..."
    brew install "$2"
  else
    echo "$1 already installed, skipping."
  fi
}
```

### Neovim Version Validation
1. Fetch latest stable from GitHub API: `curl -s https://api.github.com/repos/neovim/neovim/releases/latest`
2. Compare installed version via `sort -V`
3. If Homebrew lags: download release binary from GitHub (arm64 or x86_64 based on `uname -m`)
4. Final validation: abort with clear error if version doesn't match

### Core Dependencies (Homebrew)
neovim, ripgrep, fd, fzf, lazygit, node, python3, go, lua, luarocks, tree-sitter, cmake

### Optional Dependencies (prompted)
r, perl, ruby, basictex/mactex, verible, swift (Xcode CLI tools)

### Font Detection
- Scan for existing Nerd Fonts (MesloLGS NF, JetBrainsMono Nerd, FiraCode Nerd, Hack Nerd, etc.)
- If found: skip font install (MesloLGS NF is fully compatible)
- If not found: `brew install --cask font-jetbrains-mono-nerd-font`

### Config Installation
- Backup existing `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` with timestamp
- Symlink: `ln -s /path/to/repo/nvim ~/.config/nvim`

---

## LSP Servers (auto-installed via mason)

| Language | LSP Server | Formatter | Linter |
|----------|-----------|-----------|--------|
| Lua | lua_ls | stylua | — |
| TypeScript/JS | ts_ls | prettierd/prettier | eslint_d |
| HTML | html + emmet_ls | prettierd/prettier | — |
| CSS/SCSS | cssls | prettierd/prettier | — |
| JSON | jsonls (+ schemastore) | prettierd/prettier | — |
| YAML | yamlls (+ schemastore) | prettierd/prettier | — |
| Markdown | marksman | prettierd/prettier | — |
| MDX | mdx_analyzer | prettierd/prettier | — |
| Python | pyright + ruff | ruff_format/black | ruff |
| R | r_language_server | styler | — |
| Bash/Zsh | bashls | shfmt | shellcheck |
| C/C++ | clangd | clang-format | — |
| Go | gopls | goimports + gofumpt | — |
| LaTeX | texlab | latexindent | — |
| BibTeX | texlab | bibtex-tidy | — |
| Swift | sourcekit-lsp (SYSTEM) | swift_format | — |
| Ruby | ruby_lsp | rubocop | — |
| Perl | perlnavigator | perltidy | — |
| Verilog/SV | verible | verible | — |
| VHDL | vhdl_ls | — | — |

---

## Treesitter Parsers (auto-installed)

```
bash, bibtex, c, cpp, css, diff, gitignore, go, gomod, gosum, gowork,
html, javascript, json, json5, jsonc, latex, lua, luadoc, luap,
markdown, markdown_inline, perl, python, r, regex, ruby, scss,
swift, toml, tsx, typescript, verilog, vhdl, vimdoc, xml, yaml, zig
```
Plus `auto_install = true` for any unlisted parsers.

---

## WhichKey — Full Keymap Reference

Every category, subcategory, and individual keymap has a Nerd Font icon.

### Top-level Categories
```
<leader>b  →  󰓩  Buffer         <leader>c  →    Code
<leader>d  →    Debug          <leader>e  →    Explorer
<leader>f  →    File/Find      <leader>g  →  󰊢  Git
<leader>l  →  󰒲  Lazy           <leader>m  →    Mason
<leader>q  →    Session        <leader>r  →    Run/Build
<leader>s  →    Search         <leader>t  →    Terminal
<leader>u  →    UI/Toggle      <leader>w  →    Window
<leader>x  →  󰙅  Diagnostics
```

### Buffer `<leader>b`
```
bd →   Delete Buffer       bD →   Delete Buffer & Window
bp → 󰐃 Toggle Pin          bP →   Close Non-Pinned
bo → 󰮘 Close Others        bl →   Delete Left
br →   Delete Right
```

### Code `<leader>c`
```
ca → 󰌵 Code Action         cr →   Rename Symbol
cf → 󰉢 Format              cl →   LSP Info
cd →   Line Diagnostics    cs →   Document Symbols
cS →   Workspace Symbols
```

### File/Find `<leader>f`
```
ff →   Find File           fn →   New File
fr → 󰋚 Recent Files        fc →   Config Files
fw →   Grep Word           fg → 󰊄 Live Grep
fb → 󰓩 Buffers             fh → 󰋖 Help Tags
```

### Git `<leader>g`
```
gg → 󰊢 Lazygit             gG → 󰊢 Lazygit (cwd)
gb →   Blame Line          gB → 󰖬 Browse (GitHub)
gf →   File History        gl →   Log
gh →   Hunks (subcategory)
```

### Git Hunks `<leader>gh` (subcategory)
```
ghs →   Stage Hunk         ghr → 󰜺 Reset Hunk
ghS →   Stage Buffer       ghu →   Undo Stage
ghp →   Preview Hunk       ghb →   Blame Line
ghd →   Diff This          ghD →   Diff This ~
```

### Session `<leader>q`
```
qs →   Restore Session     ql → 󰋚 Last Session
qd → 󰅗 Don't Save Session  qq → 󰗼 Quit All
```

### Run/Build `<leader>r`
```
rb →   Build/Compile       rr →   Run File
rt →   Run Tests
```

### Search `<leader>s`
```
sf →   Files               sg → 󰊄 Grep
sb → 󰓩 Buffers             sh → 󰋖 Help Pages
sk →   Keymaps             sd →   Diagnostics
sr → 󰋚 Resume Last         sw →   Word Under Cursor
s" →   Registers           sa →   Autocommands
sc →   Command History     sC →   Commands
sH →   Highlight Groups    sm → 󰃀 Marks
sM →   Man Pages           so →   Options
ss →   Document Symbols    sS →   Workspace Symbols
st →   TODOs               sn → 󰎞 Notifications
```

### Terminal `<leader>t`
```
tf →   Float Terminal      th →   Horizontal Terminal
tv →   Vertical Terminal   tT →   Tab Terminal
tp →   Python REPL        tn → 󰎙 Node.js REPL
tr → 󰟔 R Console           tR →   Ruby IRB
tl →   Lua REPL           tP →   Perl REPL
tg →   Go Playground      ts → 󰛥 Swift REPL
tS →   Send to Terminal
```

### UI/Toggle `<leader>u`
```
ul →   Line Numbers        uL →   Relative Numbers
uw → 󰖶 Word Wrap           us → 󰓆 Spelling
ud →   Diagnostics         uc →   Color Column
ui →   Indent Guides       uf → 󰉢 Format on Save
ut →   Treesitter HL      ub → 󰹏 Background
uh → 󰸱 Inlay Hints        un → 󰎞 Dismiss Notifications
```

### Window `<leader>w`
```
wd →   Delete Window       ws →   Split Below
wv →   Split Right        wm → 󰊓 Maximize Toggle
w= →   Balance Windows
```

### Diagnostics/Trouble `<leader>x`
```
xx →   Document Diag      xX →   Workspace Diag
xL →   Location List      xQ →   Quickfix List
xt →   TODOs (Trouble)
```

### Lazy `<leader>l`
```
ll → 󰒲 Lazy Home           lu →   Update Plugins
ls →   Sync Plugins        lc →   Check Plugins
lp →   Profile
```

### Mason `<leader>m`
```
mm →   Mason Home          mu →   Update All
```

### Go-to (g prefix, no leader)
```
gd →   Definition          gr →   References
gI →   Implementation      gy →   Type Definition
gD →   Declaration         gK → 󰋖 Signature Help
K  → 󰋖 Hover Docs
```

### Bracket Navigation (]/[ prefix)
```
]h/[h → 󰊢 Next/Prev Git Hunk     ]d/[d →   Next/Prev Diagnostic
]t/[t →   Next/Prev TODO         ]f/[f →   Next/Prev Function
]c/[c →   Next/Prev Class
```

### Direct Keymaps (no leader)
```
<C-/>      →  Toggle floating terminal
<C-h/j/k/l> → Window navigation
<C-Up/Down/Left/Right> → Window resize
<S-h>/<S-l> → Previous/Next buffer
<A-j>/<A-k> → Move line down/up
<Esc>       → Clear search highlight
s/S         → Flash jump / Treesitter select
gc/gb       → Comment line / Comment block
```

---

## Terminal Support (toggleterm.nvim)

### General Terminals
- Float (`<C-/>`), horizontal (30%), vertical (40%), tab
- Multiple terminals: `2<C-/>` opens terminal #2
- Terminal-mode: `<Esc><Esc>` exits to normal, `<C-h/j/k/l>` navigates windows

### Language-Specific REPLs
Each opens as a named toggleterm instance:
- Python (`python3` / `ipython`), Node.js (`node`), R (`R`), Ruby (`irb`), Lua (`lua`), Perl (`perl -de 0`), Go (`go run`), Swift (`swift`)

### Build/Run Commands (`<leader>r`)
Auto-detects language: C/C++ (gcc/g++), Go (go run), Python (python3), LaTeX (texlab build), Swift (swift), Rust (cargo run)

### Send to Terminal
`<leader>tS` sends current line or visual selection to running terminal/REPL.

---

## Eye Candy Features

- **Rainbow indent guides** (snacks.indent) — colored per nesting level, VS Code style
- **Rainbow parentheses** (rainbow-delimiters.nvim) — treesitter-based, theme-matched colors
- **Inline color preview** (nvim-colorizer.lua) — CSS hex/rgb/hsl rendered inline
- **LSP diagnostic gutter icons:** `` Error, `` Warn, `` Info, `󰌵` Hint
- **Smooth scrolling** (snacks.scroll) and **smooth animations** (snacks.animate)
- **Floating cmdline** (noice.nvim) — centered popup command input
- **Ghost text** completion preview (blink.cmp)
- **Lualine** with custom ocean theme, vibrant mode colors, no separators (color differentiation only)
- **Bufferline** with LSP diagnostics per tab and close buttons (planned)

---

## Autocommands

**Visual feedback:**
- Highlight on yank (200ms flash)
- Restore cursor position on file reopen

**Window management:**
- Auto-resize splits on terminal resize
- Close utility filetypes with `q` (help, man, qf, lspinfo, spectre, notify, checkhealth)

**File handling:**
- Auto-create parent directories on save
- Auto-reload on focus gain / buffer enter
- Remove trailing whitespace on save (except markdown)

**Filetype-specific:**
- Wrap + spellcheck in markdown, gitcommit, text, tex
- Set commentstring for systemverilog, vhdl
- 4-space indent for Go, Python, C, C++, Rust

**LSP-related:**
- Show diagnostics float on cursor hold

**Performance:**
- Disable syntax/treesitter/LSP semantic tokens for files >1.5MB

---

## Auto-Installation Flow (First Launch)

1. User runs `nvim`
2. `lazy.lua` bootstraps lazy.nvim (git clone from GitHub)
3. lazy.nvim downloads + installs all plugins
4. mason.nvim initializes → mason-lspconfig auto-installs all LSP servers
5. mason-tool-installer auto-installs all formatters/linters
6. nvim-treesitter auto-installs all parsers
7. sourcekit-lsp configured to use system binary (no install needed)
8. Everything ready — no manual `:Mason` or `:TSInstall` needed

---

## Verification Checklist

1. `./install.sh` — Neovim + deps + font installed (or detected)
2. `nvim` first launch — lazy.nvim bootstraps, all plugins install
3. `:Mason` — all LSP servers and formatters show installed
4. `:TSInstallInfo` — all parsers installed
5. Open files per language — LSP attaches (`:LspInfo`)
6. Edit + save — format-on-save works
7. `<leader>` — WhichKey shows all categories with Nerd Font icons
8. `<leader>ff` — fzf-lua file search works
9. `<leader>e` — neo-tree opens
10. `<leader>gg` — lazygit opens
11. `nvim` (no file) — dashboard renders
12. `<C-/>` — floating terminal toggles
13. `<leader>tp` — Python REPL opens
14. Visual select + `<leader>tS` — sent to terminal
15. Type in file — blink.cmp completion appears
16. Nested code — rainbow indent guides visible
17. Nested brackets — rainbow delimiters colored
18. `(` typed — `)` auto-inserted; `<div>` → `</div>` auto-closes
19. File with errors — ``, `` icons in gutter
20. Background is deep navy (#011628), not default tokyonight
21. Statusline matches ocean theme with rounded separators
22. CSS file — hex colors show inline preview
23. `<leader>t` — all REPL entries with language icons
24. `<leader>gh` — Git Hunks subcategory with icons
25. `:checkhealth` — no critical errors

---

## Implementation Order

1. ~~`.gitignore` + `init.lua` + `lua/config/options.lua` + `lua/config/lazy.lua` + `lua/config/icons.lua`~~ (done)
2. ~~`lua/plugins/colorscheme.lua`~~ (done)
3. ~~`lua/plugins/ui.lua` (snacks dashboard + indent, noice, rainbow-delimiters, colorizer)~~ (done)
4. ~~`lua/plugins/editor.lua` (fzf-lua) + `lua/plugins/lualine.lua`~~ (done)
5. `lua/plugins/lsp.lua`
6. `lua/plugins/treesitter.lua`
7. `lua/plugins/coding.lua`
8. `lua/plugins/formatting.lua`
9. `lua/plugins/linting.lua`
10. `lua/plugins/terminal.lua`
11. `lua/plugins/util.lua`
12. `lua/config/keymaps.lua`
13. `lua/config/autocmds.lua`
14. ~~`install.sh`~~ (done) + ~~`uninstall.sh`~~ (done)
15. ~~`README.md`~~ (done)
