-- =========================================================================
-- Hyprland window and layer rules (Lua module)
-- =========================================================================

-- Scratchpads (special workspaces) – size, position, and focus
hl.window_rule({ match = { class = "kitty-drop" },       float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:kitty-drop" })
hl.window_rule({ match = { class = "btop-scratch" },     float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:btop-scratch" })
hl.window_rule({ match = { class = "keyhints-scratch" }, float = true, size = "900 900", center = true, stay_focused = true, workspace = "special:keyhints-scratch" })

-- Noctalia settings panel (floating, centred)
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
    center = true,
})

-- General rules: maximise main applications
hl.window_rule({ match = { class = "firefox" },       maximize = true })
hl.window_rule({ match = { class = "google-chrome" }, maximize = true })
hl.window_rule({ match = { class = "code" },          maximize = true })
hl.window_rule({ match = { class = "obsidian" },      maximize = true })

-- Inhibit screen idle (screensaver / suspend) while media is playing or a
-- game is running fullscreen.
hl.window_rule({
    match = { class = ".*(celluloid|^mpv$|vlc|spotify|librewolf|floorp|brave-browser|firefox|chromium|zen-browser|vivaldi|steam_app_.*|gamescope|lutris|heroic|dota2|cs2|wine.*).*" },
    idle_inhibit = "fullscreen",
})

-- Floating dialogs and utilities
hl.window_rule({ match = { title = ".*(Open|Save|Select|File|Dialog|Properties|Preferences|Settings|Rename|Authentication).*" }, float = true })
hl.window_rule({ match = { class = "org.gtk.FileChooserDialog" }, float = true })
hl.window_rule({ match = { class = "zenity" },                    float = true })
hl.window_rule({ match = { class = "pavucontrol" },               float = true })

-- Firefox Picture-in-Picture: pinned, semi-transparent, 30% of screen
hl.window_rule({
    match             = { class = "firefox", title = "^Picture-in-Picture$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "(monitor_w*0.3) (monitor_h*0.3)",
    move              = "72% 7%",
    opacity           = "0.95 0.75",
})

-- Layer rules: blur and no-anim for noctalia panels and OSD
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
