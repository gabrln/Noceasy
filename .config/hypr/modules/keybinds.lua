-- =========================================================================
-- Hyprland keybindings (Lua module)
-- =========================================================================

local mod = "SUPER"
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts_dir = config_home .. "/hypr/scripts"


-- ── Helpers ───────────────────────────────────────────────────────────

local function toggle_scratchpad(name, cmd)
    local windows = hl.get_windows({ class = name })
    if #windows == 0 then
        hl.exec_cmd(cmd)
    end
    hl.dispatch(hl.dsp.workspace.toggle_special(name))
end


-- ═══ Apps ════════════════════════════════════════════════════════════════

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("thunar"))


-- ═══ Windows ═════════════════════════════════════════════════════════════

hl.bind(mod .. " + Q",            hl.dsp.window.close())
hl.bind(mod .. " + F",            hl.dsp.window.fullscreen())
hl.bind(mod .. " + Space",        hl.dsp.window.float({ action = "toggle" }))
-- @desc Toggle floating
hl.bind(mod .. " + ALT + Space",  hl.dsp.window.pin({ action = "toggle" }))
-- @desc Toggle pinned
hl.bind(mod .. " + C",            hl.dsp.window.center())

-- Redimensionar janela por pixels (Ctrl + Alt + Setas)
hl.bind("CTRL + ALT + Left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("CTRL + ALT + Right", hl.dsp.window.resize({ x = 100,  y = 0, relative = true }))
hl.bind("CTRL + ALT + Up",    hl.dsp.window.resize({ x = 0,  y = -100, relative = true }))
hl.bind("CTRL + ALT + Down",  hl.dsp.window.resize({ x = 0,  y = 100, relative = true }))

-- Grupos e redimensionamento
hl.bind(mod .. " + R",         hl.dsp.layout("colresize +0.1"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + G",         hl.dsp.group.toggle())
hl.bind(mod .. " + ALT + H",   hl.dsp.group.prev())
hl.bind(mod .. " + ALT + L",   hl.dsp.group.next())


-- ═══ Focus ═════════════════════════════════════════════════════════════════
-- @group Windows

hl.bind(mod .. " + H", hl.dsp.layout("focus l"))
hl.bind(mod .. " + L", hl.dsp.layout("focus r"))
hl.bind(mod .. " + J", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + K", hl.dsp.focus({ workspace = "e-1" }))


-- ═══ Movement ══════════════════════════════════════════════════════════════
-- @group Windows

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ workspace = "e-1" }))


-- ═══ Layout ════════════════════════════════════════════════════════════════

hl.bind(mod .. " + M",               hl.dsp.layout("fit active"))
hl.bind(mod .. " + comma",           hl.dsp.layout("-col"))
hl.bind(mod .. " + period",          hl.dsp.layout("+col"))
hl.bind(mod .. " + SHIFT + comma",   hl.dsp.layout("swapprev"))
hl.bind(mod .. " + SHIFT + period",  hl.dsp.layout("swapnext"))


-- ═══ Workspaces ═══════════════════════════════════════════════════════

for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mod .. " + mouse_down",         hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse_up",           hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e+1" }))


-- ═══ Scratchpads ══════════════════════════════════════════════════════

hl.bind(mod .. " + T",            function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end)
hl.bind(mod .. " + SHIFT + Return", function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end)
hl.bind(mod .. " + F1",     function() toggle_scratchpad("btop-scratch", "kitty --class btop-scratch -e btop") end)
hl.bind(mod .. " + Slash",  function() toggle_scratchpad("keyhints-scratch", "kitty --class keyhints-scratch -e ~/.config/hypr/scripts/KeyHints_runner.lua") end)


-- ═══ Noctalia Panels ═══════════════════════════════════════════════════════
-- @group Noctalia

hl.bind(mod .. " + D",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + P",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))


-- ═══ Noctalia Features ═════════════════════════════════════════════════════
-- @group Noctalia

-- Nightlight
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg nightlight-toggle"))

-- Caffeine (inibidor de idle)
hl.bind(mod .. " + SHIFT + Y", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))

-- Wallpaper e tema
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("noctalia msg wallpaper-random"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg theme-mode-toggle"))


-- ═══ Session ════════════════════════════════════════════════════════════════

hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))


-- ═══ Media ══════════════════════════════════════════════════════════════════

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })

-- Microfone
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
hl.bind(mod .. " + SHIFT + M",  hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })

-- Brilho
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })

-- Reprodução de mídia
hl.bind("XF86AudioPlay",      hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86AudioPause",     hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd("noctalia msg media toggle"),    { locked = true })
hl.bind("XF86AudioNext",      hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true })
hl.bind("XF86AudioPrev",      hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true })
hl.bind("XF86AudioStop",      hl.dsp.exec_cmd("noctalia msg media stop"),      { locked = true })
hl.bind("CTRL + " .. mod .. " + Space", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind(mod .. " + ALT + N",  hl.dsp.exec_cmd("noctalia msg media next"),      { locked = true })
hl.bind(mod .. " + ALT + P",  hl.dsp.exec_cmd("noctalia msg media previous"),  { locked = true })


-- ═══ Screenshots ═══════════════════════════════════════════════════════════

hl.bind("Print",                   hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + Print",         hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("ALT + Print",             hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"))


-- ═══ Scripts ════════════════════════════════════════════════════════════════

hl.bind("ALT + F4",            hl.dsp.exec_cmd(scripts_dir .. "/AltF4.lua"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(scripts_dir .. "/WindowInfo.lua"))


-- ═══ Mouse ════════════════════════════════════════════════════════════

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
