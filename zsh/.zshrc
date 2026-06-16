# PATH
export PATH="$HOME/.local/bin:$PATH"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

ZSH_PLUGINS="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# History
HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Plugins
[[ -d "$ZSH_PLUGINS/zsh-completions/src" ]] && fpath+=("$ZSH_PLUGINS/zsh-completions/src")
[[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && source "$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# Tool integrations
eval "$(zoxide init zsh)"
eval "$(fzf --zsh 2>/dev/null || true)"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'

# Aliases
alias ls="eza"
alias ll="eza -la --git"
alias lt="eza -T"
alias cat="bat --paging=never"
alias lg="lazygit"
alias fd="fdfind 2>/dev/null || fd"
alias vi="nvim"

# Functions
source "$ZDOTDIR/tmux-sessionizer.zsh"

# Prompt
eval "$(starship init zsh)"

# Machine-specific overrides
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
