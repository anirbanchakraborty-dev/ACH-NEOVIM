#!/usr/bin/env bash
#
# ACH-NEOVIM Installer
# Installs Homebrew (if needed) and Neovim on macOS
#

clear
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ── macOS Gate ──────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "ACH-NEOVIM currently supports macOS only."
  exit 1
fi

echo -e "\n${BOLD}${CYAN}ACH-NEOVIM Installer${NC}\n"

# ── Homebrew ────────────────────────────────────────────────────────────────
if command -v brew &>/dev/null; then
  success "Homebrew already installed ($(brew --version | head -1))"
else
  info "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Homebrew may need to be added to PATH on Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if command -v brew &>/dev/null; then
    success "Homebrew installed successfully"
  else
    error "Homebrew installation failed. Please install manually:"
    error "  https://brew.sh"
    exit 1
  fi
fi

# ── Neovim ──────────────────────────────────────────────────────────────────
# Fetch latest stable version from GitHub API
info "Checking latest Neovim stable release..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
  | grep '"tag_name"' \
  | sed -E 's/.*"v([^"]+)".*/\1/')

if [[ -z "$LATEST_VERSION" ]]; then
  warn "Could not fetch latest version from GitHub. Will install whatever Homebrew provides."
  LATEST_VERSION="unknown"
else
  info "Latest stable Neovim: v${LATEST_VERSION}"
fi

if command -v nvim &>/dev/null; then
  INSTALLED_VERSION=$(nvim --version | head -1 | sed -E 's/NVIM v//')
  info "Installed Neovim: v${INSTALLED_VERSION}"

  if [[ "$LATEST_VERSION" != "unknown" ]]; then
    # Compare versions — if installed >= latest, we're good
    NEWER=$(printf '%s\n%s\n' "$LATEST_VERSION" "$INSTALLED_VERSION" | sort -V | tail -1)
    if [[ "$NEWER" == "$INSTALLED_VERSION" ]]; then
      success "Neovim is up to date (v${INSTALLED_VERSION})"
    else
      info "Upgrading Neovim from v${INSTALLED_VERSION} to v${LATEST_VERSION}..."
      brew upgrade neovim
      success "Neovim upgraded to v$(nvim --version | head -1 | sed -E 's/NVIM v//')"
    fi
  else
    success "Neovim already installed (v${INSTALLED_VERSION})"
  fi
else
  info "Installing Neovim..."
  brew install neovim

  if command -v nvim &>/dev/null; then
    success "Neovim installed (v$(nvim --version | head -1 | sed -E 's/NVIM v//'))"
  else
    error "Neovim installation failed."
    exit 1
  fi
fi

# ── Config Symlink ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG="$HOME/.config/nvim"

if [[ -L "$NVIM_CONFIG" ]]; then
  CURRENT_TARGET="$(readlink "$NVIM_CONFIG")"
  if [[ "$CURRENT_TARGET" == "$SCRIPT_DIR/nvim" ]]; then
    success "Config symlink already points to ACH-NEOVIM"
  else
    warn "~/.config/nvim is a symlink to: $CURRENT_TARGET"
    warn "Skipping — remove it manually if you want ACH-NEOVIM to take over."
  fi
elif [[ -d "$NVIM_CONFIG" ]]; then
  BACKUP="$NVIM_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
  warn "Existing Neovim config found. Backing up to: $BACKUP"
  mv "$NVIM_CONFIG" "$BACKUP"
  ln -s "$SCRIPT_DIR/nvim" "$NVIM_CONFIG"
  success "Config symlinked: ~/.config/nvim -> $SCRIPT_DIR/nvim"
else
  mkdir -p "$HOME/.config"
  ln -s "$SCRIPT_DIR/nvim" "$NVIM_CONFIG"
  success "Config symlinked: ~/.config/nvim -> $SCRIPT_DIR/nvim"
fi

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
success "ACH-NEOVIM setup complete!"
echo -e "  Neovim: ${BOLD}$(nvim --version | head -1)${NC}"
echo -e "  Config: ${BOLD}$NVIM_CONFIG -> $SCRIPT_DIR/nvim${NC}"
echo ""
info "Launch Neovim with: ${BOLD}nvim${NC}"
info "First launch will auto-install plugins via lazy.nvim."
echo ""
