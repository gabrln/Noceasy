#!/usr/bin/env lua
-- KeyHints.lua - Guia de Atalhos interativo do Hyprland em Lua

local shortcuts = {
  -- Categoria: Terminal & Sistema [Hyprland]
  { "─── [Hyprland] TERMINAL & SISTEMA ──────────────────", "", "" },
  { "SUPER + T / Return",        "[Hyprland] Abrir Terminal Padrão (Kitty)",       "kitty" },
  { "SUPER + SHIFT + T / Return","[Hyprland] Abrir Terminal Flutuante (Dropdown)", "kitty-drop (Scratchpad)" },
  { "SUPER + B",                 "[Hyprland] Abrir Navegador Web (Firefox)",       "firefox" },
  { "SUPER + E",                 "[Hyprland] Gerenciador de Arquivos (Yazi TUI)",  "kitty -e yazi" },
  { "SUPER + SHIFT + E",         "[Hyprland] Gerenciador de Arquivos (Thunar)",    "thunar" },
  { "SUPER + F1",                "[Hyprland] Monitor de Recursos (btop)",          "btop-scratch (Scratchpad)" },
  { "SUPER + /",                 "[Hyprland] Guia de Atalhos Interativo",          "keyhints-scratch (Scratchpad)" },
  { "CTRL + ALT + Del",          "[Hyprland] Sair da Sessão do Hyprland",          "hl.dsp.exit()" },
  { "CTRL + ALT + L",            "[Hyprland] Bloquear Tela",                       "noctalia msg session lock" },

  -- Categoria: Janelas & Workspaces [Hyprland]
  { "─── [Hyprland] JANELAS & WORKSPACES ───────────────", "", "" },
  { "SUPER + Q",                 "[Hyprland] Fechar Janela Ativa",                 "hl.dsp.window.close()" },
  { "ALT + F4",                  "[Hyprland] Fechar/Forçar Janela com Segurança",  "lua $HOME/.config/hypr/scripts/AltF4.lua" },
  { "SUPER + H / L",             "[Hyprland] Mover Foco Lateral (Esquerda/Direita)","hl.dsp.focus({ direction = 'left/right' })" },
  { "SUPER + J / K",             "[Hyprland] Alternar Workspace (Próxima/Anterior)","hl.dsp.focus({ workspace = 'e+1/e-1' })" },
  { "SUPER + SHIFT + H / L",     "[Hyprland] Mover Janela Lateralmente",           "hl.dsp.window.move({ direction = 'left/right' })" },
  { "SUPER + SHIFT + J / K",     "[Hyprland] Mover Janela para Workspace Próx/Ant","hl.dsp.window.move({ workspace = 'e+1/e-1' })" },
  { "ALT + Tab",                 "[Hyprland] Abrir/Fechar Visão Geral (Overview)", "toggle_overview" },
  { "Scroll sem SUPER (em Overview)", "[Hyprland] Navegar Lateralmente pelas Janelas", "navigate('left/right')" },
  { "SUPER + Space",             "[Hyprland] Alternar Janela Flutuante",           "hl.dsp.window.float({ action = 'toggle' })" },
  { "SUPER + ALT + Space",       "[Hyprland] Fixar Janela em Todas Workspaces",    "hl.dsp.window.pin({ action = 'toggle' })" },
  { "SUPER + M",                 "[Hyprland] Maximizar Janela Ativa",              "hl.dsp.layout('fit active')" },
  { "SUPER + F",                 "[Hyprland] Alternar Tela Cheia (Fullscreen)",    "hl.dsp.window.fullscreen()" },
  { "SUPER + C",                 "[Hyprland] Centralizar Janela Flutuante",        "hl.dsp.window.center()" },
  { "SUPER + R",                 "[Hyprland] Redimensionar Coluna Predefinida",    "hl.dsp.layout('colresize')" },
  { "SUPER + G",                 "[Hyprland] Criar/Alternar Grupo de Abas",        "hyprctl dispatch togglegroup" },
  { "SUPER + ALT + H / L",       "[Hyprland] Alternar Aba do Grupo (Ant/Próx)",    "hyprctl dispatch changegroupactive b/f" },
  { "SUPER + . / ,",             "[Hyprland] Mover Coluna para Direita/Esquerda",  "hl.dsp.layout('move +/-col')" },
  { "SUPER + [1-9] / 0",         "[Hyprland] Ir para Workspace [1-10]",            "hl.dsp.focus({ workspace = i })" },
  { "SUPER + SHIFT + [1-9] / 0", "[Hyprland] Mover Janela para Workspace [1-10]",  "hl.dsp.window.move({ workspace = i })" },

  -- Categoria: Noctalia Desktop Shell [Noctalia]
  { "─── [Noctalia] DESKTOP SHELL ──────────────────────", "", "" },
  { "SUPER + D",                 "[Noctalia] Menu de Aplicativos (Launcher)",      "noctalia msg panel-toggle launcher" },
  { "SUPER + V",                 "[Noctalia] Histórico de Área de Transferência",  "noctalia msg panel-toggle clipboard" },
  { "SUPER + P",                 "[Noctalia] Painel de Controle Rápido",           "noctalia msg panel-toggle control-center" },
  { "SUPER + SHIFT + P",         "[Noctalia] Menu de Encerramento (Sessão)",       "noctalia msg panel-toggle session" },
  { "SUPER + I",                 "[Noctalia] Configurações do Noctalia",           "noctalia msg settings-toggle" },
  { "SUPER + SHIFT + N",         "[Noctalia] Painel de Notificações",              "noctalia msg panel-toggle control-center notifications" },
  { "SUPER + SHIFT + D",         "[Noctalia] Informações da Janela Ativa",         "lua $HOME/.config/hypr/scripts/WindowInfo.lua" },
  { "SUPER + N",                 "[Noctalia] Alternar Luz Noturna",                "noctalia msg nightlight-toggle" },
  { "SUPER + Y",                 "[Noctalia] Modo Cafeína (Impedir Suspensão)",    "noctalia msg caffeine-toggle" },
  { "SUPER + W",                 "[Noctalia] Trocar Papel de Parede Aleatório",    "noctalia msg wallpaper-random" },
  { "SUPER + SHIFT + W",         "[Noctalia] Alternar Tema Claro/Escuro",          "noctalia msg theme-mode-toggle" },
  { "SUPER + F2",                "[Noctalia] Mutar Microfone",                     "noctalia msg mic-mute" },
  { "SUPER + Print",             "[Noctalia] Capturar Tela Cheia",                 "noctalia msg screenshot-fullscreen" },
  { "SUPER + SHIFT + Print",     "[Noctalia] Capturar Área Selecionada",           "noctalia msg screenshot-region" },
  { "ALT + Print",               "[Noctalia] Capturar Janela Ativa",               "noctalia msg screenshot-fullscreen pick" },

  -- Categoria: Comandos Rápidos e Aliases (CLI) [Command]
  { "─── [Command] CLI & ALIASES ───────────────────────", "", "" },
  { "c / q",                     "[Command] Limpar Terminal / Sair",              "c / q" },
  { ".. / ... / ....",           "[Command] Subir Diretório(s)",                  "cd .. / ... / ...." },
  { "ls / ll / la / lt",         "[Command] Listar Arquivos (com eza)",           "ls / ll / la / lt" },
  { "grep / find",               "[Command] Buscar Arquivos e Textos (rg/fd)",    "rg / fd" },
  { "update",                    "[Command] Atualizar Sistema Completo",          "sudo pacman -Syu && yay -Sua" },
  { "install <pkg>",             "[Command] Instalar Pacote (oficial)",            "sudo pacman -S <pkg>" },
  { "install-aur <pkg>",         "[Command] Instalar Pacote (AUR)",               "yay -S <pkg>" },
  { "remove <pkg>",              "[Command] Remover Pacote e Dependências",       "sudo pacman -Rns <pkg>" },
  { "search <pkg>",              "[Command] Pesquisar Pacote (oficial)",          "pacman -Ss <pkg>" },
  { "search-aur <pkg>",          "[Command] Pesquisar Pacote (AUR)",               "yay -Ss <pkg>" },
  { "make / ninja",              "[Command] Compilação Paralela Rápida",          "make -j$(nproc) / ninja -j$(nproc)" },
  { "conf-hypr",                 "[Command] Editar Configuração do Hyprland",     "nvim ~/.config/hypr/hyprland.lua" },
  { "conf-zsh",                  "[Command] Editar Configuração do Zsh",          "nvim ~/.config/zsh/.zshrc" },
  { "conf-kitty",                "[Command] Editar Configuração do Kitty",        "nvim ~/.config/kitty/kitty.conf" },
  { "reload-zsh",                "[Command] Recarregar Configurações do Zsh",     "source ~/.config/zsh/.zshrc" },
  { "g / gst / gd",              "[Command] Git Status / Diferenças",             "git status/diff" },
  { "ga / gc / gp / gpl",        "[Command] Git Add / Commit / Push / Pull",      "git add/commit/push/pull" },
  { "zj / zja / zm",             "[Command] Gerenciar Sessões Zellij",            "zellij" },
  { "dk-start / dk-stop",        "[Command] Iniciar / Parar Serviço Docker",      "systemctl docker" },
  { "y",                         "[Command] Abrir Yazi (mantendo diretório atual)","y" }
}

local w1 = 0
for _, item in ipairs(shortcuts) do
    if item[2] ~= "" then
        w1 = math.max(w1, #item[1])
    end
end

local lines = {}
local map_action = {}
for _, item in ipairs(shortcuts) do
    local formatted
    if item[2] == "" then
        formatted = item[1]
    else
        formatted = string.format("%-" .. (w1 + 4) .. "s   %s", item[1], item[2])
    end
    table.insert(lines, formatted)
    map_action[formatted] = item[3]
end

local input_str = table.concat(lines, "\n")
local tmp_file = os.tmpname()
local f = io.open(tmp_file, "w")
if f then
    f:write(input_str)
    f:close()
end

local fzf_cmd = 'fzf --no-sort --cycle --header=" [ ENTER: Copiar comando para o clipboard | ESC: Sair ]" --layout=reverse --border=rounded --prompt=" Pesquisar ou Navegar por Categoria: "'
local handle = io.popen(string.format("cat %s | %s", tmp_file, fzf_cmd))
local selected = handle:read("*l")
handle:close()
os.remove(tmp_file)

if selected and selected ~= "" then
    selected = selected:match("^%s*(.-)%s*$")
    local action = map_action[selected]
    if not action then
        action = selected:match(".*%s+([^\n]+)$")
    end
    if action then
        local copy_cmd = string.format("printf '%%s' %q | wl-copy", action)
        os.execute(copy_cmd)
        os.execute(string.format('notify-send "Atalho Copiado" "Comando \'%s\' copiado para o clipboard!" -t 2000 -i edit-copy', action))
    end
end
