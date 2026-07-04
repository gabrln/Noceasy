-- =========================================================================
-- Hyprland Configuration (v0.55+)
-- =========================================================================

-- Monitor settings
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Persistent workspaces
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        persistent = true,
    })
end

-- Core options
hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 5,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border = "rgba(cba6f7ff)",
            inactive_border = "rgba(646789ff)",
        },
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        direction = "right",
    },
    decoration = {
        rounding = 5,
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            vibrancy = 0.1696,
        },
    },
    input = {
        kb_layout = "br",
        numlock_by_default = true,
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = -0.4,
        repeat_rate  = 50,   -- key repeat rate (default ~25/s)
        repeat_delay = 300,  -- delay before repeat starts (default ~600ms)
        touchpad = {
            tap_to_click = true,
            disable_while_typing = true,
            natural_scroll = true,
            drag_lock = false,
        },
    },
    cursor = {
        -- Hide cursor after 3 seconds of inactivity or while typing
        inactive_timeout = 3,
        hide_on_key_press = true,
        sync_gsettings_theme = true,
        warp_on_change_workspace = 2,
    },
    misc = {
        disable_hyprland_logo      = true,
        focus_on_activate          = true,
        middle_click_paste         = false,  -- disable accidental middle-click paste
        allow_session_lock_restore = true,   -- prevent lockscreen crash on resume from suspend
        enable_anr_dialog          = true,   -- show dialog when app is not responding
        anr_missed_pings           = 15,     -- higher threshold (default 1 is too aggressive)
        on_focus_under_fullscreen  = 1,      -- new window takes focus over fullscreen
    },
    binds = {
        workspace_back_and_forth = true,  -- SUPER+N twice returns to previous workspace
        allow_workspace_cycles   = true,  -- workspace 10 -> next wraps to workspace 1
    },
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,  -- prevent pixelated X11 apps on HiDPI
    },
})

-- Animations (using correct hl.curve/hl.animation API for v0.55+)
hl.config({ animations = { enabled = true } })

-- Minimalist bezier curves
hl.curve("wind",   { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.00 } } })
hl.curve("winIn",  { type = "bezier", points = { { 0.1,  1.0 }, { 0.1, 1.00 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3,  0.0 }, { 0,   1.0  } } })
hl.curve("liner",  { type = "bezier", points = { { 1,    1   }, { 1,   1    } } })

-- Window animations
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5,  bezier = "winIn",  style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3,  bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
hl.animation({ leaf = "border",           enabled = true, speed = 1,  bezier = "liner" })
hl.animation({ leaf = "fade",             enabled = true, speed = 5,  bezier = "wind" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
-- Scratchpads: subtle vertical slide-fade
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,  bezier = "wind",   style = "slidefadevert 15%" })
-- Layer animations (bars, overlays, panels)
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3,  bezier = "winIn",  style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2,  bezier = "winOut" })

-- Scratchpads (special workspaces) – tamanho, posição e foco
hl.window_rule({ match = { class = "kitty-drop" },     float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:kitty-drop" })
hl.window_rule({ match = { class = "btop-scratch" },   float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:btop-scratch" })
hl.window_rule({ match = { class = "keyhints-scratch" }, float = true, size = "1600 900", center = true, stay_focused = true, workspace = "special:keyhints-scratch" })

-- Window rules for Noctalia settings panel
-- Force a larger size in absolute pixels (1920x1080 monitor: ~90% = 1728x972)
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia.Settings" },
    float = true,
    size = "1400 800",
    center = true,
})

-- General window rules (CSD, floating dialogs, browser maximize)
hl.window_rule({
    match = { class = "firefox" },
    maximize = true,
})
hl.window_rule({
    match = { class = "google-chrome" },
    maximize = true,
})
hl.window_rule({
    match = { class = "code" },
    maximize = true,
})
hl.window_rule({
    match = { class = "obsidian" },
    maximize = true,
})

-- Floating dialogs
hl.window_rule({
    match = { title = ".*(Open|Save|Select).*" },
    float = true,
})
hl.window_rule({
    match = { title = ".*File.*" },
    float = true,
})
hl.window_rule({
    match = { class = "org.gtk.FileChooserDialog" },
    float = true,
})
hl.window_rule({
    match = { title = ".*(Dialog|Properties|Preferences|Settings|Rename|Authentication).*" },
    float = true,
})
hl.window_rule({
    match = { class = "zenity" },
    float = true,
})
hl.window_rule({
    match = { class = "pavucontrol" },
    float = true,
})

-- Firefox Picture-in-Picture: pinned, semi-transparent, 30% of screen
hl.window_rule({
    match            = { class = "firefox", title = "^Picture-in-Picture$" },
    float            = true,
    pin              = true,
    keep_aspect_ratio = true,
    size             = "(monitor_w*0.3) (monitor_h*0.3)",
    move             = "72% 7%",
    opacity          = "0.95 0.75",
})

-- Layer rules: blur on Noctalia overlays and notification layers
hl.layer_rule({ match = { namespace = "notifications" },               blur = true })
hl.layer_rule({ match = { namespace = "logout_dialog" },               blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" },  blur = true })

-- Helper function to toggle scratchpad, spawning if not running
local function toggle_scratchpad(name, cmd)
    local windows = hl.get_windows({ class = name })
    if #windows == 0 then
        hl.exec_cmd(cmd)
        hl.exec_cmd("sleep 0.3")
    end
    hl.exec_cmd("hyprctl dispatch togglespecialworkspace " .. name)
    hl.exec_cmd("sleep 0.05")
    hl.exec_cmd("hyprctl dispatch focuswindow class:" .. name)
end

-- Keybindings
local mod = "SUPER"

-- Core operations
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("/home/gabrln/.config/hypr/scripts/WindowInfo.lua"))
hl.bind("ALT + F4", hl.dsp.exec_cmd("/home/gabrln/.config/hypr/scripts/AltF4.lua"))

-- Noctalia controls
hl.bind(mod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("noctalia msg nightlight-toggle"))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("noctalia msg wallpaper-random"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("noctalia msg theme-mode-toggle"))

-- Sessions & System
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Focus movement (Vim keys)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move windows (Vim keys)
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Window sizing and presentation (fitting / centering)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + M", hl.dsp.layout("fit active"))
hl.bind(mod .. " + C", hl.dsp.window.center())
hl.bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + R", hl.dsp.layout("colresize"))

-- Window resizing (Ctrl+Alt + arrows)
hl.bind("CTRL + ALT + Left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("CTRL + ALT + Right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind("CTRL + ALT + Up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind("CTRL + ALT + Down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Scrolling layout specific binds
hl.bind(mod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))

-- Workspaces switching and window moving (1 to 10)
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Tab based workspace switching
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Overview mode toggle
hl.bind("ALT + Tab", hl.dsp.exec_raw("toggleoverview", ""))

-- Mouse wheel workspace switching
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "e-1" }))

-- Mouse drag window controls
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Scratchpads (Toggle Special Workspaces with dynamic spawning)
hl.bind(mod .. " + SHIFT + Return", function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end)
hl.bind(mod .. " + F1", function() toggle_scratchpad("btop-scratch", "kitty --class btop-scratch -e btop") end)
hl.bind(mod .. " + Slash", function() toggle_scratchpad("keyhints-scratch", "kitty --class keyhints-scratch -e /home/gabrln/.config/hypr/scripts/KeyHints.lua") end)

-- Hardware, media, volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("noctalia msg media stop"), { locked = true })

-- Music alternatives
hl.bind("CTRL + " .. mod .. " + Space", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind(mod .. " + ALT + N", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind(mod .. " + ALT + P", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })

-- Screenshot controls
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"))

-- Autostart
hl.on("hyprland.start", function()
    -- Start shell and system utilities
    hl.exec_cmd("noctalia")
    hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)

-- For Noctalia Color templates
require("noctalia").apply_theme()
