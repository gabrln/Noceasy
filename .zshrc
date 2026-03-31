if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### ENV
export EDITOR="nvim"
export TERMINAL="kitty"
export QT_QPA_PLATFORMTHEME=qt6ct
export PATH="$HOME/.local/bin:$PATH"

### HISTORY
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY INC_APPEND_HISTORY
HISTFILE=~/.zsh_history

### OPTIONS
setopt AUTO_CD MULTIOS PROMPT_SUBST
unsetopt CORRECT CORRECT_ALL

### COMPLETION
autoload -Uz compinit && compinit

### ALIASES
alias c="clear"
alias q="exit"
alias please="sudo"
alias update="sudo pacman -Syu"
alias install="sudo pacman -S"
alias remove="sudo pacman -Rsn"
alias cleanup="sudo pacman -Rsn \$(pacman -Qtdq 2>/dev/null)"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias make="make -j\$(nproc)"
alias ninja="ninja -j\$(nproc)"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ls="ls --color=auto"
alias ll="ls -lah"
alias la="ls -A"

### PLUGINS
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-sudo/sudo.plugin.zsh
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
[ -f /usr/share/doc/pkgfile/command-not-found.zsh ] && source /usr/share/doc/pkgfile/command-not-found.zsh

### P10K
source ~/powerlevel10k/powerlevel10k.zsh-theme
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#KEY-BINDINGS
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^R' history-incremental-search-backward
