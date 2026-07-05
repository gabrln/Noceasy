if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi

if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [[ -d "$HOME/.local/share/pi-node" ]]; then
    for dir in "$HOME"/.local/share/pi-node/node-*/bin; do
        if [[ -d "$dir" ]]; then
            export PATH="$dir:$PATH"
        fi
    done
fi
