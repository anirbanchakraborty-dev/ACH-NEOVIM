# ACH-NEOVIM

A Neovim distribution for one person's Mac, written from scratch on lazy.nvim. It carries a deep-navy tokyonight theme, a tiled status bar, the ACH NEOVIM start screen, every language the owner might open with highlighting, intellisense, completion, formatting, linting and grammar checking, and Claude Code inside the editor.

It needs Neovim 0.12 or later. To try it, clone it into `~/.config/nvim` and start `nvim`. The first start installs the plugins.

The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite.

LazyVim, by Folke Lemaitre, is the reference this configuration learned from. Nothing here imports it, and files that adapt one of its functions say so. LazyVim is Apache-2.0 licensed.

ACH-NEOVIM is MIT licensed.
