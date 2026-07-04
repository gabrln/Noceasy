-- =========================================================================
-- Hyprland Lua Configuration (v0.55+)
-- Custom Scrolling Layout Setup matching Niri workflows
-- =========================================================================

hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
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
        follow_mouse = 1,
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
    size = "1600 900"
})

hl.window_rule({
    match = { class = "keyhints-scratch" },
    workspace = "special:keyhints-scratch",
    float = true,
    size = "1200 800"
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
    match = { title = "Picture-in-Picture" },
    float = true
})
hl.window_rule({
    match = { title = "Open File" },
    float = true
})
hl.window_rule({
    match = { title = "Save File" },
    float = true
})

-- Keybindings
local mod = "SUPER"

-- Core operations
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())

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

-- Scrolling layout specific binds
hl.bind(mod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))

-- Workspaces switching and window moving (1 to 9)
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpads (Toggle Special Workspaces)
hl.bind(mod .. " + SHIFT + Return", hl.dsp.workspace.toggle_special("kitty-drop"))
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("btop-scratch"))
hl.bind(mod .. " + Slash", hl.dsp.workspace.toggle_special("keyhints-scratch"))

-- Media and controls mapped through Noctalia / system tools
hl.bind(mod .. " + F2", hl.dsp.exec_cmd("noctalia msg mic-mute"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))

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
