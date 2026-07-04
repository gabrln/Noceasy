-- =========================================================================
-- Hyprland Environment Variables (Lua Module)
-- =========================================================================

-- Wayland core & backend flags
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Qt scaling & theming
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "Fusion")
hl.env("QT_QUICK_CONTROLS_STYLE", "Basic")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("GDK_SCALE", "1")

-- Browser & Electron acceleration
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Fix for missing XDG_DATA_DIRS mime-info database
local current_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
if not current_data_dirs:find("/usr/share") then
    local new_data_dirs = "/usr/local/share:/usr/share"
    if current_data_dirs ~= "" then
        new_data_dirs = new_data_dirs .. ":" .. current_data_dirs
    end
    hl.env("XDG_DATA_DIRS", new_data_dirs)
end
