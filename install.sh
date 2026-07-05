#!/usr/bin/env bash
# install.sh - Installation & bootstrap script for Arch-gabrln setup
# Target: CachyOS (minimal install, no desktop).

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

print_step "=== Iniciando Instalação do Setup Arch-gabrln ==="

# Identificar o usuário real e seu diretório HOME
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Configurar regra temporária no sudoers se executado como root para que comandos rodando
# como usuário (ex: makepkg em AUR) não peçam senha
if [[ $EUID -eq 0 ]]; then
    TEMP_SUDOERS="/etc/sudoers.d/99-arch-gabrln-installer-temp"
    echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" > "$TEMP_SUDOERS"
    chmod 440 "$TEMP_SUDOERS"
    trap 'rm -f "$TEMP_SUDOERS"' EXIT INT TERM HUP
fi

# Função auxiliar para executar comandos sem privilégios de root (como usuário normal)
run_as_user() {
    if [[ $EUID -eq 0 ]]; then
        sudo -u "$REAL_USER" --preserve-env=PATH,HOME bash -c "$@"
    else
        bash -c "$@"
    fi
}

# Sincronizar bases de dados de pacotes
echo -e "${YELLOW}Sincronizando base de dados do Pacman...${NC}"
sudo pacman -Sy

# Garantir que git está instalado e clonar repositório se necessário
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}Instalando git...${NC}"
    sudo pacman -S --needed --noconfirm git
fi

REPO_DIR="$USER_HOME/projects/Arch-gabrln"
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Clonando repositório para $REPO_DIR...${NC}"
    run_as_user "mkdir -p '$USER_HOME/projects' && git clone https://github.com/gabrln/Arch-gabrln.git '$REPO_DIR'"
fi

# 2. Instalar/Atualizar shelly (Modern Package Manager)
if ! command -v shelly &>/dev/null; then
    echo -e "${YELLOW}Instalando 'shelly' para gerenciamento de pacotes...${NC}"
    sudo pacman -S --needed --noconfirm base-devel git
    if ! pacman -S --needed --noconfirm shelly 2>/dev/null; then
        run_as_user "rm -rf /tmp/shelly-bin && git clone https://aur.archlinux.org/shelly-bin.git /tmp/shelly-bin && cd /tmp/shelly-bin && makepkg -si --noconfirm && rm -rf /tmp/shelly-bin"
    fi
fi

# 3. Instalar pacotes oficiais via Pacman
print_step "Instalando pacotes oficiais dos repositórios..."
OFFICIAL_PKGS=(
    # Base system & build tools for plugins (hyprpm)
    base base-devel linux-cachyos linux-cachyos-headers cmake cpio pkgconf git git-delta docker flatpak brightnessctl zsh snapper just nodejs npm unzip
    # Networking & Bluetooth
    networkmanager bluez bluez-utils
    # Display manager & Polkit
    greetd polkit
    # Zsh and terminal tooling
    atuin bat eza fzf ripgrep fd zoxide starship direnv fastfetch btop grim slurp
    # User applications
    neovim kitty zellij yazi thunar thunar-archive-plugin thunar-volman tumbler gvfs vesktop cliphist wl-clipboard duf gping tealdeer procs cava
    # Media and files
    mpv swayimg zathura file-roller rclone firefox obsidian pavucontrol nwg-look xdg-user-dirs xdg-user-dirs-gtk xdg-desktop-portal-gtk
    # Themes, fonts and tools
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji wl-clip-persist papirus-icon-theme adw-gtk-theme qt6ct protonup-qt prismlauncher spotify-launcher gnome-keyring seahorse rtkit hyprland uwsm xdg-desktop-portal-hyprland
    # System utilities & essentials
    rsync wget openssh pv hwinfo meld fsarchiver nano python-defusedxml python-packaging spice-vdagent qemu-guest-agent lua luajit libnotify jq
)
shelly install -n "${OFFICIAL_PKGS[@]}"
hash -r

# 4. Instalar pacotes extras/AUR via shelly
print_step "Instalando pacotes AUR via shelly aur install..."
AUR_PKGS=(
    noctalia-git
    noctalia-greeter-git
    bibata-cursor-theme
    antigravity
)
run_as_user "shelly aur install -n ${AUR_PKGS[*]}"

# 5. Instalar pacotes Flatpak via shelly
if command -v flatpak &>/dev/null; then
    print_step "Instalando pacotes Flatpak via shelly flatpak install..."
    sudo flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    shelly flatpak install -n com.github.wwmm.easyeffects || sudo flatpak install -y --system flathub com.github.wwmm.easyeffects
fi

# 6. Instalar agentes de AI e ferramentas de desenvolvimento
print_step "Instalando ferramentas de coding AI (herdr, pi-coding-agent)..."
if command -v npm &>/dev/null; then
    run_as_user "npm install -g --ignore-scripts --min-release-age=0 @earendil-works/pi-coding-agent 2>/dev/null || true"
fi
if ! command -v herdr &>/dev/null && [ ! -f "$USER_HOME/.local/bin/herdr" ]; then
    run_as_user "curl -sSfL https://herdr.dev/install.sh | sh 2>/dev/null || true"
fi

# 7. Baixar e instalar Wallpapers extras (Google Drive)
print_step "Baixando e instalando pacote de Wallpapers extras..."
WP_DIR="$USER_HOME/Pictures/Wallpapers"
run_as_user "mkdir -p '$WP_DIR'"
WP_TMP="/tmp/wallpapers_extra.zip"
if [ ! -f "$WP_TMP" ]; then
    echo -e "${YELLOW}Obtenção do link do Google Drive (ID: 16MOqfNb1JglRBxBZdhdxfK2qJN3OjOpZ)...${NC}"
    GDRIVE_ID="16MOqfNb1JglRBxBZdhdxfK2qJN3OjOpZ"
    GDRIVE_HTML=$(curl -sL "https://drive.google.com/uc?export=download&id=${GDRIVE_ID}")
    GDRIVE_UUID=$(echo "$GDRIVE_HTML" | grep -o 'name="uuid" value="[^"]*' | cut -d'"' -f4 || true)
    if [ -n "$GDRIVE_UUID" ]; then
        curl -L -o "$WP_TMP" "https://drive.usercontent.google.com/download?id=${GDRIVE_ID}&export=download&confirm=t&uuid=${GDRIVE_UUID}"
    else
        curl -L -o "$WP_TMP" "https://drive.google.com/uc?export=download&confirm=t&id=${GDRIVE_ID}"
    fi
fi
if [ -f "$WP_TMP" ] && file "$WP_TMP" | grep -i -E "zip|archive" &>/dev/null; then
    run_as_user "unzip -o '$WP_TMP' -d '$WP_DIR' 2>/dev/null || true"
    rm -f "$WP_TMP"
fi

# 8. Copiar configurações do usuário (dotfiles)
print_step "Copiando configurações do usuário (dotfiles)..."
run_as_user "mkdir -p '$USER_HOME/.config'"

CONFIGS=(
    zsh
    kitty
    zellij
    yazi
    fastfetch
    gtk-3.0
    gtk-4.0
    xdg-desktop-portal
    docker
    hypr
    uwsm
    noctalia
    nvim
)

for cfg in "${CONFIGS[@]}"; do
    TARGET_PATH="$USER_HOME/.config/$cfg"
    SOURCE_PATH="$REPO_DIR/.config/$cfg"
    if [ ! -d "$SOURCE_PATH" ] && [ ! -f "$SOURCE_PATH" ]; then
        echo -e "${YELLOW}Fonte não encontrada, pulando: $cfg${NC}"
        continue
    fi
    if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
        BACKUP_PATH="${TARGET_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Fazer backup de configuração existente: $cfg -> $(basename "$BACKUP_PATH")${NC}"
        mv "$TARGET_PATH" "$BACKUP_PATH"
        chown -R "$REAL_USER:$REAL_USER" "$BACKUP_PATH"
    fi
    # Remover symlink antigo se existir (migração de ln para cp)
    [ -L "$TARGET_PATH" ] && rm -f "$TARGET_PATH"
    run_as_user "cp -rfT '$SOURCE_PATH' '$TARGET_PATH'"
done

# Arquivos de configuração avulsos
run_as_user "cp -f '$REPO_DIR/.zshenv' '$USER_HOME/.zshenv'"
run_as_user "cp -f '$REPO_DIR/.config/mimeapps.list' '$USER_HOME/.config/mimeapps.list'"

# Atualizar diretórios padrão do usuário (XDG user-dirs) e criar subpastas específicas
run_as_user "xdg-user-dirs-update 2>/dev/null || true"
run_as_user "mkdir -p '$USER_HOME/Pictures/Screenshots' '$USER_HOME/Pictures/Wallpapers' '$USER_HOME/projects'"

# Tornar scripts executáveis
find "$REPO_DIR/.config" -type f \( -name "*.sh" -o -path "*/scripts/*" \) -exec chmod +x {} + 2>/dev/null || true

# 9. Configurar plugins do Hyprland (scrolloverview)
if command -v hyprpm &>/dev/null; then
    print_step "Configurando plugins do Hyprland (scrolloverview)..."
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        run_as_user "hyprpm update 2>/dev/null || true"
        run_as_user "hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git 2>/dev/null || true"
        run_as_user "hyprpm enable scrolloverview 2>/dev/null || true"
    else
        echo -e "${YELLOW}Hyprland não está rodando no momento. Para ativar o scrolloverview depois, execute:${NC}"
        echo -e "${YELLOW}  hyprpm update && hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git && hyprpm enable scrolloverview${NC}"
    fi
fi

# 10. Deploy de configurações globais do sistema
print_step "Configurando arquivos de sistema (greetd, sessões)..."
sudo mkdir -p /etc/greetd
sudo cp "$REPO_DIR/.config/greetd/config.toml" /etc/greetd/config.toml
sudo cp "$REPO_DIR/.config/greetd/pam_greetd" /etc/pam.d/greetd

sudo mkdir -p /var/lib/noctalia-greeter
sudo cp "$REPO_DIR/.config/greetd/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
sudo chown -R greeter:greeter /var/lib/noctalia-greeter 2>/dev/null || true
sudo chmod 644 /var/lib/noctalia-greeter/greeter.toml

# 11. Symlinks de temas para o usuário root (compatibilidade com apps gráficos sudo)
print_step "Vinculando temas para acessibilidade de aplicativos root..."
run_as_user "mkdir -p '$USER_HOME/.config/qt6ct' '$USER_HOME/.local/share/icons'"
sudo mkdir -p /root/.config /root/.local/share
for root_cfg in gtk-3.0 gtk-4.0 qt6ct; do
    sudo rm -rf "/root/.config/$root_cfg"
    sudo ln -sfT "$USER_HOME/.config/$root_cfg" "/root/.config/$root_cfg"
done
sudo rm -rf /root/.local/share/icons
sudo ln -sfT "$USER_HOME/.local/share/icons" /root/.local/share/icons

# 12. Ativar serviços do Systemd
print_step "Ativando serviços do Systemd..."
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

echo -e "${GREEN}=== Instalação e Sincronização concluídas com sucesso! ===${NC}"
