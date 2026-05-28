local mainMod = "SUPER"
local terminal = "alacritty"
local browser = "firefox"
local ipc = "noctalia msg"

-- Opening a terminal
hl.bind("SUPER + return", hl.dsp.exec_raw("kitty --title Kitty"))
hl.bind("SUPER + T", hl.dsp.exec_raw("kitty --title Kitty"))

-- Session Management
hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())

-- Core binds
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { repeating = true })

for _, dir in ipairs({"left", "right", "up", "down"}) do
    hl.bind("SUPER + " .. dir, hl.dsp.focus({direction = dir}))
    hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({direction = dir}))
end

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({workspace = i}))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({workspace = i, follow = true}))
end

hl.bind("SUPER + SHIFT + V", function()
    local active = hl.get_active_window()

    if active and active.floating then
        hl.dispatch(hl.dsp.focus({ window = "tiled" }))
    else
        hl.dispatch(hl.dsp.focus({ window = "floating" }))
    end
end
)

-- Noctalia Core binds
hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. " volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. " volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. " volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. " brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"))
