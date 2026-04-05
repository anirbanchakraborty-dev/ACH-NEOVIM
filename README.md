# ACH-Vim

A supercharged Neovim configuration for macOS.

One-command install. Auto-bootstraps lazy.nvim, plugins, and sensible defaults on first launch.

## Installation

```bash
git clone https://github.com/anirbanchakraborty-dev/ACH-NEOVIM.git
cd ACH-NEOVIM
./install.sh
```

The install script will:

- Install Homebrew if not present
- Install or upgrade Neovim to the latest stable release
- Symlink the config to `~/.config/nvim` (backs up any existing config)

After running the script, launch `nvim`. Lazy.nvim will auto-install all plugins on first start.

## Structure

```
nvim/
  init.lua                 -- Entry point
  lua/
    config/
      options.lua          -- Sensible defaults
      lazy.lua             -- Lazy.nvim bootstrap
    plugins/
      ui.lua               -- Dashboard
```

## Requirements

- macOS
- Git
- Internet connection (for Homebrew, Neovim, and plugin installation)

## License

MIT
