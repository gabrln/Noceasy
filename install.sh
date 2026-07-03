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
    # Base system
    base base-devel linux-cachyos linux-cachyos-headers git git-delta docker flatpak brightnessctl zsh snapper just
    # Zsh and terminal tooling
    atuin bat eza fzf ripgrep fd zoxide starship direnv fastfetch btop grim slurp
    # User applications
    neovim kitty zellij yazi nautilus vesktop cliphist wl-clipboard duf gping tealdeer procs cava
    # Media and files
    mpv swayimg zathura file-roller rclone firefox obsidian pavucontrol nwg-look xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    # Themes and tools
    wl-clip-persist papirus-icon-theme adw-gtk-theme protonup-qt prismlauncher spotify-launcher gnome-keyring seahorse rtkit niri
    # System utilities & essentials
    rsync wget openssh pv hwinfo meld fsarchiver nano nano-syntax-highlighting python-defusedxml python-packaging
)
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

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

# Make sure scripts are executable
find "$REPO_DIR/.config/niri/scripts" -type f -name "*.sh" -exec chmod +x {} +

# 7. Setup Neovim (LazyVim & Noctalia theme integration)
print_step "Setting up Neovim with LazyVim & Noctalia integration..."
NVIM_DIR="$HOME/.config/nvim"

if [ ! -d "$NVIM_DIR" ]; then
    echo -e "${YELLOW}No Neovim configuration found. Installing LazyVim starter...${NC}"
    git clone https://github.com/LazyVim/starter "$NVIM_DIR"
    rm -rf "$NVIM_DIR/.git"
fi

# Ensure directories exist
mkdir -p "$NVIM_DIR/lua/plugins"

# Write Matugen template for Noctalia
echo -e "${YELLOW}Writing Matugen template for Noctalia integration...${NC}"
cat << 'EOF' > "$NVIM_DIR/lua/matugen-template.lua"
local M = {}

function M.setup()
  require('base16-colorscheme').setup {
    -- Background tones
    base00 = '{{colors.surface.default.hex}}', -- Default Background
    base01 = '{{colors.surface_container.default.hex}}', -- Lighter Background (status bars)
    base02 = '{{colors.surface_container_high.default.hex}}', -- Selection Background
    base03 = '{{colors.outline.default.hex}}', -- Comments, Invisibles
    -- Foreground tones
    base04 = '{{colors.on_surface_variant.default.hex}}', -- Dark Foreground (status bars)
    base05 = '{{colors.on_surface.default.hex}}', -- Default Foreground
    base06 = '{{colors.on_surface.default.hex}}', -- Light Foreground
    base07 = '{{colors.on_background.default.hex}}', -- Lightest Foreground
    -- Accent colors
    base08 = '{{colors.error.default.hex}}', -- Variables, XML Tags, Errors
    base09 = '{{colors.tertiary.default.hex}}', -- Integers, Constants
    base0A = '{{colors.secondary.default.hex}}', -- Classes, Search Background
    base0B = '{{colors.primary.default.hex}}', -- Strings, Diff Inserted
    base0C = '{{colors.tertiary_fixed_dim.default.hex}}', -- Regex, Escape Chars
    base0D = '{{colors.primary_fixed_dim.default.hex}}', -- Functions, Methods
    base0E = '{{colors.secondary_fixed_dim.default.hex}}', -- Keywords, Storage
    base0F = '{{colors.error_container.default.hex}}', -- Deprecated, Embedded Tags
  }
end

-- Register a signal handler for SIGUSR1 (matugen updates)
local signal = vim.uv.new_signal()
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
EOF

# Write LazyVim plugin definition for base16-nvim and Matugen setup
if [ ! -f "$NVIM_DIR/lua/plugins/matugen.lua" ]; then
    echo -e "${YELLOW}Writing LazyVim plugin file for Noctalia theme...${NC}"
    cat << 'EOF' > "$NVIM_DIR/lua/plugins/matugen.lua"
return {
  -- Installs the base16-nvim colorscheme
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- Load matugen if it exists, otherwise fall back gracefully
      pcall(function()
        require("matugen").setup()
      end)
    end,
  },
  -- Configure LazyVim to load the base16 colorscheme by default
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "base16-colorscheme",
    },
  },
}
EOF
fi

# 8. Copy System Configurations (Requires sudo)
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

# 9. Symlink themes for Root user (GParted, btrfs-assistant, Greetd Greeter compatibility)
print_step "Linking user themes for root application accessibility..."
sudo mkdir -p /root/.config
sudo ln -sfT "$HOME/.config/gtk-3.0" /root/.config/gtk-3.0
sudo ln -sfT "$HOME/.config/gtk-4.0" /root/.config/gtk-4.0
sudo ln -sfT "$HOME/.config/qt6ct" /root/.config/qt6ct
sudo mkdir -p /root/.local/share
sudo ln -sfT "$HOME/.local/share/icons" /root/.local/share/icons

# 10. Enable Systemd Services
print_step "Enabling Systemd units..."
SERVICES=(
    docker.service
    bluetooth.service
    NetworkManager.service
    greetd.service
)
for svc in "${SERVICES[@]}"; do
    sudo systemctl enable "$svc"
done

echo -e "${GREEN}=== Setup Installation & Sync Completed successfully! ===${NC}"
