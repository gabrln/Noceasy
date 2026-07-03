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

# 1. User and home directory
# Locate correct user home via SUDO_USER since decman runs as root
sudo_user = os.environ.get("SUDO_USER", "gabrln")
user_home = f"/home/{sudo_user}"
repo_dir = f"{user_home}/projects/Arch-gabrln"

# Prevent decman from removing locally installed packages
import subprocess
try:
    native_pkgs = subprocess.check_output(["pacman", "-Qqen"]).decode().splitlines()
    decman.pacman.ignored_packages |= set(native_pkgs)
    
    foreign_pkgs = subprocess.check_output(["pacman", "-Qqem"]).decode().splitlines()
    decman.aur.ignored_packages |= set(foreign_pkgs)
except Exception:
    pass

# 2. Pacman packages (Official)
decman.pacman.packages |= {
    # Base system
    "base", "base-devel", "linux-cachyos", "linux-cachyos-headers",
    "git", "git-delta", "docker", "flatpak", "brightnessctl",
    "zsh", "snapper", "just",
    
    # Zsh and terminal tooling
    "atuin", "bat", "eza", "fzf", "ripgrep", "fd", "zoxide", "starship", "direnv",
    "fastfetch", "btop", "grim", "slurp",
    
    # User applications
    "neovim", "kitty", "zellij", "yazi", "nautilus", "vesktop",
    "cliphist", "wl-clipboard", "duf", "gping", "tealdeer", "procs", "cava",
    "mpv", "swayimg", "zathura", "file-roller", "rclone",
    "firefox", "obsidian", "pavucontrol", "nwg-look", "xdg-desktop-portal-gnome", "xdg-desktop-portal-gtk",
    
    # Themes and tools
    "wl-clip-persist", "papirus-icon-theme", "adw-gtk-theme",
    "protonup-qt", "prismlauncher", "spotify-launcher",
    "gnome-keyring", "seahorse", "rtkit", "niri"
}

# 3. AUR packages (via yay/paru)
decman.aur.packages |= {
    "decman",
    "noctalia-git",
    "noctalia-greeter-git",
    "bibata-cursor-theme",
    "niri-scratchpad-rs-git"
}

# 4. Flatpak packages
decman.flatpak.packages |= {
    "com.github.wwmm.easyeffects"
}

# 5. Systemd units
decman.systemd.enabled_units |= {
    "docker.service",
    "bluetooth.service",
    "NetworkManager.service",
    "greetd.service"
}

# 6. Individual files
# Greetd / Noctalia configuration
decman.files["/etc/greetd/config.toml"] = File(
    source_file=f"{repo_dir}/.config/greetd/config.toml",
    owner="root"
)

decman.files["/etc/pam.d/greetd"] = File(
    source_file=f"{repo_dir}/.config/greetd/pam_greetd",
    owner="root"
)

# Niri session desktop entry
decman.files["/usr/share/wayland-sessions/niri.desktop"] = File(
    source_file=f"{repo_dir}/.config/niri/niri.desktop",
    owner="root"
)

# Zsh env
decman.files[f"{user_home}/.zshenv"] = File(
    source_file=f"{repo_dir}/.zshenv",
    owner=sudo_user
)

# Noctalia templates (static templates only)
decman.files[f"{user_home}/.config/noctalia/user-templates.toml"] = File(
    source_file=f"{repo_dir}/.config/noctalia/user-templates.toml",
    owner=sudo_user
)



decman.files[f"{user_home}/.config/niri/scripts/KeyHints.sh"] = File(
    source_file=f"{repo_dir}/.config/niri/scripts/KeyHints.sh",
    permissions=0o755,
    owner=sudo_user
)

decman.files[f"{user_home}/.config/niri/scripts/WindowInfo.sh"] = File(
    source_file=f"{repo_dir}/.config/niri/scripts/WindowInfo.sh",
    permissions=0o755,
    owner=sudo_user
)

decman.files[f"{user_home}/.config/niri/scripts/AltF4.sh"] = File(
    source_file=f"{repo_dir}/.config/niri/scripts/AltF4.sh",
    permissions=0o755,
    owner=sudo_user
)


# Explicit Niri Config file
decman.files[f"{user_home}/.config/niri/config.kdl"] = File(
    source_file=f"{repo_dir}/.config/niri/config.kdl",
    owner=sudo_user
)

# Mimeapps and Starship config files
decman.files[f"{user_home}/.config/mimeapps.list"] = File(
    source_file=f"{repo_dir}/.config/mimeapps.list",
    owner=sudo_user
)

decman.files[f"{user_home}/.config/starship.toml"] = File(
    source_file=f"{repo_dir}/.config/starship.toml",
    owner=sudo_user
)

# User Dirs configurations
decman.files[f"{user_home}/.config/user-dirs.dirs"] = File(
    source_file=f"{repo_dir}/.config/user-dirs.dirs",
    owner=sudo_user
)

decman.files[f"{user_home}/.config/user-dirs.locale"] = File(
    source_file=f"{repo_dir}/.config/user-dirs.locale",
    owner=sudo_user
)

# 7. Config directories (.config)
configs = [
    "zsh",
    "kitty",
    "zellij",
    "yazi",
    "fastfetch",
    "nvim",
    "opencode",
    "gtk-3.0",
    "gtk-4.0",
    "xdg-desktop-portal"
]

for cfg in configs:
    decman.directories[f"{user_home}/.config/{cfg}"] = Directory(
        source_directory=f"{repo_dir}/.config/{cfg}",
        owner=sudo_user
    )


