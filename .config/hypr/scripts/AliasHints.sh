#!/usr/bin/env bash
# /* ---- Custom Zsh Aliases & Functions Cheat Sheet ---- */

# Toggle behavior: if yad is already running, kill it and exit
if pidof yad > /dev/null; then
  pkill yad
  exit 0
fi

# Define arguments as a bash array to avoid line-continuation backslash errors
yad_args=(
  --center
  --name="yad-keyhints"
  --title="Zsh Aliases, Custom Commands & Nix Quick Cheat Sheet"
  --no-buttons
  --list
  --column="Category"
  --column="Alias/Command"
  --column="Description"
  --column="Equivalent/Action"
  --width=1000
  --height=650
  
  # Row data: 4 columns per row
  "Zsh" "c" "Clear terminal" "clear"
  "Zsh" "q" "Exit terminal" "exit"
  "Zsh" ".." "Go up one directory" "cd .."
  "Zsh" "-" "Go to previous directory" "cd -"
  "Zsh" "ls" "Modern file listing (eza)" "eza --icons --color=always..."
  "Zsh" "ll" "Detailed modern list" "eza -lah --icons --color=always..."
  "Zsh" "lt / tree" "Display directory tree" "eza --tree --icons"
  "Zsh" "cat" "Modern file view (bat)" "bat --style=plain"
  "Zsh" "grep" "Ripgrep file search" "rg"
  "Zsh" "find" "Fast file/dir find" "fd"
  "Zsh" "y" "Open Yazi (cd on exit)" "yazi wrapper function"
  "Zsh" "zj" "Zellij multiplexer" "zellij"
  
  "Config" "conf-hypr" "Edit Hyprland config" "nvim ~/.config/hypr/hyprland.lua"
  "Config" "conf-zsh" "Edit Zsh config" "nvim ~/.config/zsh/.zshrc"
  "Config" "conf-zj" "Edit Zellij config" "nvim ~/.config/zellij/config.kdl"
  "Config" "reload-hypr" "Reload Hyprland config" "hyprctl reload"
  "Config" "reload-zsh" "Reload Zsh config" "source ~/.config/zsh/.zshrc"
  
  "System" "update" "System update" "paru -Syu"
  "System" "install" "Install system package" "paru -S"
  "System" "remove" "Remove package + configs" "paru -Rns"
  "System" "search" "Search system package" "paru -Ss"
  
  "Docker" "dk-start" "Start Docker daemon" "sudo systemctl start docker"
  "Docker" "dk-stop" "Stop Docker daemon" "sudo systemctl stop docker"
  "Docker" "dk-status" "Check Docker status" "systemctl status docker"
  
  "Nix" "nxi <pkg>" "Install Nix package" "nix profile install nixpkgs#<pkg>"
  "Nix" "nxu <pkg>" "Remove Nix package" "nix profile remove <pkg>"
  "Nix" "nxl" "List installed Nix packages" "nix profile list"
  "Nix" "nxs <pkg>" "Enter temp shell with package" "nix shell nixpkgs#<pkg>"
  "Nix" "nxr <pkg>" "Run package without installing" "nix run nixpkgs#<pkg>"
  "Nix" "nxsearch <pkg>" "Search Nixpkgs registry" "nix search nixpkgs <pkg>"
  "Nix" "nxd" "Develop Nix environment" "nix develop"
  
  "Git" "g" "Git wrapper" "git"
  "Git" "gst" "Git status (short format)" "git status -sb"
  "Git" "gd" "Git diff" "git diff"
  "Git" "gp" "Git push" "git push"
  "Git" "gpl" "Git pull" "git pull"
  "Git" "ga <files>" "Stage files" "git add"
  "Git" "gc '<msg>'" "Commit with message" "git commit -m"
  "Git" "gadog" "Fancy git log graph" "git log --all --graph..."
)

# Launch YAD with the array arguments
yad "${yad_args[@]}"
