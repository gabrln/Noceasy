-- =========================================================================
-- Hyprland keybindings (Lua module)
-- =========================================================================

local mod = "SUPER"
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts_dir = config_home .. "/hypr/scripts"


-- 1. Apps

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"),              { description = "Abrir terminal kitty" })
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"),            { description = "Abrir navegador Firefox" })
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("kitty -e yazi"),      { description = "Abrir gerenciador de arquivos yazi" })
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("thunar"),          { description = "Abrir thunar" })
hl.bind(mod .. " + A",      hl.dsp.exec_cmd("kitty -e herdr"),     { description = "Abrir herdr" })


-- 2. Windows

hl.bind(mod .. " + Q",            hl.dsp.window.close(),                                                { description = "Fechar janela" })
hl.bind(mod .. " + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 1280, y = 720 }))
    hl.dispatch(hl.dsp.window.center())
end,                                                                                                     { description = "Toggle floating/centralizar" })
hl.bind(mod .. " + ALT + Space",  hl.dsp.window.pin({ action = "toggle" }),                             { description = "Toggle pinned" })
hl.bind(mod .. " + C",            hl.dsp.window.center(),                                               { description = "Centralizar janela" })

-- Grupos e redimensionamento
hl.bind(mod .. " + R",         hl.dsp.layout("colresize +conf"),                                        { description = "Ciclar largura da coluna (0.5 → 0.8 → 1.0)" })
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"),                                       { description = "Recarregar config Hyprland" })
hl.bind(mod .. " + G",         hl.dsp.group.toggle(),                                                   { description = "Toggle grupo" })
hl.bind(mod .. " + ALT + H",   hl.dsp.group.prev(),                                                     { description = "Grupo anterior" })
hl.bind(mod .. " + ALT + L",   hl.dsp.group.next(),                                                     { description = "Próximo grupo" })

hl.bind(mod .. " + H", hl.dsp.layout("focus l"),                                                        { description = "Focar janela à esquerda" })
hl.bind(mod .. " + L", hl.dsp.layout("focus r"),                                                        { description = "Focar janela à direita" })
hl.bind(mod .. " + J", hl.dsp.focus({ workspace = "e+1" }),                                             { description = "Próximo workspace" })
hl.bind(mod .. " + K", hl.dsp.focus({ workspace = "e-1" }),                                             { description = "Workspace anterior" })

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }),                              { description = "Mover janela à esquerda" })
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }),                             { description = "Mover janela à direita" })
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ workspace = "e+1" }),                               { description = "Mover janela próximo workspace" })
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ workspace = "e-1" }),                               { description = "Mover janela workspace anterior" })


-- 3. Layout

hl.bind(mod .. " + M",               hl.dsp.layout("fit active"),                                       { description = "Ajustar janela ativa" })
hl.bind(mod .. " + comma",           hl.dsp.layout("-col"),                                              { description = "Diminuir colunas" })
hl.bind(mod .. " + period",          hl.dsp.layout("+col"),                                              { description = "Aumentar colunas" })
hl.bind(mod .. " + SHIFT + comma",   hl.dsp.layout("swapprev"),                                          { description = "Trocar janela anterior" })
hl.bind(mod .. " + SHIFT + period",  hl.dsp.layout("swapnext"),                                          { description = "Trocar próxima janela" })


-- 4. Workspaces

for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }),         { description = "Workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }),    { description = "Mover janela para workspace " .. i })
end
hl.bind(mod .. " + X",             hl.dsp.exec_cmd("pypr expose"),                                      { description = "Mostrar todas as janelas (expose)" })
hl.bind(mod .. " + 0",         hl.dsp.focus({ workspace = 10 }),                                        { description = "Workspace 10" })
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }),                                  { description = "Mover janela para workspace 10" })



-- 5. Scratchpads

hl.bind(mod .. " + T",            hl.dsp.exec_cmd("pypr toggle terminal"),      { description = "Toggle terminal dropdown" })
hl.bind(mod .. " + F1",     hl.dsp.exec_cmd("pypr toggle btop"),                { description = "Toggle btop" })
hl.bind(mod .. " + Slash",  hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"), { description = "Abrir cheatsheet de teclas" })
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd("pypr toggle spotify"),          { description = "Toggle Spotify" })
hl.bind(mod .. " + S",      hl.dsp.exec_cmd("pypr toggle steam"),               { description = "Toggle Steam" })


-- 6. Noctalia

hl.bind(mod .. " + D",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"),                    { description = "Abrir launcher" })
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"),                   { description = "Abrir clipboard" })
hl.bind(mod .. " + O",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"), { description = "Abrir notificações" })
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("noctalia msg panel-toggle noctalia/notes:panel"),         { description = "Toggle notas" })
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"),                     { description = "Abrir menu de sessão (lock, logout, etc)" })
hl.bind(mod .. " + I",         hl.dsp.exec_cmd("noctalia msg settings-toggle"),                          { description = "Abrir configurações do Noctalia" })

-- Nightlight
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg nightlight-toggle"),                        { description = "Toggle nightlight" })

-- Caffeine (inibidor de idle)
hl.bind(mod .. " + SHIFT + Y", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"),                          { description = "Toggle caffeine" })

-- Wallpaper e tema
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("noctalia msg wallpaper-random"),                         { description = "Wallpaper aleatório" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"),                                  { description = "Bloquear tela" })
hl.bind("ALT + Tab", hl.dsp.exec_cmd("noctalia msg window-switcher"),                                    { description = "Alternar entre janelas (window switcher)" })




-- 7. Media

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),   { locked = true, repeating = true, description = "Aumentar volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true, description = "Diminuir volume" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, description = "Silenciar volume" })

-- Microfone
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, description = "Silenciar microfone" })
hl.bind(mod .. " + SHIFT + M",  hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, description = "Silenciar microfone" })

-- Brilho
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true, repeating = true, description = "Aumentar brilho" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true, description = "Diminuir brilho" })

-- Reprodução de mídia
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true, description = "Play/Pausar" })
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true, description = "Play/Pausar" })
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true, description = "Play/Pausar" })
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true, description = "Próxima faixa" })
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true, description = "Faixa anterior" })
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd("noctalia msg media stop"),      { locked = true, description = "Parar reprodução" })
hl.bind("CTRL + " .. mod .. " + Space", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true, description = "Play/Pausar" })
hl.bind(mod .. " + ALT + N",  hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true, description = "Próxima faixa" })
hl.bind(mod .. " + ALT + P",  hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true, description = "Faixa anterior" })


-- 8. Screenshots

hl.bind(mod .. " + Print",         hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"),           { description = "Captura de tela fullscreen" })
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"),               { description = "Captura de tela região" })
hl.bind("ALT + Print",             hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"),      { description = "Captura de tela com seletor" })


-- 9. Scripts

hl.bind("ALT + F4",            hl.dsp.exec_cmd(scripts_dir .. "/AltF4.lua"),                        { description = "Executar AltF4.lua" })
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(scripts_dir .. "/WindowInfo.lua"),                   { description = "Executar WindowInfo.lua" })


-- 10. Mouse

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Arrastar janela" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Redimensionar janela" })
