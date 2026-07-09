# Noceasy

Fast installer for Noctalia v5 (Hyprland/Qt6 shell) on Arch/CachyOS.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Noceasy/main/install.sh | sudo bash
```

## Problems

| Error | Fix |
|---|---|
| `Unsupported distribution` | Only Arch and CachyOS |
| `Python 3.11+ required` | `pacman -S python` |
| `python-rich not found` | `pacman -S python-rich` |
| `pacman: unable to find linux-cachyos` | You're on Arch, not CachyOS — auto-filtered |
| `polkit: ... authentication required` | Enable `polkit-gnome-authentication-agent-1` in autostart |
| `hyprpm: command not found` | Re-run install |

Logs in `installer/logs/`. See `installer/README.md` for internals.
