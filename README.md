# Arch-gabrln

Ambiente Wayland focado em produtividade e estética unificada no **Arch Linux / CachyOS**, configurado em puro **Lua**.

## Stack

* **Compositor & Shell**: Hyprland (UWSM + Lua Config) + Noctalia V5
* **Terminal & TUI**: Kitty, Zellij, Neovim e Yazi
* **Pacotes**: Shelly CLI (ALPM, AUR e Flatpak)
* **AI Coding**: Antigravity CLI, Herdr e Pi-coding-agent

## Instalação

O instalador automatiza a instalação de pacotes, diretórios XDG, wallpapers e sincroniza os dotfiles.

**Opção 1: Instalação Padrão**
```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | bash
```

**Opção 2: Sem redigitar senha (Recomendado)**
Caso não queira digitar a senha de administrador (`sudo`) várias vezes durante o processo de instalação dos pacotes e serviços, execute passando as variáveis para o root desde o início:
```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo -E bash
```

## Pós-instalação

O `install.sh` roda antes do primeiro login gráfico, num TTY sem sessão Hyprland ativa. O plugin **scrolloverview** (necessário para o atalho `Alt + Tab`) é instalado automaticamente pelo `autostart.lua` no primeiro login, quando o Hyprland já está funcional.

Se o atalho `Alt + Tab` não funcionar após o primeiro login, execute manualmente:

```bash
hyprpm update
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm enable scrolloverview
```

## Atalhos Principais

| Atalho | Ação |
|---|---|
| `Super + T` | Terminal (Kitty) |
| `Super + Shift + T` | Terminal Dropdown (Scratchpad) |
| `Super + D` | Launcher de Aplicativos |
| `Alt + Tab` | Overview de Janelas / Workspaces |
| `Super + B` | Navegador (Firefox) |
| `Super + /` | Cheat Sheet interativo de atalhos |
| `Super + G` | Modo Abas (Grupos) |
| `Super + V` | Histórico da Área de Transferência |
| `Super + Shift + W` | Alternar Tema Claro / Escuro |
| `Super + Q` / `Alt + F4` | Fechar Janela |
