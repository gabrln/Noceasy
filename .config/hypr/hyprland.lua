-- ============================================================
-- HYPRLAND 0.55.0
-- ============================================================

require("noctalia")

-- - - - Environment Variables - - -
hl.env = {
	LIBVA_DRIVER_NAME = "iHD",
	GBM_BACKEND = "drimod",
	__GLX_VENDOR_LIBRARY_NAME = "mesa",
	QT_QPA_PLATFORM = "wayland;xcb",
	ELECTRON_OZONE_PLATFORM_HINT = "wayland",
	XDG_CURRENT_DESKTOP = "Hyprland",
	XDG_SESSION_DESKTOP = "Hyprland",
	XDG_SESSION_TYPE = "wayland",
	QT_AUTO_SCREEN_SCALE_FACTOR = "1",
	QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
	QT_QPA_PLATFORMTHEME = "qt6ct",
	MOZ_ENABLE_WAYLAND = "1",
	XCURSOR_THEME = "Bibata-Modern-Classic",
	XCURSOR_SIZE = "24",
	HYPRCURSOR_THEME = "Bibata-Modern-Classic",
	HYPRCURSOR_SIZE = "24",
}

-- - - - Animations - - -
hl.curve("fade", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })

hl.animation({ leaf = "global", enabled = false })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })

-- - - - General & Decoration - - -
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 5,
		resize_on_border = true,
		extend_border_grab_area = 10,
	},
	decoration = {
		rounding = 5,
		rounding_power = 2,
		shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
		blur = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 },
	},
	dwindle = { preserve_split = true },
	scrolling = {
		column_width = 1.0,
		fullscreen_on_one_column = true,
		follow_focus = true,
		focus_fit_method = 0,
		explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
	},
	binds = {
		allow_workspace_cycles = true,
		movefocus_cycles_fullscreen = false,
		workspace_back_and_forth = true,
		workspace_center_on = 1,
	},
	input = {
		kb_layout = "br",
		numlock_by_default = true,
		repeat_rate = 60,
		repeat_delay = 300,
		follow_mouse = 1,
		sensitivity = -0.4,
		scroll_factor = 2.0,
		accel_profile = "flat",
		touchpad = { natural_scroll = true, disable_while_typing = true, tap_to_click = true },
	},
	misc = { disable_hyprland_logo = true, focus_on_activate = false },
	cursor = { no_warps = true },
})

-- - - - Monitor & Workspaces - - -
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = "1.0" })

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
end

-- - - - Layer Rules (Noctalia) - - -
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel)$" },
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

-- - - - Scratchpad Factory - - -
local function create_scratchpad(class, cmd, special_name, size, center)
	hl.window_rule({
		match = { class = class },
		workspace = "special:" .. special_name,
		float = true,
		size = size,
		center = center or false,
	})

	return function()
		local win = hl.get_window("class:" .. class)
		if not win then
			hl.dispatch(hl.dsp.exec_cmd(cmd))
		else
			hl.dispatch(hl.dsp.workspace.toggle_special(special_name))
		end
	end
end

local toggle_drop = create_scratchpad("kitty-drop", "kitty --app-id kitty-drop", "drop", { 1600, 900 }, false)
local toggle_btop = create_scratchpad("btop-scratch", "kitty --app-id btop-scratch btop", "btop", { 1400, 800 }, true)

-- - - - App Launchers - - -
local mainMod = "SUPER"
local browser = "firefox"
local ipc = "noctalia msg"

hl.bind(mainMod .. " + return", hl.dsp.exec_raw("kitty --title Kitty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))

-- - - - Window Management - - -
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + O", function()
	local w = hl.get_active_window()
	if w then
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.pin())
	end
end)
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- - - - Navigation & Focus - - -
for _, dir in ipairs({ "left", "right", "up", "down" }) do
	hl.bind(mainMod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind(mainMod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
	-- Move window to workspace without following
	hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
-- Inverted scroll direction: Up -> Prev (e-1), Down -> Next (e+1)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- - - - Layout & Resizing - - -
-- Resize with Equal/Minus (Omarchy style)
-- SUPER + = : Grow Right (x +50)
-- SUPER + - : Grow Left (x -50)
-- SUPER + SHIFT + = : Grow Up (y -50)
-- SUPER + SHIFT + - : Grow Down (y +50)
hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Resize with Arrow Keys (Legacy/Alternative)
local resize_maps = {
	{ key = "left", x = -50, y = 0 },
	{ key = "right", x = 50, y = 0 },
	{ key = "up", x = 0, y = -50 },
	{ key = "down", x = 0, y = 50 },
}
for _, map in ipairs(resize_maps) do
	hl.bind(
		mainMod .. " + ALT + " .. map.key,
		hl.dsp.window.resize({ x = map.x, y = map.y, relative = true }),
		{ repeating = true }
	)
end

hl.bind(mainMod .. " + SHIFT + L", function()
	local current = hl.get_config("general.layout")
	if current == "dwindle" then
		hl.config({ general = { layout = "scrolling" } })
		hl.notification.create({ text = "Layout: Scrolling", timeout = 2000, icon = "ok" })
	else
		hl.config({ general = { layout = "dwindle" } })
		hl.notification.create({ text = "Layout: Dwindle", timeout = 2000, icon = "ok" })
	end
end)

-- Scrolling layout specific bindings
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + C", hl.dsp.exec_raw("dispatch centerview"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.layout("consume_or_expel"))

-- - - - Scratchpads & Groups - - -
hl.bind(mainMod .. " + T", toggle_drop)
hl.bind(mainMod .. " + F1", toggle_btop)

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", function()
	local w = hl.get_active_window()
	if w == nil then
		return
	end
	if w.workspace.name == "special:magic" then
		hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
	else
		hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
	end
end)

hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + bracketleft", hl.dsp.group.prev())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock())

-- - - - System & Media (Noctalia) - - -
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(ipc .. " screenshot-region"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(ipc .. " screenshot-fullscreen"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. " session logout"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ipc .. " panel-toggle control-center"))
hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd(ipc .. " mic-mute"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. " volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. " volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. " volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. " brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"))

-- - - - Autostart - - -
hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")
	hl.exec_cmd("wl-paste --watch cliphist store")
end)
