# dotfiles

CLI toolchain configs. Repo clones directly into `~/.config`.

## Setup

### Fresh machine (no `~/.config`)

```bash
git clone git@github.com:eveny/dotfiles.git ~/.config
~/.config/install.sh --full
```

### Existing `~/.config`

```bash
cd ~/.config
git init
git remote add origin git@github.com:eveny/dotfiles.git
git fetch origin main
git checkout main
./install.sh --full
```

### Devcontainer

Handled by Dockerfile — clones repo and runs `--install-only` then `--config-only`.

## Modes

```
./install.sh --full           # install + configure + chsh (sudo)
./install.sh --install-only   # tools only
./install.sh --config-only    # data dirs, plugins, TPM (no sudo)
./install.sh --help
```

## What's included

**Tools**: zsh, tmux, ripgrep, fd, bat, fzf, eza, zoxide, delta, starship, neovim, lazygit

**Configs**: `zsh/`, `tmux/`, `nvim/`, `bat/`, `git/`, `starship/`

**Zsh plugins** (tarballs, no git): zsh-autosuggestions, fast-syntax-highlighting, zsh-completions

## Layout

Repo root = `~/.config`. `.gitignore` ignores everything except tracked dirs.

```
~/.config/
├── zsh/            ← ZDOTDIR
├── tmux/
├── nvim/           ← LazyVim
├── bat/
├── git/            ← delta pager
├── starship/
├── install.sh
└── .gitignore      ← ignores non-dotfiles content
```

Runtime data (plugins, TPM, history) stored in `~/.local/share/`, not here.
