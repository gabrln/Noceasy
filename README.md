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


