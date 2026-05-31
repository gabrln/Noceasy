-- ============================================================
-- HYPRLAND CONFIG
-- ============================================================

require("noctalia")

-- ── Animations ───────────────────────────────────────────────

hl.curve("fade", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })

hl.animation({ leaf = "global",                enabled = false })
hl.animation({ leaf = "fadeIn",               enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeOut",              enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeSwitch",           enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeDim",              enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "workspaces",           enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "specialWorkspaceIn",   enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceOut",  enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })

-- ── General & Decoration ────────────────────────────────────

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,
    },

    decoration = {
        rounding       = 5,
        rounding_power = 2,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 2,
            vibrancy  = 0.1696,
        },
    },

    -- Layout
    dwindle = {
        preserve_split = true,
    },

    binds = {
        allow_workspace_cycles      = true,
        movefocus_cycles_fullscreen = false,
        workspace_back_and_forth    = true,
        workspace_center_on         = 1,
    },

    -- Input
    input = {
        kb_layout          = "br",
        numlock_by_default = true,
        repeat_rate        = 60,
        repeat_delay       = 300,
        follow_mouse       = 1,
        sensitivity        = -0.4,
        scroll_factor      = 2.0,
        accel_profile      = "flat",
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
        },
    },
})

-- ── Monitor ──────────────────────────────────────────────────

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = "1.0",
})

-- ── Workspace Rules ──────────────────────────────────────────

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
end

-- ── Layer Rules ──────────────────────────────────────────────

hl.layer_rule({
    name  = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel)$" },
    ignore_alpha = 0.5,
    blur         = true,
    blur_popups  = true,
})

-- ── Drop Terminal ────────────────────────────────────────────

local DROP_CLASS = "kitty-drop"
local DROP_CMD   = "kitty --app-id " .. DROP_CLASS
local drop_alive = false

hl.window_rule({
    match     = { class = DROP_CLASS },
    workspace = "special:drop",
    float     = true,
    size      = { 1600, 900 },
    move      = { 160, 90 },   -- (1920-1600)/2, (1080-900)/2
})

hl.on("window.close", function(w)
    if w.class == DROP_CLASS then
        drop_alive = false
    end
end)

-- ── Keybinds ─────────────────────────────────────────────────

local mainMod = "SUPER"
local browser = "firefox"
local ipc     = "noctalia msg"

-- Terminal
hl.bind("SUPER + return", hl.dsp.exec_raw("kitty --title Kitty"))

-- Drop terminal toggle (SUPER+T)
hl.bind("SUPER + T", function()
    if not drop_alive then
        hl.dispatch(hl.dsp.exec_cmd(DROP_CMD))
        drop_alive = true
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("drop"))
    end
end)

-- Core
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- Focus & move with arrow keys
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. dir,         hl.dsp.focus({ direction = dir }))
    hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Toggle focus between floating and tiled
hl.bind("SUPER + SHIFT + V", function()
    local active = hl.get_active_window()
    if active and active.floating then
        hl.dispatch(hl.dsp.focus({ window = "tiled" }))
    else
        hl.dispatch(hl.dsp.focus({ window = "floating" }))
    end
end)

-- Noctalia
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))
hl.bind(mainMod .. " + V",     hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))

-- Media keys
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd(ipc .. " volume-up"))
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd(ipc .. " volume-down"))
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd(ipc .. " volume-mute"))
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd(ipc .. " brightness-up"))
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd(ipc .. " brightness-down"))

-- ── Autostart ────────────────────────────────────────────────

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
end)
