-- =========================================================================
-- Hyprland keybindings (Lua module)
-- =========================================================================

local mod = "SUPER"
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts_dir = config_home .. "/hypr/scripts"




-- ═══ Apps ════════════════════════════════════════════════════════════════

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
-- @desc Abrir terminal kitty
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))
-- @desc Abrir navegador Firefox
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("kitty -e yazi"))
-- @desc Abrir gerenciador de arquivos yazi
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("thunar"))
-- @desc Abrir thunar
hl.bind(mod .. " + A",      hl.dsp.exec_cmd("kitty -e herdr"))
-- @desc Abrir herdr


-- ═══ Windows ═════════════════════════════════════════════════════════════

hl.bind(mod .. " + Q",            hl.dsp.window.close())
-- @desc Fechar janela
hl.bind(mod .. " + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1280, y = 720 }))
    hl.dispatch(hl.dsp.window.center())
end)
-- @desc Toggle floating/centralizar
hl.bind(mod .. " + ALT + Space",  hl.dsp.window.pin({ action = "toggle" }))
-- @desc Toggle pinned
hl.bind(mod .. " + C",            hl.dsp.window.center())
-- @desc Centralizar janela

-- Redimensionar janela por pixels (Ctrl + Alt + Setas)
-- @desc Redimensionar janela baixo

-- Grupos e redimensionamento
hl.bind(mod .. " + R",         hl.dsp.layout("colresize +0.1"))
-- @desc Aumentar coluna
hl.bind(mod .. " + SHIFT + R", hl.dsp.layout("colresize -0.1"))
-- @desc Diminuir coluna
hl.bind(mod .. " + G",         hl.dsp.group.toggle())
-- @desc Toggle grupo
hl.bind(mod .. " + ALT + H",   hl.dsp.group.prev())
-- @desc Grupo anterior
hl.bind(mod .. " + ALT + L",   hl.dsp.group.next())
-- @desc Próximo grupo


-- ═══ Focus ═════════════════════════════════════════════════════════════════
-- @group Windows

hl.bind(mod .. " + H", hl.dsp.layout("focus l"))
-- @desc Focar janela à esquerda
hl.bind(mod .. " + L", hl.dsp.layout("focus r"))
-- @desc Focar janela à direita
hl.bind(mod .. " + J", hl.dsp.focus({ workspace = "e+1" }))
-- @desc Próximo workspace
hl.bind(mod .. " + K", hl.dsp.focus({ workspace = "e-1" }))
-- @desc Workspace anterior


-- ═══ Movement ══════════════════════════════════════════════════════════════
-- @group Windows

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
-- @desc Mover janela à esquerda
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
-- @desc Mover janela à direita
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ workspace = "e+1" }))
-- @desc Mover janela próximo workspace
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ workspace = "e-1" }))
-- @desc Mover janela workspace anterior


-- ═══ Layout ════════════════════════════════════════════════════════════════

hl.bind(mod .. " + M",               hl.dsp.layout("fit active"))
-- @desc Ajustar janela ativa
hl.bind(mod .. " + comma",           hl.dsp.layout("-col"))
-- @desc Diminuir colunas
hl.bind(mod .. " + period",          hl.dsp.layout("+col"))
-- @desc Aumentar colunas
hl.bind(mod .. " + SHIFT + comma",   hl.dsp.layout("swapprev"))
-- @desc Trocar janela anterior
hl.bind(mod .. " + SHIFT + period",  hl.dsp.layout("swapnext"))
-- @desc Trocar próxima janela


-- ═══ Workspaces ═══════════════════════════════════════════════════════

for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + X",             hl.dsp.exec_cmd("pypr expose"))
-- @desc Mostrar todas as janelas (expose)
hl.bind(mod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))



-- ═══ Scratchpads ═══════════════════════════════════════════════════════

hl.bind(mod .. " + T",            hl.dsp.exec_cmd("pypr toggle terminal"))
-- @desc Toggle terminal dropdown
hl.bind(mod .. " + F1",     hl.dsp.exec_cmd("pypr toggle btop"))
-- @desc Toggle btop
hl.bind(mod .. " + Slash",  hl.dsp.exec_cmd("pypr toggle keyhints"))
-- @desc Abrir keyhints
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd("pypr toggle spotify"))
-- @desc Toggle Spotify

-- ═══ Noctalia Panels ═══════════════════════════════════════════════════════
-- @group Noctalia

hl.bind(mod .. " + D",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
-- @desc Abrir launcher
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
-- @desc Abrir clipboard
hl.bind(mod .. " + O",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
-- @desc Abrir notificações
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("noctalia msg panel-toggle noctalia/notes:panel"))
-- @desc Toggle notas
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
-- @desc Abrir menu de sessão (lock, logout, etc)
hl.bind(mod .. " + I",         hl.dsp.exec_cmd("noctalia msg settings-toggle"))
-- @desc Abrir configurações do Noctalia


-- ═══ Noctalia Features ═════════════════════════════════════════════════════
-- @group Noctalia

-- Nightlight
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg nightlight-toggle"))
-- @desc Toggle nightlight

-- Caffeine (inibidor de idle)
hl.bind(mod .. " + SHIFT + Y", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))
-- @desc Toggle caffeine

-- Wallpaper e tema
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("noctalia msg wallpaper-random"))
-- @desc Wallpaper aleatório


-- ═══ Session ════════════════════════════════════════════════════════════════

hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))
-- @desc Bloquear tela


-- ═══ Media ══════════════════════════════════════════════════════════════════

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),   { locked = true, repeating = true })
-- @desc Aumentar volume
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
-- @desc Diminuir volume
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
-- @desc Silenciar volume

-- Microfone
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
-- @desc Silenciar microfone
hl.bind(mod .. " + SHIFT + M",  hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
-- @desc Silenciar microfone

-- Brilho
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true, repeating = true })
-- @desc Aumentar brilho
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })
-- @desc Diminuir brilho

-- Reprodução de mídia
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
-- @desc Play/Pausar
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
-- @desc Play/Pausar
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
-- @desc Play/Pausar
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true })
-- @desc Próxima faixa
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true })
-- @desc Faixa anterior
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd("noctalia msg media stop"),      { locked = true })
-- @desc Parar reprodução
hl.bind("CTRL + " .. mod .. " + Space", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
-- @desc Play/Pausar
hl.bind(mod .. " + ALT + N",  hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true })
-- @desc Próxima faixa
hl.bind(mod .. " + ALT + P",  hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true })
-- @desc Faixa anterior


-- ═══ Screenshots ═══════════════════════════════════════════════════════════

hl.bind("Print",                   hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
-- @desc Silenciar microfone
hl.bind(mod .. " + Print",         hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
-- @desc Captura de tela fullscreen
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
-- @desc Captura de tela região
hl.bind("ALT + Print",             hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"))
-- @desc Captura de tela com seletor


-- ═══ Scripts ════════════════════════════════════════════════════════════════

hl.bind("ALT + F4",            hl.dsp.exec_cmd(scripts_dir .. "/AltF4.lua"))
-- @desc Executar AltF4.lua
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(scripts_dir .. "/WindowInfo.lua"))
-- @desc Executar WindowInfo.lua


-- ═══ Mouse ════════════════════════════════════════════════════════════

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
-- @desc Arrastar janela
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- @desc Redimensionar janela
hl.bind(mod .. " + S",      hl.dsp.exec_cmd("pypr toggle steam"))
-- @desc Toggle Steam
