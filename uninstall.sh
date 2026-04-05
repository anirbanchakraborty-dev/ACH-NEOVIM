#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  Neovim Config Uninstaller${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This will remove:"
echo "  - ~/.config/nvim (symlink)"
echo "  - ~/.local/share/nvim (plugins, mason packages)"
echo "  - ~/.local/state/nvim (session data)"
echo "  - ~/.cache/nvim (cache)"
echo ""
echo -ne "${YELLOW}Are you sure? [y/N]:${NC} "
read -r reply

if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  info "Aborted."
  exit 0
fi

remove_dir() {
  local dir="$1"
  if [ -L "$dir" ]; then
    rm "$dir"
    success "Removed symlink: $dir"
  elif [ -d "$dir" ]; then
    rm -rf "$dir"
    success "Removed directory: $dir"
  else
    info "Not found: $dir (skipping)"
  fi
}

remove_dir "$HOME/.config/nvim"
remove_dir "$HOME/.local/share/nvim"
remove_dir "$HOME/.local/state/nvim"
remove_dir "$HOME/.cache/nvim"

echo ""
success "Neovim config fully removed."
info "Your Neovim-Config repo is still intact — re-run install.sh to set up again."
echo ""
