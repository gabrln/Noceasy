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
        touchpad = {
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
    misc = {
        disable_hyprland_logo = true,
    }
})

-- Window rules for Scratchpads (Special Workspaces)
hl.window_rule({
    match = { class = "kitty-drop" },
    workspace = "special:kitty-drop",
    float = true,
    size = "1600 900"
})

hl.window_rule({
    match = { class = "btop-scratch" },
    workspace = "special:btop-scratch",
    float = true,
    size = "1400 800"
})

hl.window_rule({
    match = { class = "keyhints-scratch" },
    workspace = "special:keyhints-scratch",
    float = true,
    size = "1280 720"
})

-- Window rules for Noctalia settings panel
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia.Settings" },
    float = true,
    size = "1080 920"
})

-- General window rules (CSD, floating dialogs, browser maximize)
hl.window_rule({
    match = { class = "firefox" },
    maximize = true
})
hl.window_rule({
    match = { class = "google-chrome" },
    maximize = true
})
hl.window_rule({
    match = { class = "code" },
    maximize = true
})
hl.window_rule({
    match = { class = "obsidian" },
    maximize = true
})

-- Floating dialogs
hl.window_rule({
    match = { title = ".*(Open|Save|Select).*" },
    float = true
})
hl.window_rule({
    match = { title = ".*File.*" },
    float = true
})
hl.window_rule({
    match = { class = "org.gtk.FileChooserDialog" },
    float = true
})
hl.window_rule({
    match = { title = ".*(Dialog|Properties|Preferences|Settings|Rename|Authentication).*" },
    float = true
})
hl.window_rule({
    match = { class = "zenity" },
    float = true
})
hl.window_rule({
    match = { class = "pavucontrol" },
    float = true
})

-- Firefox Picture-in-Picture float
hl.window_rule({
    match = { class = "firefox", title = "^Picture-in-Picture$" },
    float = true
})

-- Keybindings
local mod = "SUPER"

-- Core operations
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("/home/gabrln/.config/niri/scripts/WindowInfo.sh"))
hl.bind("ALT + F4", hl.dsp.exec_cmd("/home/gabrln/.config/niri/scripts/AltF4.sh"))

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
hl.bind("ALT + Tab", function() hl.dispatch("toggleoverview", "") end)

-- Mouse wheel workspace switching
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "e-1" }))

-- Scratchpads (Toggle Special Workspaces)
hl.bind(mod .. " + SHIFT + Return", hl.dsp.workspace.toggle_special("kitty-drop"))
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("btop-scratch"))
hl.bind(mod .. " + Slash", hl.dsp.workspace.toggle_special("keyhints-scratch"))

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

    -- Pre-spawn scratchpad processes inside their special workspaces
    hl.exec_cmd("kitty --class kitty-drop")
    hl.exec_cmd("kitty --class btop-scratch -e btop")
    hl.exec_cmd("kitty --class keyhints-scratch -e /home/gabrln/.config/niri/scripts/KeyHints.sh")
end)
