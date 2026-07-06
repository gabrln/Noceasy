# Arch-gabrln

Ambiente Wayland para Arch/CachyOS: **Hyprland (Lua) + Noctalia V5 + Kitty + Zellij + Neovim**.
Stack de pacotes: `pacman` (oficial CachyOS) · `yay` (AUR) · `flatpak`.

## Instalação

```bash
# Padrão
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo -E bash

# Com flags (--gaming, --force, ou ambas)
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo -E bash -s -- --gaming
```

O instalador clona o repo em `~/Projects/Arch-gabrln` e roda o framework `gabrln`. Requer Arch ou CachyOS.

## Comandos

| Comando | O que faz |
|---|---|
| `gabrln install` | Instalação completa (módulos 00–16) |
| `gabrln update` | Atualiza dotfiles, AUR `-git` e hyprpm |
| `gabrln repair` | Reaplicar configs divergentes |
| `gabrln backup` | Snapshot manual das configs |
| `gabrln rollback` | Restaurar snapshot mais recente |
| `gabrln doctor` | Diagnóstico read-only |

Flags: `--gaming` (inclui pacotes gaming) · `--force` (ignora state e reroda).

## Atalhos principais

- `Super + T` — Terminal (Kitty)
- `Super + D` — Launcher
- `Alt + Tab` — Overview (hyprpm scrolloverview)
- `Super + B` — Firefox
- `Super + /` — Cheat sheet completo
- `Super + Q` / `Alt + F4` — Fechar janela
