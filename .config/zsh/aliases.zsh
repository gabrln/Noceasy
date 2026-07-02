alias c="clear"
alias q="exit"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -='cd -'

if command -v eza &>/dev/null; then
    alias ls="eza --icons --color=always --group-directories-first"
    alias ll="eza -lah --icons --color=always --group-directories-first"
    alias la="eza -A --icons --color=always"
    alias lt="eza --tree --level=2 --icons"
    alias tree="eza --tree --icons"
    compdef eza=ls
else
    alias ls="ls --color=auto"
    alias ll="ls -lah"
    alias la="ls -A"
fi

if command -v bat &>/dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

alias grep="rg"
alias find="fd"

alias update="yay -Syu"
alias install="yay -S"
alias remove="yay -Rns"
alias search="yay -Ss"

alias make="make -j\$(nproc)"
alias ninja="ninja -j\$(nproc)"

alias conf-mango="nvim ~/.config/mango/mango.conf"
alias conf-zsh="nvim ~/.config/zsh/.zshrc"
alias conf-kitty="nvim ~/.config/kitty/kitty.conf"
alias reload-zsh="source ~/.config/zsh/.zshrc && echo 'Zsh config reloaded!'"

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

alias zj="zellij"
alias zja="zellij attach"
alias zm="zellij attach main || zellij --session main"
alias zjl="zellij list-sessions"
alias zjda="zellij delete-all-sessions --force"
alias conf-zj="nvim ~/.config/zellij/config.kdl"

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

function y() {
    local tmp=$(mktemp -t yazi-cwd.XXXXX)
    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
        local cwd=$(cat "$tmp")
        rm -f "$tmp"
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
    fi
}
