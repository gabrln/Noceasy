-- =========================================================================
-- Regras de Janelas e Camadas (Módulo Lua)
-- =========================================================================

-- Scratchpads (workspaces especiais) – tamanho, posição e foco
hl.window_rule({ match = { class = "kitty-drop" },       float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:kitty-drop" })
hl.window_rule({ match = { class = "btop-scratch" },     float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:btop-scratch" })
hl.window_rule({ match = { class = "keyhints-scratch" }, float = true, size = "900 900", center = true, stay_focused = true, workspace = "special:keyhints-scratch" })

-- Painel de configurações do Noctalia (flutuante 1400x800 centralizado)
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia.Settings" },
    float = true,
    size = "1400 800",
    center = true,
})

-- Regras gerais (maximizar aplicações principais)
hl.window_rule({ match = { class = "firefox" },       maximize = true })
hl.window_rule({ match = { class = "google-chrome" }, maximize = true })
hl.window_rule({ match = { class = "code" },          maximize = true })
hl.window_rule({ match = { class = "obsidian" },      maximize = true })

-- Bloquear suspensão da tela durante reprodução de mídia ou jogos em tela cheia
hl.window_rule({ match = { class = ".*(celluloid|mpv|vlc|spotify|LibreWolf|floorp|brave-browser|firefox|chromium|zen|vivaldi|steam_app|gamescope|lutris|heroic|dota2|cs2|wine).*" }, idle_inhibit = "fullscreen" })

-- Diálogos flutuantes e utilitários
hl.window_rule({ match = { title = ".*(Open|Save|Select|File|Dialog|Properties|Preferences|Settings|Rename|Authentication).*" }, float = true })
hl.window_rule({ match = { class = "org.gtk.FileChooserDialog" }, float = true })
hl.window_rule({ match = { class = "zenity" },                    float = true })
hl.window_rule({ match = { class = "pavucontrol" },               float = true })

-- Firefox Picture-in-Picture: fixo, semi-transparente, 30% da tela
hl.window_rule({
    match             = { class = "firefox", title = "^Picture-in-Picture$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "(monitor_w*0.3) (monitor_h*0.3)",
    move              = "72% 7%",
    opacity           = "0.95 0.75",
})

-- Regras de camada: desfoque (blur) e remoção de animações conflitantes
hl.layer_rule({
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|wallpaper|background)$" },
    no_anim = true,
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
})
hl.layer_rule({ match = { namespace = "notifications" },              blur = true })
hl.layer_rule({ match = { namespace = "logout_dialog" },              blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
