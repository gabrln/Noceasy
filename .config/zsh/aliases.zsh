# =========================================================
# Aliases & Functions
# =========================================================

# general & navigation
alias c="clear"
alias q="exit"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -='cd -'  # Voltar para o diretório anterior

# eza (modern ls)
if command -v eza &>/dev/null; then
    alias ls="eza --icons --color=always --group-directories-first"
    alias ll="eza -lah --icons --color=always --group-directories-first"
    alias la="eza -A --icons --color=always"
    alias lt="eza --tree --level=2 --icons"
    alias tree="eza --tree --icons"
    compdef eza=ls  # Reutiliza completações do ls para o eza
else
    alias ls="ls --color=auto"
    alias ll="ls -lah"
    alias la="ls -A"
fi

# bat (modern cat)
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
alias conf-niri="nvim ~/.config/niri/config.kdl"
alias conf-zsh="nvim ~/.config/zsh/.zshrc"
alias reload-hypr="hyprctl reload"
alias reload-zsh="source ~/.config/zsh/.zshrc && echo 'Zsh config reloaded!'"

# git
alias g="git"
alias gst="git status -sb"
alias gd="git diff"
alias gl="git log --oneline -n 10"
alias gp="git push"
alias gpl="git pull"
alias ga="git add"
alias gc="git commit -m"
alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'

# zellij
alias zj="zellij"
alias zja="zellij attach"
alias zjl="zellij list-sessions"
alias zjda="zellij delete-all-sessions --force"
alias conf-zj="nvim ~/.config/zellij/config.kdl"

# docker functions
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
