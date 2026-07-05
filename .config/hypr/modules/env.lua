-- =========================================================================
-- Variáveis de Ambiente do Hyprland (Módulo Lua)
-- =========================================================================

-- Parâmetros centrais do Wayland
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Temas para Qt/GTK
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Aceleração para navegadores e Electron
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Cursor e ferramentas padrão (antes no .config/uwsm/env)
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("EDITOR", "nvim")
hl.env("TERMINAL", "kitty")

-- Correção para base de dados de mime-info no XDG_DATA_DIRS
local current_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
if not current_data_dirs:find("/usr/share") then
    local new_data_dirs = "/usr/local/share:/usr/share"
    if current_data_dirs ~= "" then
        new_data_dirs = new_data_dirs .. ":" .. current_data_dirs
    end
    hl.env("XDG_DATA_DIRS", new_data_dirs)
end
