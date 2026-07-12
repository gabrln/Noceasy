-- =========================================================================
-- Hyprland environment variables (Lua module)
-- =========================================================================

-- Core Wayland parameters
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Qt / GTK themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Hardware acceleration for browsers and Electron
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Intel video acceleration (VAAPI/VDPAU)
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl")

-- Java AWT compatibility (fix gray screens in Minecraft, etc.)
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Cursor and default tools (previously in .config/uwsm/env)
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("EDITOR", "nvim")
hl.env("TERMINAL", "kitty")

-- Ensure ~/.local/bin is in PATH (for uv/pip user-installed tools like pyprland)
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin")

-- Ensure /usr/share is in XDG_DATA_DIRS for mime-info
local current_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
if not current_data_dirs:find("/usr/share") then
    local new_data_dirs = "/usr/local/share:/usr/share"
    if current_data_dirs ~= "" then
        new_data_dirs = new_data_dirs .. ":" .. current_data_dirs
    end
    hl.env("XDG_DATA_DIRS", new_data_dirs)
end
