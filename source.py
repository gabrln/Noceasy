import os
import decman
from decman import File, Directory

decman.execution_order = [
    "files",
    "pacman",
    "aur",
    "flatpak",
    "systemd"
]

# 1. Obter usuário atual e diretório home
# Decman roda como root, então usamos SUDO_USER para localizar o home do usuário correto
sudo_user = os.environ.get("SUDO_USER", "gabrln")
user_home = f"/home/{sudo_user}"
repo_dir = f"{user_home}/projects/Arch-gabrln"

# Evitar que o decman remova os pacotes explicitamente instalados locais
import subprocess
try:
    native_pkgs = subprocess.check_output(["pacman", "-Qqen"]).decode().splitlines()
    decman.pacman.ignored_packages |= set(native_pkgs)
    
    foreign_pkgs = subprocess.check_output(["pacman", "-Qqem"]).decode().splitlines()
    decman.aur.ignored_packages |= set(foreign_pkgs)
except Exception:
    pass

# 2. Declarar Pacotes Pacman (Oficiais)
decman.pacman.packages |= {
    # Sistema Base e Ferramentas essenciais
    "base", "base-devel", "linux-cachyos", "linux-cachyos-headers",
    "git", "git-delta", "docker", "flatpak", "brightnessctl",
    "zsh", "snapper", "just",
    
    # CLI Modern Tooling (do Zsh & aliases)
    "atuin", "bat", "eza", "fzf", "ripgrep", "fd", "zoxide", "starship", "direnv",
    "fastfetch", "btop", "grim", "slurp",
    
    # Aplicações e Utilitários
    "neovim", "kitty", "zellij", "yazi", "nautilus", "vesktop",
    "cliphist", "wl-clipboard", "duf", "gping", "tealdeer", "procs", "cava",
    "mpv", "swayimg", "zathura", "file-roller", "rclone",
    "firefox", "obsidian", "pavucontrol", "nwg-look", "xdg-desktop-portal-wlr",
    
    # Temas, Protons e Ferramentas CachyOS/Arch
    "wl-clip-persist", "papirus-icon-theme", "adw-gtk-theme",
    "protonup-qt", "prismlauncher", "spotify-launcher",
    "gnome-keyring", "seahorse", "rtkit", "niri"
}

# 3. Declarar Pacotes do AUR (via yay/paru)
decman.aur.packages |= {
    "decman",
    "noctalia-git",
    "noctalia-greeter-git",
    "mangowm-git",
    "bibata-cursor-theme"
}

# 4. Declarar Pacotes Flatpak
decman.flatpak.packages |= {
    "com.github.wwmm.easyeffects"
}

# 5. Habilitar Unidades Systemd
decman.systemd.enabled_units |= {
    "docker.service",
    "bluetooth.service",
    "NetworkManager.service",
    "greetd.service"
}

# 6. Declarar Arquivos Individuais
# Greetd / Noctalia Greeter Configuration
decman.files["/etc/greetd/config.toml"] = File(
    source_file=f"{repo_dir}/.config/greetd/config.toml",
    owner="root"
)

decman.files["/etc/pam.d/greetd"] = File(
    source_file=f"{repo_dir}/.config/greetd/pam_greetd",
    owner="root"
)

# .zshenv do Zsh
decman.files[f"{user_home}/.zshenv"] = File(
    source_file=f"{repo_dir}/.zshenv",
    owner=sudo_user
)

# Noctalia Settings (Arquivo de Estado do Noctalia)
decman.files[f"{user_home}/.local/state/noctalia/settings.toml"] = File(
    source_file=f"{repo_dir}/.config/noctalia/settings.toml",
    owner=sudo_user
)

# Mimeapps e Starship (arquivos avulsos em ~/.config)
decman.files[f"{user_home}/.config/mimeapps.list"] = File(
    source_file=f"{repo_dir}/.config/mimeapps.list",
    owner=sudo_user
)

decman.files[f"{user_home}/.config/starship.toml"] = File(
    source_file=f"{repo_dir}/.config/starship.toml",
    owner=sudo_user
)

# 7. Declarar Diretórios de Configuração (.config)
configs = [
    "zsh",
    "kitty",
    "zellij",
    "yazi",
    "mango",
    "fastfetch",
    "nvim",
    "noctalia",
    "opencode",
    "niri"
]

for cfg in configs:
    decman.directories[f"{user_home}/.config/{cfg}"] = Directory(
        source_directory=f"{repo_dir}/.config/{cfg}",
        owner=sudo_user
    )


