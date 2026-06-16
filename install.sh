#!/usr/bin/env bash
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
LOCAL_BIN="$HOME/.local/bin"
ZSH_PLUGINS_DIR="$XDG_DATA_HOME/zsh/plugins"

OS="$(uname -s)"
ARCH="$(uname -m)"

MODE=""
for arg in "$@"; do
  case "$arg" in
  --full) MODE="full" ;;
  --install-only) MODE="install" ;;
  --config-only) MODE="config" ;;
  --help | -h) MODE="help" ;;
  esac
done

if [[ -z "$MODE" ]]; then
  MODE="help"
fi

# --- Helpers ---

info() { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
ok() { printf '\033[1;32m[ok]\033[0m    %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
fail() {
  printf '\033[1;31m[fail]\033[0m  %s\n' "$*"
  exit 1
}

command_exists() { command -v "$1" &>/dev/null; }

github_latest_version() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/'
}

ensure_dir() { mkdir -p "$@"; }

fetch_plugin() {
  local repo="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    ok "plugin $repo already present"
    return
  fi
  info "fetching $repo"
  ensure_dir "$dest"
  curl -fsSL "https://github.com/$repo/archive/refs/heads/master.tar.gz" |
    tar -xz -C "$dest" --strip-components=1 2>/dev/null ||
    curl -fsSL "https://github.com/$repo/archive/refs/heads/main.tar.gz" |
    tar -xz -C "$dest" --strip-components=1
}

# --- Install: system packages ---

install_apt_packages() {
  info "installing apt packages"
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends \
    zsh tmux ripgrep fd-find bat jq unzip
  if command_exists batcat && ! command_exists bat; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
  fi
  if command_exists fdfind && ! command_exists fd; then
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
  fi
}

install_brew_packages() {
  if ! command_exists brew; then
    fail "homebrew required — install from https://brew.sh"
  fi
  brew install zsh tmux ripgrep fd bat eza zoxide git-delta \
    starship neovim fzf lazygit jq
}

# --- Install: individual tools (Linux only, macOS uses brew) ---

install_deb() {
  local name="$1" url="$2"
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "$url" -o "$tmp/$name.deb"
  sudo dpkg -i "$tmp/$name.deb" || sudo apt-get install -f -y
  rm -rf "$tmp"
}

install_eza() {
  if command_exists eza; then
    ok "eza already installed"
    return
  fi
  info "installing eza"
  local eza_arch
  case "$ARCH" in
  x86_64) eza_arch="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
  esac
  local version
  version=$(github_latest_version "eza-community/eza")
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/eza-community/eza/releases/download/v${version}/eza_${eza_arch}.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  ensure_dir "$LOCAL_BIN"
  mv "$tmp/eza" "$LOCAL_BIN/"
  chmod +x "$LOCAL_BIN/eza"
  rm -rf "$tmp"
}

install_zoxide() {
  if command_exists zoxide; then
    ok "zoxide already installed"
    return
  fi
  info "installing zoxide"
  local zox_arch
  case "$ARCH" in
  x86_64) zox_arch="x86_64" ;;
  aarch64|arm64) zox_arch="aarch64" ;;
  esac
  local version
  version=$(github_latest_version "ajeetdsouza/zoxide")
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v${version}/zoxide-${version}-${zox_arch}-unknown-linux-musl.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  ensure_dir "$LOCAL_BIN"
  mv "$tmp/zoxide" "$LOCAL_BIN/"
  chmod +x "$LOCAL_BIN/zoxide"
  rm -rf "$tmp"
}

install_delta() {
  if command_exists delta; then
    ok "delta already installed"
    return
  fi
  info "installing delta"
  local deb_arch
  case "$ARCH" in
  x86_64) deb_arch="amd64" ;;
  aarch64|arm64) deb_arch="arm64" ;;
  esac
  local version
  version=$(github_latest_version "dandavison/delta")
  install_deb delta "https://github.com/dandavison/delta/releases/download/${version}/git-delta_${version}_${deb_arch}.deb"
}

install_starship() {
  if command_exists starship; then
    ok "starship already installed"
    return
  fi
  info "installing starship"
  local star_arch
  case "$ARCH" in
  x86_64) star_arch="x86_64" ;;
  aarch64|arm64) star_arch="aarch64" ;;
  esac
  local version
  version=$(github_latest_version "starship/starship")
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/starship/starship/releases/download/v${version}/starship-${star_arch}-unknown-linux-musl.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  ensure_dir "$LOCAL_BIN"
  mv "$tmp/starship" "$LOCAL_BIN/"
  chmod +x "$LOCAL_BIN/starship"
  rm -rf "$tmp"
}

install_neovim() {
  if command_exists nvim; then
    ok "neovim already installed"
    return
  fi
  info "installing neovim"
  local nvim_arch
  case "$ARCH" in
  x86_64) nvim_arch="x86_64" ;;
  aarch64|arm64) nvim_arch="arm64" ;;
  esac
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  sudo cp -r "$tmp"/nvim-linux-*/. /usr/local/
  rm -rf "$tmp"
}

install_fzf() {
  if command_exists fzf; then
    ok "fzf already installed"
    return
  fi
  info "installing fzf"
  local fzf_arch
  case "$ARCH" in
  x86_64) fzf_arch="linux_amd64" ;;
  aarch64|arm64) fzf_arch="linux_arm64" ;;
  esac
  local version
  version=$(github_latest_version "junegunn/fzf")
  ensure_dir "$LOCAL_BIN"
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-${fzf_arch}.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  mv "$tmp/fzf" "$LOCAL_BIN/"
  chmod +x "$LOCAL_BIN/fzf"
  rm -rf "$tmp"
}

install_lazygit() {
  if command_exists lazygit; then
    ok "lazygit already installed"
    return
  fi
  info "installing lazygit"
  local lg_arch
  case "$ARCH" in
  x86_64) lg_arch="x86_64" ;;
  aarch64|arm64) lg_arch="arm64" ;;
  esac
  local version
  version=$(github_latest_version "jesseduffield/lazygit")
  local tmp
  tmp=$(mktemp -d)
  chmod 700 "$tmp"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${lg_arch}.tar.gz" |
    tar --no-same-owner -xz -C "$tmp"
  ensure_dir "$LOCAL_BIN"
  mv "$tmp/lazygit" "$LOCAL_BIN/"
  chmod +x "$LOCAL_BIN/lazygit"
  rm -rf "$tmp"
}

# --- Install: all tools ---

install_tools() {
  info "installing tools — OS=$OS ARCH=$ARCH"
  ensure_dir "$LOCAL_BIN"

  case "$OS" in
  Linux)
    install_apt_packages
    install_eza
    install_zoxide
    install_delta
    install_starship
    install_neovim
    install_fzf
    install_lazygit
    ;;
  Darwin)
    install_brew_packages
    ;;
  *)
    fail "unsupported OS: $OS"
    ;;
  esac

  ok "tools installed"
}

# --- Configure ---

configure_tools() {
  info "configuring tools"

  ensure_dir "$XDG_DATA_HOME/zsh"
  ensure_dir "$XDG_DATA_HOME/tmux/plugins"
  ensure_dir "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

  # .zshenv in $HOME sets ZDOTDIR
  if [[ ! -f "$HOME/.zshenv" ]] || ! grep -q ZDOTDIR "$HOME/.zshenv" 2>/dev/null; then
    cp "$XDG_CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv"
    ok ".zshenv copied to $HOME"
  fi

  # TPM
  local tpm_dir="$XDG_DATA_HOME/tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    info "installing tpm"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  # Zsh plugins (~330KB total, no .git)
  fetch_plugin "zsh-users/zsh-autosuggestions" "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
  fetch_plugin "zdharma-continuum/fast-syntax-highlighting" "$ZSH_PLUGINS_DIR/fast-syntax-highlighting"
  fetch_plugin "zsh-users/zsh-completions" "$ZSH_PLUGINS_DIR/zsh-completions"

  ok "configured — restart shell or: exec zsh"
  info "run prefix+I inside tmux to install tmux plugins"
}

set_default_shell() {
  if [[ "$SHELL" == *zsh ]]; then
    ok "zsh already default shell"
    return
  fi
  local zsh_path
  zsh_path=$(which zsh)
  if ! grep -qF "$zsh_path" /etc/shells 2>/dev/null; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  sudo chsh -s "$zsh_path" "$(whoami)" 2>/dev/null || warn "chsh failed — run: chsh -s $zsh_path"
}

# --- Help ---

show_help() {
  cat <<'EOF'
Usage: install.sh <mode>

Modes:
  --full           Install tools + configure + set default shell (sudo)
  --install-only   Install CLI tools only (apt/brew + GitHub releases)
  --config-only    Configure only (data dirs, plugins, TPM — no sudo)
  --help, -h       Show this help

Tools installed:
  zsh, tmux, ripgrep, fd, bat, fzf, eza, zoxide, delta,
  starship, neovim, lazygit

Configs managed (~/.config/):
  zsh, starship, tmux, nvim (LazyVim), bat, git (delta)

Setup:
  git clone git@github.com:eveny/dotfiles.git ~/.config    # fresh
  ./install.sh --full
EOF
}

# --- Main ---

main() {
  case "$MODE" in
  full)
    install_tools
    configure_tools
    set_default_shell
    ;;
  install) install_tools ;;
  config) configure_tools ;;
  help) show_help ;;
  esac
}

main
