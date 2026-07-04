-- =========================================================================
-- Hyprland Autostart & Services (Lua Module)
-- =========================================================================

hl.on("hyprland.start", function()
    -- Authentication & Keyring services (inspired by minimaLinux)
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    -- Desktop shell and system utilities
    hl.exec_cmd("noctalia")
    hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)
