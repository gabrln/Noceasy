#!/usr/bin/env bash
# /* ---- Custom Zsh Aliases & Functions Cheat Sheet ---- */

# Toggle behavior: if yad is already running, kill it and exit
if pidof yad > /dev/null; then
  pkill yad
  exit 0
fi

# Use YAD with name yad-keyhints to match Hyprland window rules
yad --center \
    --name="yad-keyhints" \
    --title="Zsh Aliases, Custom Commands & Nix Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column="Alias/Command:" \
    --column="Description:" \
    --column="Equivalent/Action:" \
    --width=1000 --height=650 \
    "ESC" "Close this Cheat Sheet" "" \
    "Zsh Shortcuts" "------------------------------------------------" "------------------------------------------------" \
    "c" "Clear terminal" "clear" \
    "q" "Exit terminal" "exit" \
    ".." "Go up one directory" "cd .." \
    "-" "Go to previous directory" "cd -" \
    "ls" "Modern file listing (eza)" "eza --icons..." \
    "ll" "Detailed modern list" "eza -lah --icons..." \
    "lt / tree" "Display directory tree" "eza --tree" \
    "cat" "Modern file view (bat)" "bat --style=plain" \
    "grep" "Ripgrep file search" "rg" \
    "find" "Fast file/dir find" "fd" \
    "y" "Open Yazi (cd on exit)" "yazi wrapper function" \
    "zj" "Zellij multiplexer" "zellij" \
    "Config Shortcuts" "------------------------------------------------" "------------------------------------------------" \
    "conf-hypr" "Edit Hyprland config" "nvim ~/.config/hypr/hyprland.lua" \
    "conf-zsh" "Edit Zsh config" "nvim ~/.config/zsh/.zshrc" \
    "conf-zj" "Edit Zellij config" "nvim ~/.config/zellij/config.kdl" \
    "reload-hypr" "Reload Hyprland config" "hyprctl reload" \
    "reload-zsh" "Reload Zsh config" "source ~/.config/zsh/.zshrc" \
    "Package Management" "------------------------------------------------" "------------------------------------------------" \
    "update" "System update" "paru -Syu" \
    "install" "Install system package" "paru -S" \
    "remove" "Remove package + configs" "paru -Rns" \
    "search" "Search system package" "paru -Ss" \
    "Docker Controls" "------------------------------------------------" "------------------------------------------------" \
    "dk-start" "Start Docker daemon" "sudo systemctl start docker" \
    "dk-stop" "Stop Docker daemon" "sudo systemctl stop docker" \
    "dk-status" "Check Docker status" "systemctl status docker" \
    "Nix Package Manager" "------------------------------------------------" "------------------------------------------------" \
    "nxi <pkg>" "Install Nix package" "nix profile install nixpkgs#<pkg>" \
    "nxu <pkg>" "Remove Nix package" "nix profile remove <pkg>" \
    "nxl" "List installed Nix packages" "nix profile list" \
    "nxs <pkg>" "Enter temp shell with package" "nix shell nixpkgs#<pkg>" \
    "nxr <pkg>" "Run package without installing" "nix run nixpkgs#<pkg>" \
    "nxsearch <pkg>" "Search Nixpkgs registry" "nix search nixpkgs <pkg>" \
    "nxd" "Develop Nix environment" "nix develop" \
    "Git Commands" "------------------------------------------------" "------------------------------------------------" \
    "g" "Git wrapper" "git" \
    "gst" "Git status (short format)" "git status -sb" \
    "gd" "Git diff" "git diff" \
    "gp" "Git push" "git push" \
    "gpl" "Git pull" "git pull" \
    "ga <files>" "Stage files" "git add" \
    "gc '<msg>'" "Commit with message" "git commit -m" \
    "gadog" "Fancy git log graph" "git log --all --graph..."
