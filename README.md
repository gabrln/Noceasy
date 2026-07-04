# Arch-gabrln Dots

**Noctalia V5 + Hyprland (UWSM + Lua Config) + CachyOS / Arch Linux**

Um ambiente Wayland moderno, focado em performance, produtividade por teclado e estética unificada, configurado 100% em **Lua** (Neovim, Hyprland e Scripts de Automação).

---

## 🛠️ Tech Stack

| Camada | Ferramenta | Descrição |
|---|---|---|
| **Compositor** | [Hyprland](https://hyprland.org/) | Tiling Window Manager dinâmico gerido via **UWSM** e configurado em Lua (`hyprland.lua`). |
| **Desktop Shell** | [Noctalia V5](https://github.com/noctalia/noctalia) | Painéis de controle, launcher, notificações e greeter (`greetd`). |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | Terminal acelerado por GPU com suporte a Dropdown Scratchpad. |
| **Editor** | [Neovim](https://neovim.io/) | Configurado com **LazyVim**, integração de cores dinâmicas com Noctalia. |
| **Gerenciador de Arquivos** | [Yazi](https://github.com/sxyazi/yazi) & Nautilus | TUI ultrarrápida em Rust + GUI moderna do GNOME. |
| **Multiplexador** | [Zellij](https://zellij.dev/) | Multiplexador de terminal moderno com abas e painéis. |
| **Automação & Scripts** | **Lua 5.5 standalone** | Scripts de sistema limpos e rápidos em puro `.lua` sem dependências externas. |

---

## ⚡ Instalação e Bootstrap (`install.sh`)

O script de instalação `install.sh` gerencia de forma totalmente automatizada a instalação de pacotes (Pacman/AUR/Flatpak), backup de pastas existentes em `~/.config/` e a criação dos links simbólicos (symlinks) apontando para este repositório.

Para instalar em qualquer máquina (ou atualizar o ambiente local):

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | bash
```

*(Ou localmente: `cd ~/projects/Arch-gabrln && ./install.sh`)*

> [!NOTE]
> O instalador faz backup automático com timestamp (ex: `hypr.backup.YYYYMMDD_HHMMSS`) de qualquer diretório local não-symlink antes de vincular as configurações ao Git.

---

## ✨ Destaques e Dicionário de Recursos

* **Configuração Hyprland em Lua (`hyprland.lua`):** Substituição completa dos antigos arquivos estáticos `.conf` pelo loader oficial em Lua, permitindo lógica programática, animações fluidas e regras consolidadas.
* **Scratchpads Inteligentes e Focados:** Workspaces especiais geridos diretamente pela API do Hyprland com `stay_focused = true` e dimensões padronizadas (`1600x900`):
  * `Super + Shift + Return`: Terminal Dropdown (`kitty-drop`).
  * `Super + F1`: Monitor de Recursos (`btop-scratch`).
  * `Super + /`: Cheat Sheet e Buscador de Atalhos (`keyhints-scratch`).
* **Scripts Standalone em Lua (`~/.config/hypr/scripts/`):**
  * `WindowInfo.lua`: Leitura nativa e exibição instantânea de dados da janela ativa (Endereço, PID, Classe/App ID, Workspace) via `notify-send`.
  * `AltF4.lua`: Encerramento seguro com verificação de processos protegidos do sistema (Noctalia, UWSM, Pipewire) e fallback de fechamento forçado (`kill -9`).
  * `KeyHints.lua`: Lista interativa de atalhos alinhada em memória, integrada com `fzf` para pesquisa rápida e cópia automática para o clipboard (`wl-copy`).
* **Integração Visual Total (Noctalia + LazyVim):** Sincronização em tempo real do tema visual entre o Noctalia Shell, GTK/Qt, Greeter na tela de login e Neovim.

---

## ⌨️ Atalhos Principais

| Atalho | Ação |
|---|---|
| `Super + Return` | Abrir Terminal (Kitty) |
| `Super + B` | Abrir Navegador (Firefox) |
| `Super + D` | Launcher de Aplicativos (Noctalia) |
| `Super + /` | Cheat Sheet de Atalhos interativo |
| `Super + Shift + Return` | Toggle Terminal Dropdown (Scratchpad) |
| `Super + Shift + Q` | Fechar Janela (`closewindow`) |
| `Alt + F4` | Fechar/Encerrar Janela com segurança (`AltF4.lua`) |
| `Super + Shift + D` | Notificação com Informações da Janela Ativa (`WindowInfo.lua`) |
| `Super + V` | Histórico da Área de Transferência (Clipboard) |
| `Super + P` | Painel de Controle e Configurações Rápidas |
