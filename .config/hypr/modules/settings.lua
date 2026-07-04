-- =========================================================================
-- Hyprland Core Settings & Layout (Lua Module)
-- =========================================================================

hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 5,
        gaps_out = 5,
        border_size = 1,
        resize_on_border = true,
        col = {
            active_border = "rgba(cba6f7ff)",
            inactive_border = "rgba(646789ff)",
        },
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        direction = "right",
        follow_focus = true,
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
        repeat_rate  = 50,
        repeat_delay = 300,
        touchpad = {
            tap_to_click = true,
            disable_while_typing = true,
            natural_scroll = true,
            drag_lock = false,
        },
    },
    cursor = {
        inactive_timeout = 3,
        hide_on_key_press = true,
        sync_gsettings_theme = true,
        warp_on_change_workspace = 2,
    },
    misc = {
        disable_hyprland_logo      = true,
        focus_on_activate          = true,
        middle_click_paste         = false,
        allow_session_lock_restore = true,
        enable_anr_dialog          = true,
        anr_missed_pings           = 15,
        on_focus_under_fullscreen  = 1,
    },
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
    },
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },
})
