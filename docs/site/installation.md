Installing takes one Homebrew session, one clone and one first start. Every command below is typed in a terminal, in the order given.

**Install Homebrew.** Homebrew is the Mac's package manager, and everything else comes from it. If `brew --version` prints nothing, follow the one command on [brew.sh](https://brew.sh).

**Install the programs.** Neovim itself, git, ripgrep and fd for searching, lazygit for git, the tree-sitter command-line program, ImageMagick for pictures, Ghostty, and the font:

```bash
brew install neovim git ripgrep fd lazygit tree-sitter-cli imagemagick
brew install --cask ghostty font-meslo-lg-nerd-font
xcode-select --install
```

ACH-NEOVIM needs Neovim 0.12.4 or later, and `nvim --version` prints the version on its first line. The tree-sitter program builds each language's parser, the part that reads its syntax, with the compiler from Apple's Command Line Tools, which is what the last line installs.

<Callout type="tip">

Install Ghostty and the Meslo Nerd Font before anything else. Every icon in the editor comes from that font, and without it each one shows as an empty box.

</Callout>

**Back up what you have.** The clone goes exactly where a Neovim configuration lives, so move yours aside first, with the folders Neovim keeps its data, its state and its cache in:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

A line whose folder does not exist only prints an error, so run all four.

<Callout type="warning">

Do not skip the backup. ACH-NEOVIM keeps its plugins, its language tools, its history and its sessions in those same folders, so starting it on top of another setup's folders leaves the two mixed together.

</Callout>

**Clone the configuration.**

```bash
git clone https://github.com/anirbanchakraborty-dev/ACH-NEOVIM ~/.config/nvim
```

**Link Ghostty's settings.** The repository carries Ghostty's settings in `ghostty/config.ghostty`: the font at 16 points, the navy background, the left Option key working as Alt, and the sixteen colours Neovim's own terminal uses. Link the file to where Ghostty reads it:

```bash
mkdir -p ~/.config/ghostty
ln -s ~/.config/nvim/ghostty/config.ghostty ~/.config/ghostty/config.ghostty
```

<Callout type="warning">

Do not keep an old `~/.config/ghostty/config` beside the link. Ghostty reads both files and warns about it. Move any setting you want to keep out of `~/Library/Application Support/com.mitchellh.ghostty/config` too, because Ghostty reads that file last and a setting there wins.

</Callout>

**Start Neovim.**

```bash
nvim
```

The first start installs every plugin at the commit pinned in `lazy-lock.json`, so you get the versions I test. Let it finish before you open anything.

**Check what is missing.** Inside Neovim, type this and press Enter:

```text
:checkhealth ach
```

Read what it says. It lists each program the configuration uses, installed or not, and gives each missing one the single command that installs it.

**Open a file.** The first time you open a file in a language, its parser, its language server, its formatter and its linter install by themselves in the background, without asking, and switch on when they are ready. A language that needs a compiler or runtime only Homebrew provides, such as Haskell's GHC or Julia, asks first, once, in one line that names it and its rough size. Say yes, and Homebrew installs it in the background while you keep editing. Say no, and it does not ask again until you next start Neovim.

<Callout type="warning">

Do not say yes to a compiler on a slow or metered connection. Haskell's runs to about 3 GB and Julia's to about 1.5 GB.

</Callout>

**Add the programs some keys use.** A key whose program is missing prints the line that installs it instead of running, and `:checkhealth ach` lists the same programs:

| Program | What it is for | Install |
| --- | --- | --- |
| `lazygit` | Lazygit on `Space g g` and `Space g G` | `brew install lazygit` |
| `gh` | GitHub issues and pull requests on `Space g i` and `Space g p` | `brew install gh`, then `gh auth login` |
| `claude` | the Claude Code panel on `Space a` | `brew install --cask claude-code` |
| `latexmk` | building LaTeX documents on `Space c b` | `brew install --cask mactex` |
| `displayline` | showing LaTeX PDFs in Skim and jumping between them and the source | `brew install --cask skim` |
| `magick` | turning pictures and formulas into images the terminal can show | `brew install imagemagick` |
| `pdflatex` | typesetting the formulas in Markdown files | `brew install --cask mactex` |
| `gs` | letting ImageMagick read the PDF a formula is typeset into | `brew install ghostscript` |
| `pdftotext` | reading Intel's manual to find each instruction's page | `brew install poppler` |
| `newsboat` | the feed reader on `Space N` | `brew install newsboat` |

<Callout type="warning">

Do not `brew install` language servers, formatters or linters yourself. Mason, the package manager inside Neovim, installs each one into Neovim's own folder at the version pinned in `mason-lock.json`, and puts that folder on the path Neovim searches. A second copy from Homebrew is one more version that can differ from the pinned one, and you are left guessing which one runs.

</Callout>
