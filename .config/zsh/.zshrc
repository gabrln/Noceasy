export EDITOR="nvim"
export TERMINAL="kitty"
export QT_QPA_PLATFORMTHEME="qt6ct"

eval "$(atuin init zsh)"

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT
setopt MULTIOS
setopt PROMPT_SUBST

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$XDG_CACHE_HOME/zsh"

autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
source "$ZDOTDIR/prompt.zsh"
source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/plugins.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/aliases.zsh"

eval "$(zoxide init zsh)"
