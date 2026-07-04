-- =========================================================================
-- Hyprland Window & Layer Rules (Lua Module)
-- =========================================================================

-- Scratchpads (special workspaces) – size, position, focus, and workspace assignment
hl.window_rule({ match = { class = "kitty-drop" },       float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:kitty-drop" })
hl.window_rule({ match = { class = "btop-scratch" },     float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:btop-scratch" })
hl.window_rule({ match = { class = "keyhints-scratch" }, float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:keyhints-scratch" })

-- Window rules for Noctalia settings panel (1400x800 centered floating dialog)
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia.Settings" },
    float = true,
    size = "1400 800",
    center = true,
})

-- General window rules (maximize common apps)
hl.window_rule({ match = { class = "firefox" },       maximize = true })
hl.window_rule({ match = { class = "google-chrome" }, maximize = true })
hl.window_rule({ match = { class = "code" },          maximize = true })
hl.window_rule({ match = { class = "obsidian" },      maximize = true })

-- Idle inhibit rules (prevent screen lock during full-screen video/media playing, inspired by minimaLinux)
hl.window_rule({ match = { class = ".*(celluloid|mpv|vlc|spotify|LibreWolf|floorp|brave-browser|firefox|chromium|zen|vivaldi).*" }, idle_inhibit = "fullscreen" })

-- Floating dialogs & utilities
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

-- Layer rules: blur on Noctalia overlays and notification layers
hl.layer_rule({ match = { namespace = "notifications" },              blur = true })
hl.layer_rule({ match = { namespace = "logout_dialog" },              blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
