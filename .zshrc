# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(sudo colored-man-pages extract copypath copyfile web-search)

source $ZSH/oh-my-zsh.sh

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

### ALIASES
# general & navigation
alias c="clear"
alias q="exit"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# modern cli tools
# install eza and bat via 'paru -S eza bat'
if command -v eza &>/dev/null; then
    alias ls="eza --icons --color=always --group-directories-first"
    alias ll="eza -lah --icons --color=always --group-directories-first"
    alias la="eza -A --icons --color=always"
    alias lt="eza --tree --level=2 --icons"
else
    alias ls="ls --color=auto"
    alias ll="ls -lah"
    alias la="ls -A"
fi

if command -v bat &>/dev/null; then
    alias cat="bat --style=plain"
fi

alias grep="rg"
alias find="fd"

# package manager
alias update="paru -Syu"
alias install="paru -S"
alias remove="paru -Rns"
alias search="paru -Ss"

# build
alias make="make -j\$(nproc)"
alias ninja="ninja -j\$(nproc)"

# config shortcuts
alias conf-hypr="nvim ~/.config/hypr/hyprland.lua"
alias conf-zsh="nvim ~/.zshrc"
alias reload-hypr="hyprctl reload"
alias reload-zsh="source ~/.zshrc && echo 'Zsh config reloaded!'"

# git
alias g="git"
alias gst="git status -sb"
alias gd="git diff"
alias gl="git log --oneline -n 10"
alias gp="git push"
alias gpl="git pull"
alias ga="git add"
alias gc="git commit -m"

# zellij
alias zj="zellij"
alias zja="zellij attach"
alias zjl="zellij list-sessions"
alias zjda="zellij delete-all-sessions --force"
alias conf-zj="nvim ~/.config/zellij/config.kdl"

# docker
docker-start() {
    sudo systemctl start docker
    if systemctl is-active --quiet docker; then
        notify-send "Docker" "Active" -i docker -u normal
    else
        notify-send "Docker" "Failed to start" -i dialog-error -u critical
    fi
}
docker-stop() {
    sudo systemctl stop docker
    if ! systemctl is-active --quiet docker; then
        notify-send "Docker" "Inactive" -i docker -u normal
    else
        notify-send "Docker" "Failed to stop" -i dialog-error -u critical
    fi
}
docker-status() {
    if systemctl is-active --quiet docker; then
        notify-send "Docker" "Active" -i docker
    else
        notify-send "Docker" "Inactive" -i docker
    fi
}
alias dk-start="docker-start"
alias dk-stop="docker-stop"
alias dk-status="docker-status"

### PLUGINS (System-wide)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

### KEY-BINDINGS
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^R' history-incremental-search-backward

# Yazi wrapper: cd into the directory yazi exits in
function y() {
    local tmp=$(mktemp -t yazi-cwd.XXXXX)
    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
        local cwd=$(cat "$tmp")
        rm -f "$tmp"
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
    fi
}

# Zoxide initialization
eval "$(zoxide init zsh)"
