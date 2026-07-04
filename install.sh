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

print_step "=== Iniciando Instalação do Setup Arch-gabrln ==="

# 1. Elevação de privilégios única no início do script
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}:: Solicitando senha de administrador (sudo) apenas uma vez para toda a instalação...${NC}"
    exec sudo -E bash "$0" "$@"
fi

# Identificar o usuário real e seu diretório HOME
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Configurar regra temporária no sudoers para garantir que comandos rodando como o usuário
# (ex: yay e makepkg ao instalar pacotes AUR) nunca peçam senha novamente
TEMP_SUDOERS="/etc/sudoers.d/99-arch-gabrln-installer-temp"
echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" > "$TEMP_SUDOERS"
chmod 440 "$TEMP_SUDOERS"

# Garantir remoção automática da regra temporária ao sair ou interromper o script
trap 'rm -f "$TEMP_SUDOERS"' EXIT INT TERM HUP

# Função auxiliar para executar comandos sem privilégios de root (como usuário normal)
run_as_user() {
    sudo -u "$REAL_USER" --preserve-env=PATH,HOME bash -c "$@"
}

# Sincronizar bases de dados de pacotes
echo -e "${YELLOW}Sincronizando base de dados do Pacman...${NC}"
pacman -Sy

# Garantir que git está instalado e clonar repositório se necessário
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}Instalando git...${NC}"
    pacman -S --needed --noconfirm git
fi

REPO_DIR="$USER_HOME/projects/Arch-gabrln"
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Clonando repositório para $REPO_DIR...${NC}"
    run_as_user "mkdir -p '$USER_HOME/projects' && git clone https://github.com/gabrln/Arch-gabrln.git '$REPO_DIR'"
fi

# 2. Instalar/Atualizar shelly (Modern Package Manager)
if ! command -v shelly &>/dev/null; then
    echo -e "${YELLOW}Instalando 'shelly' para gerenciamento de pacotes...${NC}"
    pacman -S --needed --noconfirm base-devel git
    if ! pacman -S --needed --noconfirm shelly 2>/dev/null; then
        run_as_user "rm -rf /tmp/shelly-bin && git clone https://aur.archlinux.org/shelly-bin.git /tmp/shelly-bin && cd /tmp/shelly-bin && makepkg -si --noconfirm && rm -rf /tmp/shelly-bin"
    fi
fi

# 3. Instalar pacotes oficiais via Pacman
print_step "Instalando pacotes oficiais dos repositórios..."
OFFICIAL_PKGS=(
    # Base system & build tools for plugins (hyprpm)
    base base-devel linux-cachyos linux-cachyos-headers cmake cpio pkgconf git git-delta docker flatpak brightnessctl zsh snapper just nodejs npm unzip
    # Zsh and terminal tooling
    atuin bat eza fzf ripgrep fd zoxide starship direnv fastfetch btop grim slurp
    # User applications
    neovim kitty zellij yazi nautilus vesktop cliphist wl-clipboard duf gping tealdeer procs cava
    # Media and files
    mpv swayimg zathura file-roller rclone firefox obsidian pavucontrol nwg-look xdg-user-dirs xdg-user-dirs-gtk xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    # Themes and tools
    wl-clip-persist papirus-icon-theme adw-gtk-theme protonup-qt prismlauncher spotify-launcher gnome-keyring seahorse rtkit niri hyprland uwsm xdg-desktop-portal-hyprland
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
    niri-scratchpad-rs-git
    antigravity
)
run_as_user "shelly aur install -n ${AUR_PKGS[*]}"

# 5. Instalar pacotes Flatpak via shelly
if command -v flatpak &>/dev/null; then
    print_step "Instalando pacotes Flatpak via shelly flatpak install..."
    flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    shelly flatpak install -n com.github.wwmm.easyeffects || flatpak install -y --system flathub com.github.wwmm.easyeffects
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

# 8. Criar links simbólicos para as configurações do usuário
print_step "Configurando links simbólicos (dotfiles)..."
REPO_DIR="$USER_HOME/projects/Arch-gabrln"
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
    niri
    docker
    hypr
    uwsm
    noctalia
    nvim
)

for cfg in "${CONFIGS[@]}"; do
    TARGET_PATH="$USER_HOME/.config/$cfg"
    if [ -e "$TARGET_PATH" ] && [ ! -L "$TARGET_PATH" ]; then
        BACKUP_PATH="${TARGET_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Fazer backup de configuração existente: $cfg -> $(basename "$BACKUP_PATH")${NC}"
        mv "$TARGET_PATH" "$BACKUP_PATH"
        chown -R "$REAL_USER:$REAL_USER" "$BACKUP_PATH"
    fi
    run_as_user "ln -sfT '$REPO_DIR/.config/$cfg' '$TARGET_PATH'"
done

# Arquivos de configuração avulsos
run_as_user "ln -sf '$REPO_DIR/.zshenv' '$USER_HOME/.zshenv'"
run_as_user "ln -sf '$REPO_DIR/.config/mimeapps.list' '$USER_HOME/.config/mimeapps.list'"
run_as_user "ln -sf '$REPO_DIR/.config/user-dirs.dirs' '$USER_HOME/.config/user-dirs.dirs'"
run_as_user "ln -sf '$REPO_DIR/.config/user-dirs.locale' '$USER_HOME/.config/user-dirs.locale'"
run_as_user "ln -sf '$REPO_DIR/.config/starship.toml' '$USER_HOME/.config/starship.toml'"

# Criar diretórios padrão do usuário (XDG user-dirs) e sincronizar
run_as_user "mkdir -p '$USER_HOME/Desktop' '$USER_HOME/Downloads' '$USER_HOME/Templates' '$USER_HOME/Public' '$USER_HOME/Documents' '$USER_HOME/Music' '$USER_HOME/Pictures/Screenshots' '$USER_HOME/Pictures/Wallpapers' '$USER_HOME/Videos' '$USER_HOME/Projects' '$USER_HOME/projects'"
run_as_user "xdg-user-dirs-update 2>/dev/null || true"

# Tornar scripts executáveis
find "$REPO_DIR/.config" -type f \( -name "*.sh" -o -path "*/scripts/*" \) -exec chmod +x {} + 2>/dev/null || true

# 7. Setup do Neovim
print_step "Configuração do Neovim vinculada via symlink. Pulando..."

# 8. Configurar plugins do Hyprland (scrolloverview)
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

# 9. Deploy de configurações globais do sistema
print_step "Configurando arquivos de sistema (greetd, sessões)..."
mkdir -p /etc/greetd
cp "$REPO_DIR/.config/greetd/config.toml" /etc/greetd/config.toml
cp "$REPO_DIR/.config/greetd/pam_greetd" /etc/pam.d/greetd

mkdir -p /usr/share/wayland-sessions
cp "$REPO_DIR/.config/niri/niri.desktop" /usr/share/wayland-sessions/niri.desktop

mkdir -p /var/lib/noctalia-greeter
cp "$REPO_DIR/.config/greetd/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
chown -R greeter:greeter /var/lib/noctalia-greeter 2>/dev/null || true
chmod 644 /var/lib/noctalia-greeter/greeter.toml

# 10. Symlinks de temas para o usuário root (compatibilidade com apps gráficos sudo)
print_step "Vinculando temas para acessibilidade de aplicativos root..."
run_as_user "mkdir -p '$USER_HOME/.config/qt6ct' '$USER_HOME/.local/share/icons'"
mkdir -p /root/.config /root/.local/share
for root_cfg in gtk-3.0 gtk-4.0 qt6ct; do
    rm -rf "/root/.config/$root_cfg"
    ln -sfT "$USER_HOME/.config/$root_cfg" "/root/.config/$root_cfg"
done
rm -rf /root/.local/share/icons
ln -sfT "$USER_HOME/.local/share/icons" /root/.local/share/icons

# 11. Ativar serviços do Systemd
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
    systemctl enable "$svc" 2>/dev/null || true
done

echo -e "${GREEN}=== Instalação e Sincronização concluídas com sucesso! ===${NC}"
