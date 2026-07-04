-- =========================================================================
-- Hyprland Keybindings & Shortcuts (Lua Module)
-- =========================================================================

local mod = "SUPER"

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

-- Core applications & tools
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("/home/gabrln/.config/hypr/scripts/WindowInfo.lua"))

-- Window closing & system management (SUPER+SHIFT+Q unbound/released as requested)
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind("ALT + F4",            hl.dsp.exec_cmd("/home/gabrln/.config/hypr/scripts/AltF4.lua"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind("CTRL + ALT + L",      hl.dsp.exec_cmd("noctalia msg session lock"))

-- Noctalia shell controls
hl.bind(mod .. " + D",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + P",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mod .. " + I",         hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("noctalia msg nightlight-toggle"))
hl.bind(mod .. " + Y",         hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("noctalia msg wallpaper-random"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("noctalia msg theme-mode-toggle"))

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

-- Window sizing & presentation
hl.bind(mod .. " + F",     hl.dsp.window.fullscreen())
hl.bind(mod .. " + M",     hl.dsp.layout("fit active"))
hl.bind(mod .. " + C",     hl.dsp.window.center())
hl.bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + R",     hl.dsp.layout("colresize"))

-- Window resizing (Ctrl + Alt + Arrows)
hl.bind("CTRL + ALT + Left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("CTRL + ALT + Right", hl.dsp.window.resize({ x = 100,  y = 0, relative = true }))
hl.bind("CTRL + ALT + Up",    hl.dsp.window.resize({ x = 0,  y = -100, relative = true }))
hl.bind("CTRL + ALT + Down",  hl.dsp.window.resize({ x = 0,  y = 100, relative = true }))

-- Scrolling layout operations
hl.bind(mod .. " + period",         hl.dsp.layout("move +col"))
hl.bind(mod .. " + comma",          hl.dsp.layout("move -col"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + comma",  hl.dsp.layout("swapcol l"))

-- Workspaces switching and window moving (1 to 10)
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Tab / mouse wheel workspace switching & overview
hl.bind(mod .. " + Tab",               hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + Tab",       hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT + Tab",                   hl.dsp.exec_raw("toggleoverview", ""))
hl.bind(mod .. " + mouse_down",        hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",          hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e-1" }))

-- Mouse drag window controls
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Scratchpads (Special Workspaces)
hl.bind(mod .. " + SHIFT + Return", function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end)
hl.bind(mod .. " + F1",             function() toggle_scratchpad("btop-scratch", "kitty --class btop-scratch -e btop") end)
hl.bind(mod .. " + Slash",          function() toggle_scratchpad("keyhints-scratch", "kitty --class keyhints-scratch -e /home/gabrln/.config/hypr/scripts/KeyHints.lua") end)

-- Hardware, media & volume keys
hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("noctalia msg volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",        hl.dsp.exec_cmd("noctalia msg mic-mute"),    { locked = true })
hl.bind(mod .. " + SHIFT + M",     hl.dsp.exec_cmd("noctalia msg mic-mute"),    { locked = true })
hl.bind("XF86MonBrightnessUp",     hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",   hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",           hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86AudioPause",          hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86MediaPlayPause",      hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86AudioNext",           hl.dsp.exec_cmd("noctalia msg media next"),        { locked = true })
hl.bind("XF86AudioPrev",           hl.dsp.exec_cmd("noctalia msg media previous"),    { locked = true })
hl.bind("XF86AudioStop",           hl.dsp.exec_cmd("noctalia msg media stop"),        { locked = true })
hl.bind("CTRL + " .. mod .. " + Space", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind(mod .. " + ALT + N",       hl.dsp.exec_cmd("noctalia msg media next"),        { locked = true })
hl.bind(mod .. " + ALT + P",       hl.dsp.exec_cmd("noctalia msg media previous"),    { locked = true })

-- Screenshots
hl.bind("Print",               hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + Print",       hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("ALT + Print",         hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"))
