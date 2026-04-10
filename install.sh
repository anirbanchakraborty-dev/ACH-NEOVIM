#!/usr/bin/env bash
#
# ACH-NEOVIM Installer
# Installs Homebrew (if needed), Neovim, and Claude Code CLI on macOS
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

# ── Argument parsing ────────────────────────────────────────────────────────
# --with-hdl is opt-in because the SystemVerilog/Verilog toolchain
# (verible + verilator + icarus-verilog + yosys + surfer + netlistsvg)
# pulls ~500 MB of binaries that only hardware-design users need. The
# default install stays lean for everyone else.
INSTALL_HDL=false
for arg in "$@"; do
  case "$arg" in
    --with-hdl)
      INSTALL_HDL=true
      ;;
    --help|-h)
      cat <<EOF
ACH-NEOVIM Installer

Usage: $0 [--with-hdl]

Options:
  --with-hdl   Also install the SystemVerilog/Verilog toolchain via brew:
               verible, verilator, icarus-verilog, yosys, surfer, netlistsvg.
               Adds the system binaries that the SV LSP, formatter, linter,
               and HDL workflow need. Skip this flag on machines
               that aren't doing hardware design.
  -h, --help   Show this help.
EOF
      exit 0
      ;;
    *)
      error "Unknown argument: $arg"
      error "Run '$0 --help' for usage."
      exit 1
      ;;
  esac
done

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

# ── Claude Code CLI ─────────────────────────────────────────────────────────
# Powers nvim/lua/plugins/ai.lua (coder/claudecode.nvim). Uses the official
# native installer per https://code.claude.com/docs/en/overview — auto-updates
# in the background, unlike `brew install --cask claude-code`.
ensure_local_bin_on_path() {
  # Make ~/.local/bin reachable from this script session AND from every future
  # shell. The native installer does NOT touch shell rc files itself — it just
  # prints a "Setup notes" warning telling the user to do it. This function
  # automates that step so the install is truly hands-off.
  local local_bin="$HOME/.local/bin"

  # 1. Current script session: prepend if missing so the success line below
  #    can call `claude --version` directly.
  if [[ ":$PATH:" != *":$local_bin:"* ]]; then
    export PATH="$local_bin:$PATH"
  fi

  # 2. Future shells: append the export to ~/.zshrc (the macOS default since
  #    Catalina, and what CLAUDE.md documents as the shell). `>>` creates the
  #    file if it doesn't exist. The grep guard makes the append idempotent
  #    so re-running the installer doesn't pile up duplicate lines, and it
  #    also no-ops cleanly if the user has already added ~/.local/bin to PATH
  #    via some other entry (e.g. `path+=(~/.local/bin)`).
  local zshrc="$HOME/.zshrc"
  if [[ -f "$zshrc" ]] && grep -qE '\.local/bin' "$zshrc"; then
    return 0
  fi
  {
    echo ""
    echo "# Added by ACH-NEOVIM installer (Claude Code CLI lives in ~/.local/bin)"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$zshrc"
  info "Added ~/.local/bin to PATH in ~/.zshrc"
}

if command -v claude &>/dev/null; then
  # Installed and reachable — nothing to do.
  success "Claude Code already installed ($(claude --version 2>/dev/null | head -1 || echo 'version unknown'))"
elif [[ -x "$HOME/.local/bin/claude" ]]; then
  # Binary exists from a previous run but the user's PATH still doesn't
  # reach it. Skip the network round-trip and just wire up PATH.
  info "Claude Code present at ~/.local/bin/claude — wiring up PATH..."
  ensure_local_bin_on_path
  success "Claude Code ready ($(claude --version 2>/dev/null | head -1 || echo 'on PATH'))"
else
  info "Installing Claude Code CLI (native installer, auto-updates)..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    # The native installer drops the binary in ~/.local/bin but does NOT add
    # that directory to PATH on its own — it only prints a warning telling
    # the user to do it. ensure_local_bin_on_path() automates that step for
    # both the current script session and future shells via ~/.zshrc.
    if [[ -x "$HOME/.local/bin/claude" ]]; then
      ensure_local_bin_on_path
    fi

    if command -v claude &>/dev/null; then
      success "Claude Code installed ($(claude --version 2>/dev/null | head -1 || echo 'on PATH'))"
    else
      warn "Claude Code installer ran but 'claude' was not detected on PATH."
      warn "Open a new shell and run 'claude --version' to verify."
    fi
  else
    warn "Claude Code installer failed. Install manually with one of:"
    warn "  curl -fsSL https://claude.ai/install.sh | bash   (recommended, auto-updates)"
    warn "  brew install --cask claude-code                  (no auto-update)"
    warn "Continuing — the AI plugin will be inert until 'claude' is on PATH."
  fi
fi

# ── Optional: SystemVerilog / Verilog toolchain ─────────────────────────────
# Gated behind --with-hdl. Pulls in:
#   verible           -- LSP (verible-verilog-ls), formatter, lint engine
#   verilator         -- linter + simulator
#   icarus-verilog    -- iverilog + vvp simulator pair
#   yosys             -- synthesis
#   surfer            -- waveform viewer
#   netlistsvg        -- yosys-JSON -> SVG schematic renderer (also pulls
#                        node + npm transitively, which mason needs to
#                        install svlangserver on first .sv file open)
#
# `brew install` is idempotent: every package already on the system is
# silently skipped, so re-running this with --with-hdl on a partially
# provisioned machine just installs whatever's missing.
#
# All six tools are wired into the Neovim config at:
#   nvim/lua/plugins/lsp.lua          (verible LSP + svlangserver)
#   nvim/lua/plugins/formatting.lua   (verible-verilog-format via conform)
#   nvim/lua/plugins/linting.lua      (verilator via nvim-lint, with
#                                      project-aware -f filelist resolver)
if $INSTALL_HDL; then
  info "Installing SystemVerilog/Verilog toolchain via Homebrew..."
  brew install verible verilator icarus-verilog yosys surfer netlistsvg
  success "HDL toolchain installed (verible, verilator, icarus-verilog, yosys, surfer, netlistsvg)"
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
if command -v claude &>/dev/null; then
  echo -e "  Claude: ${BOLD}$(claude --version 2>/dev/null | head -1 || echo 'installed')${NC}"
fi
if $INSTALL_HDL && command -v verible-verilog-ls &>/dev/null; then
  echo -e "  HDL:    ${BOLD}verible + verilator + icarus-verilog + yosys + surfer + netlistsvg${NC}"
fi
echo -e "  Config: ${BOLD}$NVIM_CONFIG -> $SCRIPT_DIR/nvim${NC}"
echo ""
info "Launch Neovim with: ${BOLD}nvim${NC}"
info "First launch will auto-install plugins via lazy.nvim."
if ! $INSTALL_HDL; then
  echo ""
  info "Doing SystemVerilog work? Re-run with ${BOLD}./install.sh --with-hdl${NC} to add the HDL toolchain."
fi
echo ""
