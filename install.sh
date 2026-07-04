#!/usr/bin/env bash
# install.sh - Installation & bootstrap script for Arch-gabrln setup
# Assumes Arch Linux or CachyOS.

set -euo pipefail

# Output colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}$1${NC}"
    sleep 2
}

print_step "=== Starting Arch-gabrln Setup Installation ==="

# Ensure we are not running as root directly (script will request sudo when needed)
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Do not run this script as root/sudo directly. Run it as normal user.${NC}" 1>&2
   exit 1
fi

# Synchronize package databases to avoid signature/target mismatch errors
echo -e "${YELLOW}Synchronizing package databases...${NC}"
sudo pacman -Sy

# 1. Ensure git is installed and clone the repository if not present
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo pacman -S --needed --noconfirm git
fi

REPO_DIR="$HOME/projects/Arch-gabrln"
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Cloning repository to $REPO_DIR...${NC}"
    mkdir -p "$HOME/projects"
    git clone https://github.com/gabrln/Arch-gabrln.git "$REPO_DIR"
fi

# 2. Install/Update yay (AUR helper)
if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}Installing 'yay' for AUR package support...${NC}"
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# 3. Install Pacman Packages (Official repositories)
print_step "Installing official Pacman packages..."
OFFICIAL_PKGS=(
    # Base system & build tools for plugins (hyprpm)
    base base-devel linux-cachyos linux-cachyos-headers cmake cpio pkgconf git git-delta docker flatpak brightnessctl zsh snapper just
    # Zsh and terminal tooling
    atuin bat eza fzf ripgrep fd zoxide starship direnv fastfetch btop grim slurp
    # User applications
    neovim kitty zellij yazi nautilus vesktop cliphist wl-clipboard duf gping tealdeer procs cava
    # Media and files
    mpv swayimg zathura file-roller rclone firefox obsidian pavucontrol nwg-look xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    # Themes and tools
    wl-clip-persist papirus-icon-theme adw-gtk-theme protonup-qt prismlauncher spotify-launcher gnome-keyring seahorse rtkit niri hyprland uwsm xdg-desktop-portal-hyprland
    # System utilities & essentials
    rsync wget openssh pv hwinfo meld fsarchiver nano python-defusedxml python-packaging spice-vdagent qemu-guest-agent lua luajit libnotify jq
)
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"
hash -r

# 4. Install AUR Packages
print_step "Installing AUR packages..."
AUR_PKGS=(
    noctalia-git
    noctalia-greeter-git
    bibata-cursor-theme
    niri-scratchpad-rs-git
)
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# 5. Install Flatpak Packages
if command -v flatpak &>/dev/null; then
    print_step "Installing Flatpak packages..."
    # Ensure flathub repository is registered system-wide first
    flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y --system flathub com.github.wwmm.easyeffects
fi

# 6. Create Symlinks for User Configurations
print_step "Setting up configuration symlinks..."
REPO_DIR="$HOME/projects/Arch-gabrln"
mkdir -p "$HOME/.config"

CONFIGS=(
    zsh
    kitty
    zellij
    yazi
    fastfetch
    opencode
    gtk-3.0
    gtk-4.0
    xdg-desktop-portal
    niri
    docker
    hypr
    uwsm
    noctalia
    nvim
)

for cfg in "${CONFIGS[@]}"; do
    TARGET_PATH="$HOME/.config/$cfg"
    # Backup physical directories if they exist and are not symlinks
    if [ -d "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
        BACKUP_PATH="${TARGET_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Backing up existing directory: $cfg -> $(basename "$BACKUP_PATH")${NC}"
        mv "$TARGET_PATH" "$BACKUP_PATH"
    fi
    ln -sfT "$REPO_DIR/.config/$cfg" "$TARGET_PATH"
done

# Single configuration files
ln -sf "$REPO_DIR/.zshenv" "$HOME/.zshenv"
ln -sf "$REPO_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
ln -sf "$REPO_DIR/.config/user-dirs.dirs" "$HOME/.config/user-dirs.dirs"
ln -sf "$REPO_DIR/.config/user-dirs.locale" "$HOME/.config/user-dirs.locale"
ln -sf "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Make sure scripts are executable
find "$REPO_DIR/.config" -type f \( -name "*.sh" -o -path "*/scripts/*" \) -exec chmod +x {} + 2>/dev/null || true

# 7. Setup Neovim (LazyVim + Noctalia theme integration)
# The full LazyVim config is already tracked in the repo under .config/nvim.
# The symlink created in step 6 is sufficient — no extra cloning needed.
print_step "Neovim config already handled by symlink (LazyVim). Skipping extra setup..."

# 8. Setup Hyprland Plugins (scrolloverview via hyprpm)
if command -v hyprpm &>/dev/null; then
    print_step "Setting up Hyprland plugins (scrolloverview)..."
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git 2>/dev/null || true
        hyprpm update 2>/dev/null || true
        hyprpm enable scrolloverview 2>/dev/null || true
    else
        echo -e "${YELLOW}Hyprland is not currently running. To enable the scrolloverview plugin later, run:${NC}"
        echo -e "${YELLOW}  hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git && hyprpm update && hyprpm enable scrolloverview${NC}"
    fi
fi

# 9. Copy System Configurations (Requires sudo)
print_step "Deploying system configuration files..."
sudo mkdir -p /etc/greetd
sudo cp "$REPO_DIR/.config/greetd/config.toml" /etc/greetd/config.toml
sudo cp "$REPO_DIR/.config/greetd/pam_greetd" /etc/pam.d/greetd

# Wayland Session desktop entry (Ensure parent folder exists)
sudo mkdir -p /usr/share/wayland-sessions
sudo cp "$REPO_DIR/.config/niri/niri.desktop" /usr/share/wayland-sessions/niri.desktop

# Noctalia Greeter settings
sudo mkdir -p /var/lib/noctalia-greeter
sudo cp "$REPO_DIR/.config/greetd/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
sudo chown greeter:greeter /var/lib/noctalia-greeter/greeter.toml
sudo chmod 644 /var/lib/noctalia-greeter/greeter.toml

# 10. Symlink themes for Root user (GParted, btrfs-assistant, Greetd Greeter compatibility)
print_step "Linking user themes for root application accessibility..."
mkdir -p "$HOME/.config/qt6ct" "$HOME/.local/share/icons"
sudo mkdir -p /root/.config /root/.local/share
sudo ln -sfT "$HOME/.config/gtk-3.0" /root/.config/gtk-3.0
sudo ln -sfT "$HOME/.config/gtk-4.0" /root/.config/gtk-4.0
sudo ln -sfT "$HOME/.config/qt6ct" /root/.config/qt6ct
sudo ln -sfT "$HOME/.local/share/icons" /root/.local/share/icons

# 11. Enable Systemd Services
print_step "Enabling Systemd units..."
SERVICES=(
    docker.service
    bluetooth.service
    NetworkManager.service
    greetd.service
    spice-vdagentd.service
    qemu-guest-agent.service
)
for svc in "${SERVICES[@]}"; do
    sudo systemctl enable "$svc" 2>/dev/null || true
done

echo -e "${GREEN}=== Setup Installation & Sync Completed successfully! ===${NC}"
