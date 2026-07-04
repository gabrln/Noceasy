# Arch-gabrln Dots

Noctalia V5 + Hyprland (UWSM + Lua Config) + CachyOS / Arch Linux

Ambiente Wayland focado em performance, produtividade por teclado e estética unificada, configurado integralmente em Lua.

---

## Tech Stack

| Camada | Ferramenta | Descrição |
|---|---|---|
| Compositor | Hyprland | Tiling Window Manager dinâmico gerido via UWSM e configurado em Lua. |
| Desktop Shell | Noctalia V5 | Painéis de controle, launcher, notificações e greeter (greetd). |
| Terminal | Kitty | Terminal acelerado por GPU com suporte a Dropdown Scratchpad. |
| Editor | Neovim | Configurado com LazyVim e integração de cores dinâmicas com Noctalia. |
| Gerenciador de Arquivos | Yazi & Nautilus | TUI em Rust + GUI moderna do GNOME. |
| Multiplexador | Zellij | Multiplexador de terminal moderno com abas e painéis. |
| Automação & Scripts | Lua 5.5 | Scripts de sistema standalone em puro Lua sem dependências externas. |

---

## Instalação e Bootstrap (install.sh)

O script de instalação gerencia de forma automatizada a instalação de pacotes (Pacman/AUR/Flatpak), backup de pastas existentes em ~/.config/ e a criação dos links simbólicos apontando para este repositório.

Comando para execução em terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/gabrln/Arch-gabrln/main/install.sh | bash
```

Nota: O instalador realiza backup automático com carimbo de data/hora (ex: hypr.backup.YYYYMMDD_HHMMSS) de qualquer diretório local antes de vincular as configurações ao Git.

---

## Arquitetura Modular Hyprland (Lua)

A configuração do compositor é dividida em módulos especializados localizados em ~/.config/hypr/modules/, carregados dinamicamente via dofile() no arquivo principal hyprland.lua para permitir recarregamento instantâneo sem conflitos de cache:

* env.lua: Variáveis de ambiente, suporte Wayland nativo para Electron, Firefox, Qt6, GDK e fix de diretórios XDG.
* monitors.lua: Configuração de resolução de monitores e regras para workspaces persistentes (1 a 10).
* settings.lua: Layout scrolling, regras de input (teclado BR, touchpad com natural scroll), escala XWayland e configuração do plugin scrolloverview (gesto com 3 dedos).
* animations.lua: Curvas Bezier refinadas e animações fluidas para janelas, painéis e transições de workspace.
* rules.lua: Regras de janela para aplicativos maximizados, Picture-in-Picture, diálogos flutuantes e inibição de idle ao reproduzir vídeos ou músicas em tela cheia.
* keybinds.lua: Mapeamento completo de atalhos por categoria, incluindo navegação por abas (grupos), pin flutuante e overview (scrolloverview). O atalho Super+Shift+Q foi liberado.
* autostart.lua: Inicialização de serviços essenciais na sessão (polkit, gnome-keyring, noctalia, cliphist e easyeffects).

---

## Scripts Standalone (Lua)

Os utilitários em ~/.config/hypr/scripts/ operam como binários independentes:

* WindowInfo.lua: Leitura e exibição instantânea de dados da janela ativa via notify-send.
* AltF4.lua: Encerramento seguro com verificação de processos protegidos do sistema e fallback de fechamento forçado.
* KeyHints.lua: Lista interativa de atalhos em memória, integrada com fzf para pesquisa rápida e cópia para o clipboard via wl-copy.

---

## Atalhos Principais

| Atalho | Ação |
|---|---|
| Super + T | Abrir Terminal (Kitty) |
| Super + Shift + T | Toggle Terminal Dropdown (Scratchpad) |
| Super + Tab | Toggle Overview (suporte nativo a hyprland-scroll-overview) |
| Super + B | Abrir Navegador (Firefox) |
| Super + D | Launcher de Aplicativos (Noctalia) |
| Super + / | Cheat Sheet interativo de atalhos |
| Super + G | Criar/Alternar Grupo de Janelas (Modo Abas) |
| Super + Alt + H / L | Alternar entre Abas do Grupo Anterior/Próximo |
| Super + . / , | Mover Coluna de Rolagem Direita/Esquerda |
| Super + Alt + Space | Fixar Janela Flutuante em Todas Workspaces (Pin) |
| Super + Shift + W | Alternar Tema Claro/Escuro (Noctalia) |
| Super + Q | Fechar Janela |
| Alt + F4 | Fechar/Encerrar Janela com segurança (AltF4.lua) |
| Super + Shift + D | Notificação com Informações da Janela Ativa (WindowInfo.lua) |
| Super + V | Histórico da Área de Transferência |
| Super + P | Painel de Controle e Configurações Rápidas |
