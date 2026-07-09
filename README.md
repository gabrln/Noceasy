# Arch-gabrln

Ambiente Wayland para Arch/CachyOS: **Hyprland 0.55 + Noctalia V5**.

## Instalação

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | sudo bash
```

Requer Arch ou CachyOS. Roda 16 módulos em ordem, configura o sistema
completo, e sai.

## Atalhos principais

- `Super + T` — Terminal (Kitty)
- `Super + D` — Launcher
- `Alt + Tab` — Overview (hyprpm scrolloverview)
- `Super + B` — Firefox
- `Super + /` — Cheat sheet completo
- `Super + Q` — Fechar janela

## Problemas comuns

| Sintoma | Solução |
|---|---|
| `Distribuição não suportada` | Apenas Arch e CachyOS são suportados |
| `Python 3.11+ necessário` | `pacman -S python` (Arch já tem 3.12+) |
| `python-rich não encontrado` | `pacman -S python-rich` |
| `pacman: unable to find linux-cachyos` | Você está em Arch puro, não CachyOS. O install filtra automaticamente; ignore |
| `polkit: ... authentication required` | Habilite o agent do polkit no autostart: `polkit-gnome-authentication-agent-1` |
| `hyprpm: command not found` | hyprland não foi instalado. Rode `gabrln` (install) de novo |

Para erros mais detalhados, veja os logs em `installer/logs/`. Para
contribuir com o framework, veja `installer/README.md`.
