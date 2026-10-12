Here is what ACH-NEOVIM does beyond editing text, area by area. Each area's keys are in the Keymaps section below.

**Git.** Change bars in the margin show what changed since the last commit, and `] h` and `[ h` move between the changes. Lazygit opens on `Space g g`. Neogit, git's status page inside Neovim, opens on `Space g n`, and diffview shows every uncommitted change side by side on `Space g D`. GitHub's issues and pull requests are on `Space g i` and `Space g p`, through `gh`. A git key pressed on a file outside every repository says so and opens nothing, and a link copied to the current line never carries a user name or a token from the remote's address.

**Claude Code.** `Space a c` opens Claude Code in a panel on the right, 40 percent of the screen wide. It sees the file and the selection I am on, and a change it proposes opens side by side, to accept with `Space a a` or reject with `Space a d`. Its server listens only on this Mac, refuses a connection without the token in its lock file, and never starts when Neovim has no window.

**LaTeX.** VimTeX builds the document on `Space c b`, with latexmk or with a command the project sets, and shows the PDF in Skim, and I can jump from a line of the source to its place in the PDF and back. The build's own files are kept outside the repository.

**Markdown.** Headings, lists and tables are drawn in place while I write, formulas and pictures are drawn as images inside the editor, and `Space c p` opens a preview in the browser that keeps up with the file as it changes. The preview's server listens only on this Mac and serves nothing outside the folder it was started for.

**Intel's manual.** `Space c x` opens Intel's x86 manual in Skim at the page for the instruction under the cursor, and on any other word lists every instruction to pick one. The manual is Intel's to publish, so it is not in the repository.

**News.** `Space N` opens newsboat, a feed reader, in a window floating over the editor.

**Ghostty.** The repository carries Ghostty's settings: JetBrains Mono at 15 points, the same navy background as the editor, the left Option key working as Alt, and the sixteen colours Neovim's own terminal uses.

**Startup.** It starts no slower than stock LazyVim, and the test suite fails any change that makes it take more than one and a half times as long to start as it did when first timed.

**Updates.** `scripts/update` updates every plugin and Mason package, runs the full test suite, and commits both lock files when it passes, or puts everything back when it does not.

**Upgrade check.** The first time a new Neovim release starts on a screen, the fast test suite runs in the background, and the release is recorded once it passes.

**Key card.** `docs/key-card.md` is one page of keys to keep beside the keyboard, and a test fails whenever it disagrees with the keys the configuration sets.

**This page.** `scripts/docs` writes this page from the configuration's own source, so a plugin, a key or a language added to the configuration shows here the next time it runs.
