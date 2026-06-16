# =========================================================
# Zsh Configuration (v5.0+)
# =========================================================

# Environment variables
export EDITOR="nvim"
export TERMINAL="kitty"
export QT_QPA_PLATFORMTHEME="qt6ct"
export PATH="$HOME/.local/bin:$PATH"

# Nix Integration
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# History configuration
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# Shell behavior options
setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT
setopt MULTIOS
setopt PROMPT_SUBST

# Completion system setup
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$XDG_CACHE_HOME/zsh"

autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Load system FZF utilities (Arch Linux paths)
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Load modular configurations
ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
source "$ZDOTDIR/prompt.zsh"
source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/plugins.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/aliases.zsh"

# Initialize zoxide
eval "$(zoxide init zsh)"
