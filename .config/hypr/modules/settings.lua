-- =========================================================================
-- Hyprland general settings and layout (Lua module)
-- =========================================================================

hl.config({
	general = {
		layout = "scrolling",
		gaps_in = 5,
		gaps_out = 10,
		border_size = 1,
		resize_on_border = true,
	},
	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.667,
		explicit_column_widths = "0.5,0.667,1.0",
		direction = "right",
		follow_focus = true,
		focus_fit_method = 1,
	},
	decoration = {
		rounding = 8,
		rounding_power = 2,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 3,
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
		repeat_rate = 50,
		repeat_delay = 300,
		touchpad = {
			tap_to_click = true,
			disable_while_typing = true,
			natural_scroll = true,
			drag_lock = false,
		},
	},
	cursor = {
		inactive_timeout = 2,
		hide_on_key_press = false,
		sync_gsettings_theme = true,
		warp_on_change_workspace = 2,
	},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		background_color = "rgb(11111b)",
		initial_workspace_tracking = 0,
		focus_on_activate = true,
		middle_click_paste = false,
		allow_session_lock_restore = true,
		enable_anr_dialog = true,
		anr_missed_pings = 15,
		on_focus_under_fullscreen = 1,
	},
	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
	},
	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},
})
