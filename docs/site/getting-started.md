ACH-NEOVIM is my Neovim configuration for macOS. Neovim is a text editor that runs inside a terminal and is driven from the keyboard, and a configuration is the set of files that tells it which plugins to load, what each key does and how each language is handled. I wrote this one from scratch on lazy.nvim, the plugin manager, and it lives at [github.com/anirbanchakraborty-dev/ACH-NEOVIM](https://github.com/anirbanchakraborty-dev/ACH-NEOVIM) under the MIT licence.

**Why I built it.** I wanted one editor that already knows every language I work in: C and C++, Python, Rust, SystemVerilog and Verilog, VHDL, LaTeX and Markdown, with the rest of about ninety languages there when I need them. I did not want it to fill my disk with tools for languages I never open, so nothing for a language installs until I open a file in it. I wanted it to start fast, too. It starts no slower than stock LazyVim, and its own test suite fails any change that makes it take more than one and a half times as long to start as it did when I first timed it. LazyVim showed me what a well-made Neovim setup looks like. I took its ideas and built my own, small enough that I can read every line of it and keep it working, and the few files that adapt a LazyVim function say so in their first lines and name LazyVim's Apache-2.0 licence.

**Who it is for.** It is for someone on a Mac who writes code and technical documents in many languages, works from the keyboard, and would rather set things up properly once than tinker forever.

<Callout type="warning">

It is not for someone learning Vim for the first time. Run `nvim --clean +Tutor` first, which opens Neovim's own lessons without this configuration, and come back when the motions feel natural. ACH-NEOVIM switches the tutor off, with a few other built-in plugins, so it starts faster.

</Callout>

<Callout type="warning">

It is not for Linux or Windows. I run it on macOS in Ghostty, and that is the only place I test it.

</Callout>

**My favourite part.** I never install a language's tools by hand. I open a file in a language I have not touched in months, and while I read the first screen, its highlighting, completion and formatter install in the background and switch on. A close second is having Claude Code right inside the editor, on `Space a c`, looking at the same file I am.

<Callout type="tip">

Keep the key card beside you while the keys are new. It is `docs/key-card.md` in the repository, the dashboard points to it, and every key on it has a one-line description and a sentence saying what it does. The Keymaps section below lists every key the configuration sets.

</Callout>
