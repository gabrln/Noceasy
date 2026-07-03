NOCTALIA V5 + MANGOWM + CACHYOS.

## Stack

| Camada | Ferramenta |
|--------|------------|
| Compositor | MangoWM |
| Shell | Noctalia V5 |
| Terminal | Kitty |
| Gerenciador de Arquivos | Yazi + Nautilus |
| Multiplexador | Zellij |
| Prompt | Starship |
| Editor | Neovim |
| Pacotes | yay (AUR helper) |

## Instalação e Gerenciamento Declarativo (decman)

Agora a configuração do sistema e pacotes é gerenciada declarativamente com o **decman**.

```bash
# 1. Execute o script de setup para instalar o decman
./decman_setup.sh

# 2. Simule as alterações declaradas
sudo decman --source ./source.py --dry-run

# 3. Aplique as configurações e instale os pacotes declarados
sudo decman --source ./source.py
```

> [!NOTE]
> O arquivo [source.py](file:///home/gabrln/projects/Arch-gabrln/source.py) contém a declaração de todos os pacotes (Pacman e AUR), arquivos de configuração (como `.zshenv` e configurações de estado do Noctalia) e diretórios do `.config`.

## Pacotes Importantes e de Usuário Declarados

Esta é a lista organizada de pacotes gerenciados pelo `decman` no sistema para auditoria, controle e replicação de novas instalações:

### 1. Core e Subsistema do Sistema (Hardware & System)
* **`base` / `base-devel`**: Metapacotes fundamentais do Arch Linux.
* **`linux-cachyos` / `linux-cachyos-headers`**: Kernel otimizado Linux CachyOS.
* **`docker`**: Plataforma de containers.
* **`flatpak`**: Distribuição de aplicações sandboxed.
* **`snapper`**: Criação automática de snapshots (backup/restauração do Btrfs).
* **`just`**: Executor de comandos para automação local.
* **`rtkit`**: RealtimeKit daemon para priorização de áudio em tempo real.
* **`brightnessctl`**: Controle de brilho físico da tela.

### 2. Interface Gráfica e Window Manager (GUI Stack)
* **`mangowm-git` (AUR)**: Compositor/Window Manager Wayland baseado em dwl.
* **`noctalia-git` (AUR)**: Shell gráfico unificado (painéis, notificações, widgets).
* **`noctalia-greeter-git` (AUR)**: Gerenciador de login personalizado baseado em greetd.
* **`xdg-desktop-portal-wlr`**: Integração de portal (telas, arquivos) sob compositores wlroots.
* **`nwg-look`**: Utilitário gráfico de temas GTK3/GTK4.
* **`pavucontrol`**: Mixer gráfico de volume para controle de áudio (PipeWire/Pulse).
* **`bibata-cursor-theme` (AUR)**: Tema gráfico moderno para o ponteiro do cursor.

### 3. Aplicações de Usuário (User Apps)
* **`firefox`**: Navegador web padrão.
* **`kitty`**: Emulador de terminal acelerado por GPU.
* **`neovim`**: Editor de texto / ambiente de desenvolvimento.
* **`zellij`**: Multiplexador de terminais moderno em Rust.
* **`yazi`**: Gerenciador de arquivos CLI rápido com previews.
* **`nautilus`**: Gerenciador de arquivos gráfico oficial do GNOME.
* **`vesktop`**: Discord client otimizado para Wayland (captura de tela ativa).
* **`obsidian`**: Base de conhecimento e notas em markdown local.
* **`spotify-launcher`**: Inicializador oficial do cliente de streaming de música Spotify.
* **`prismlauncher`**: Launcher de Minecraft livre e open source.

### 4. CLI Modern Tooling & Utilidades
* **`zsh`**: Shell principal configurado em `~/.config/zsh`.
* **`atuin`**: Busca interativa de histórico SQLite de comandos.
* **`starship`**: Prompt de comando customizado em Rust.
* **`zoxide` / `direnv`**: Navegação rápida de pastas e ativação automática de ambientes.
* **`fzf` / `ripgrep` / `fd` / `bat` / `eza`**: Substitutos modernos para comandos clássicos do Linux (`find`, `grep`, `ls`, etc.).
* **`fastfetch` / `btop`**: Monitor de hardware e info do sistema.
* **`grim` / `slurp`**: Captura de telas para sessões Wayland.
* **`cliphist` / `wl-clipboard` / `wl-clip-persist`**: Gerenciador e persistência de área de transferência Wayland.
* **`gnome-keyring` / `seahorse`**: Daemon oficial de chaveiro (segredos) e gerenciador gráfico de credenciais.
