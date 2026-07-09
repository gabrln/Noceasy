-- =========================================================================
-- Hyprland keybindings (Lua module)
-- =========================================================================

local mod = "SUPER"


-- Helper: toggle a scratchpad, opening it if it isn't already shown.
local function toggle_scratchpad(name, cmd)
    local windows = hl.get_windows({ class = name })
    if #windows == 0 then
        hl.exec_cmd(cmd)
    end
    hl.dispatch(hl.dsp.workspace.toggle_special(name))
end

-- Main applications and tools
hl.bind(mod .. " + T",      hl.dsp.exec_cmd("kitty")) -- Default terminal
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty")) -- Fallback shortcut for terminal
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/WindowInfo.lua"))

-- Close windows and session management.
-- Session exit goes through the Noctalia session menu (Super+Shift+P)
-- to avoid an accidental direct exit via Ctrl+Alt+Del.
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind("ALT + F4",            hl.dsp.exec_cmd("~/.config/hypr/scripts/AltF4.lua"))
hl.bind("CTRL + ALT + L",      hl.dsp.exec_cmd("noctalia msg session lock"))

-- Noctalia interface controls
hl.bind(mod .. " + D",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mod .. " + P",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
hl.bind(mod .. " + I",         hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("noctalia msg nightlight-toggle"))
hl.bind(mod .. " + Y",         hl.dsp.exec_cmd("noctalia msg caffeine-toggle"))
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("noctalia msg wallpaper-random"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg theme-mode-toggle")) -- Light/Dark theme toggle

-- Focus navigation (Vim keys — H/L sideways, K/J for workspaces)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + J", hl.dsp.focus({ workspace = "e+1" }))

-- Move windows (Vim keys — H/L sideways, K/J for workspaces)
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ workspace = "e+1" }))

-- Resize, presentation, and window groups
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mod .. " + M",         hl.dsp.layout("fit active")) -- Fit the active column to the screen (scrolling layout "maximize")
hl.bind(mod .. " + C",         hl.dsp.window.center())
hl.bind(mod .. " + Space",     hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + ALT + Space", hl.dsp.window.pin({ action = "toggle" })) -- Pin floating window across all workspaces
hl.bind(mod .. " + R",         hl.dsp.layout("colresize +conf")) -- Resize column to next predefined width
hl.bind(mod .. " + SHIFT + R", hl.dsp.layout("colresize -conf")) -- Resize column to previous predefined width
hl.bind(mod .. " + G",           hl.dsp.group.toggle()) -- Create / remove tab group
hl.bind(mod .. " + ALT + H",     hl.dsp.group.prev()) -- Previous tab in group
hl.bind(mod .. " + ALT + L",     hl.dsp.group.next()) -- Next tab in group

-- Resize window by pixels (Ctrl + Alt + Arrow Keys)
hl.bind("CTRL + ALT + Left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("CTRL + ALT + Right", hl.dsp.window.resize({ x = 100,  y = 0, relative = true }))
hl.bind("CTRL + ALT + Up",    hl.dsp.window.resize({ x = 0,  y = -100, relative = true }))
hl.bind("CTRL + ALT + Down",  hl.dsp.window.resize({ x = 0,  y = 100, relative = true }))

-- Column operations in scrolling layout
hl.bind(mod .. " + period",         hl.dsp.layout("+col"))
hl.bind(mod .. " + comma",          hl.dsp.layout("-col"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.layout("swapnext"))
hl.bind(mod .. " + SHIFT + comma",  hl.dsp.layout("swapprev"))

-- Switch workspaces and move windows (1 through 10)
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0",         hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Switch workspaces via Tab/Scroll and activate scrolloverview submap
local function open_overview()
    if hl.plugin and hl.plugin.scrolloverview then
        hl.plugin.scrolloverview.overview("on")
    else
        hl.dispatch(hl.dsp.exec_raw("overview:open"))
    end
    if hl.define_submap then
        hl.dispatch(hl.dsp.submap("scrolloverview"))
    end
end

local function close_overview()
    if hl.plugin and hl.plugin.scrolloverview then
        hl.plugin.scrolloverview.overview("off")
    else
        hl.dispatch(hl.dsp.exec_raw("overview:close"))
    end
    if hl.define_submap then
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

-- hl.bind(mod .. " + Tab", open_overview) -- Disabled: only ALT + Tab for overview
hl.bind(mod .. " + SHIFT + Tab",       hl.dsp.focus({ workspace = "e-1" }))
hl.bind("ALT + Tab",                   open_overview)
hl.bind(mod .. " + mouse_down",        hl.dsp.focus({ workspace = "e-1" }), { mouse = true })
hl.bind(mod .. " + mouse_up",          hl.dsp.focus({ workspace = "e+1" }), { mouse = true })
hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e-1" }), { mouse = true })
hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e+1" }), { mouse = true })

-- Submap for isolated navigation inside scrolloverview
if hl.define_submap then
    hl.define_submap("scrolloverview", function()
        hl.bind("left",   function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("left") end end)
        hl.bind("right",  function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("right") end end)
        hl.bind("up",     function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("up") end end)
        hl.bind("down",   function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("down") end end)
        hl.bind("h",      function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("left") end end)
        hl.bind("l",      function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("right") end end)
        hl.bind("k",      function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("up") end end)
        hl.bind("j",      function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("down") end end)

        -- Close overview with ALT + Tab or Escape; select with Return
        hl.bind("ALT + Tab", close_overview)
        hl.bind("escape", close_overview)
        hl.bind("return", function()
            if hl.plugin and hl.plugin.scrolloverview then
                hl.plugin.scrolloverview.overview("select")
            end
            if hl.define_submap then hl.dispatch(hl.dsp.submap("reset")) end
        end)

        -- Lateral navigation with mouse scroll inside overview (no SUPER needed)
        hl.bind("mouse_down", function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("right") end end, { mouse = true })
        hl.bind("mouse_up",   function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.navigate("left") end end, { mouse = true })

        hl.bind("mouse:272", function()
            if hl.plugin and hl.plugin.scrolloverview then
                hl.plugin.scrolloverview.overview("select")
                hl.plugin.scrolloverview.window("select")
                hl.plugin.scrolloverview.overview("off")
            end
            if hl.define_submap then hl.dispatch(hl.dsp.submap("reset")) end
        end, { mouse = true })
        hl.bind("mouse:274", function() if hl.plugin and hl.plugin.scrolloverview then hl.plugin.scrolloverview.window("close") end end, { mouse = true })
    end)
end

-- Move and resize windows with mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Scratchpads (special workspaces)
hl.bind(mod .. " + SHIFT + T",      function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end) -- Dropdown / scratchpad terminal
hl.bind(mod .. " + SHIFT + Return", function() toggle_scratchpad("kitty-drop", "kitty --class kitty-drop") end) -- Fallback for scratchpad terminal
hl.bind(mod .. " + F1",             function() toggle_scratchpad("btop-scratch", "kitty --class btop-scratch -e btop") end)
hl.bind(mod .. " + Slash",          function() toggle_scratchpad("keyhints-scratch", "kitty --class keyhints-scratch -e ~/.config/hypr/scripts/KeyHints.lua") end)

-- Media keys, hardware and volume
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
