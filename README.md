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

## Instalação

```bash
# Clonar
git clone git@github.com:gabrln/Arch-gabrln.git ~/dotfiles

# Symlinkar (ou usar stow)
ln -sf ~/dotfiles/.zshenv ~/.zshenv
stow -R -d ~/dotfiles -t ~/ .config

# Instalar pacotes
sudo pacman -S $(grep -v '^#' ~/dotfiles/packages.txt)

# AUR
yay -S bibata-cursor-theme
```

