-- =============================================================================
-- HYPRLAND LUA CONFIGURATION (v0.55.0+)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Imports & Modules
-- -----------------------------------------------------------------------------
require("noctalia")

-- -----------------------------------------------------------------------------
-- 2. Environment Variables
-- -----------------------------------------------------------------------------
local env_variables = {
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
	QS_ICON_THEME = "Papirus-Dark",
}

for key, value in pairs(env_variables) do
	hl.env(key, value)
end

-- -----------------------------------------------------------------------------
-- 3. Core Configurations (Look & Feel, Input, Rules)
-- -----------------------------------------------------------------------------
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
		column_width = 0.7,
		fullscreen_on_one_column = true,
		follow_focus = true,
		focus_fit_method = 1,
		explicit_column_widths = "0.3, 0.5, 0.7, 1.0",
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
	cursor = { no_warps = true, inactive_timeout = 3, hide_on_key_press = true },

})

-- -----------------------------------------------------------------------------
-- 4. Monitors & Workspaces
-- -----------------------------------------------------------------------------
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = "1.0" })

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", persistent = true })
end

-- -----------------------------------------------------------------------------
-- 5. Window & Layer Rules
-- -----------------------------------------------------------------------------
hl.layer_rule({
	name = "noctalia",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel)$" },
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

hl.window_rule({
	match = { class = "floating-keyhints" },
	float = true,
	size = { 1000, 650 },
	center = true,
	pin = true,
})

hl.window_rule({
	match = { initial_class = "obsidian" },
	tile = true,
	float = false,
})

-- -----------------------------------------------------------------------------
-- 6. Animations & Easing Curves
-- -----------------------------------------------------------------------------
hl.curve("fade", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })

hl.animation({ leaf = "global", enabled = false })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "fade" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "fade", style = "slidefadevert" })

-- -----------------------------------------------------------------------------
-- 7. Helpers & Factories (Scratchpads)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 8. Keybindings (hl.bind)
-- -----------------------------------------------------------------------------
local mainMod = "SUPER"
local browser = "firefox"
local ipc = "noctalia msg"
local scriptsDir = "/home/gsouza/.config/hypr/scripts"

-- --- Application Launchers ---
-- --- Application Launchers ---
hl.bind(mainMod .. " + return", hl.dsp.exec_raw("kitty --title Kitty"))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + h", hl.dsp.exec_raw("kitty --class floating-keyhints -e " .. scriptsDir .. "/KeyHints.sh"))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.exec_raw("kitty --class floating-keyhints -e " .. scriptsDir .. "/AliasHints.sh"))
hl.bind(mainMod .. " + d", hl.dsp.exec_cmd(ipc .. " panel-toggle launcher"))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.exec_cmd(ipc .. " settings-toggle"))
hl.bind(mainMod .. " + e", hl.dsp.exec_raw("kitty -e yazi"))
hl.bind(mainMod .. " + SHIFT + d", hl.dsp.exec_cmd(scriptsDir .. "/WindowInfo.sh"))

-- --- Window Management ---
hl.bind(mainMod .. " + q", hl.dsp.window.close(), { repeating = true })

hl.bind("ALT + F4", function()
	local w = hl.get_active_window()
	if w and w.pid then
		-- 1. Validar pelas classes de janela do Hyprland
		local class = (w.class or ""):lower()
		local initialClass = (w.initialClass or ""):lower()
		if class:find("noctalia") or initialClass:find("noctalia") or class:find("hyprland") then
			hl.exec_cmd("notify-send 'Ação Bloqueada' 'Não é permitido encerrar o Noctalia ou Hyprland!' -u critical -t 3000")
			return
		end

		-- 2. Validar pelo executável lido no /proc/<pid>/comm
		local proc_name = w.class or "Desconhecido"
		local f = io.open("/proc/" .. w.pid .. "/comm", "r")
		if f then
			local comm = f:read("*l")
			f:close()
			if comm then
				proc_name = comm
				comm = comm:lower():gsub("%s+", "")
				if comm:find("noctalia") or comm:find("hyprland") then
					hl.exec_cmd("notify-send 'Ação Bloqueada' 'Não é permitido encerrar o processo: " .. proc_name .. "' -u critical -t 3000")
					return
				end
			end
		end

		-- 3. Executar encerramento agressivo
		hl.exec_cmd("kill -9 " .. w.pid)
		hl.exec_cmd("notify-send 'Processo Encerrado' 'Processo \"" .. proc_name .. "\" (PID: " .. w.pid .. ") encerrado agressivamente.' -t 2000")
	end
end)

hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.kill())
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + m", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + space", function()
	local w = hl.get_active_window()
	if not w then return end
	if w.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	else
		if w.fullscreen ~= 0 then
			hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset" }))
			hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "unset" }))
		end
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800, relative = false }))
		hl.dispatch(hl.dsp.window.center())
	end
end)
hl.bind(mainMod .. " + ALT + space", function()
	local active_w = hl.get_active_window()
	if not active_w then return end
	local active_ws = active_w.workspace.name
	local windows = hl.get_windows()
	for _, win in ipairs(windows) do
		if win.workspace.name == active_ws then
			hl.exec_cmd("hyprctl dispatch togglefloating address:" .. win.address)
		end
	end
end)
hl.bind(mainMod .. " + o", function()
	local w = hl.get_active_window()
	if w then
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.pin())
	end
end)
hl.bind(mainMod .. " + SHIFT + i", hl.dsp.layout("togglesplit"))

-- --- Focus & Navigation ---
-- Directional Arrow Keys
for _, dir in ipairs({ "left", "right", "up", "down" }) do
	hl.bind(mainMod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind(mainMod .. " + CTRL + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Resize active window via SUPER + SHIFT + Arrow keys
local resize_dirs = {
	left = { x = -50, y = 0 },
	right = { x = 50, y = 0 },
	up = { x = 0, y = -50 },
	down = { x = 0, y = 50 },
}
for dir, val in pairs(resize_dirs) do
	hl.bind(mainMod .. " + SHIFT + " .. dir, hl.dsp.window.resize({ x = val.x, y = val.y, relative = true }), { repeating = true })
end

-- Workspaces
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
	hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- --- Window Switcher (Snappy Switcher) ---
hl.bind("ALT + Tab", hl.dsp.exec_cmd("snappy-switcher next --mod alt"))

-- --- Mouse Bindings ---
-- Inverted scroll direction: Up -> Prev (e-1), Down -> Next (e+1)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- --- Window Resizing (Omarchy keys & ALT+Arrows fallback) ---
hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

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

-- --- Layout Controls ---
hl.bind(mainMod .. " + ALT + l", function()
	local current = hl.get_config("general.layout")
	if current == "dwindle" then
		hl.config({ general = { layout = "scrolling" } })
		hl.exec_cmd("notify-send 'Layout: Scrolling' -t 2000")
	else
		hl.config({ general = { layout = "dwindle" } })
		hl.exec_cmd("notify-send 'Layout: Dwindle' -t 2000")
	end
end)

-- Scrolling Layout Specifics
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + ALT + period", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + ALT + comma", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + c", hl.dsp.layout("centerview"))
hl.bind(mainMod .. " + SHIFT + x", hl.dsp.layout("consume_or_expel"))
hl.bind(mainMod .. " + SHIFT + p", hl.dsp.layout("promote"))

-- --- Scratchpads & Groups ---
hl.bind(mainMod .. " + SHIFT + return", toggle_drop)
hl.bind(mainMod .. " + F1", toggle_btop)
hl.bind(mainMod .. " + u", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + u", function()
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

hl.bind(mainMod .. " + g", hl.dsp.group.toggle())
hl.bind(mainMod .. " + bracketleft", hl.dsp.group.prev())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + CTRL + g", hl.dsp.group.lock())

-- --- System, Media & Noctalia Panels ---
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd(ipc .. " panel-toggle clipboard"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(ipc .. " screenshot-fullscreen"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(ipc .. " screenshot-region"))
hl.bind("ALT + Print", hl.dsp.exec_cmd(ipc .. " screenshot-fullscreen pick"))
hl.bind("CTRL + ALT + l", hl.dsp.exec_cmd(ipc .. " session lock"))
hl.bind("CTRL + ALT + delete", hl.dsp.exec_raw("hyprctl dispatch exit"))
hl.bind("CTRL + ALT + p", hl.dsp.exec_cmd(ipc .. " panel-toggle session"))
hl.bind(mainMod .. " + SHIFT + n", hl.dsp.exec_cmd(ipc .. " panel-toggle control-center notifications"))
hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd(ipc .. " mic-mute"))

-- --- Noctalia System Controls ---
hl.bind(mainMod .. " + n", hl.dsp.exec_cmd(ipc .. " nightlight-toggle"))
hl.bind(mainMod .. " + y", hl.dsp.exec_cmd(ipc .. " caffeine-toggle"))
hl.bind(mainMod .. " + w", hl.dsp.exec_cmd(ipc .. " wallpaper-random"))
hl.bind(mainMod .. " + SHIFT + t", hl.dsp.exec_cmd(ipc .. " theme-mode-toggle"))

-- --- Extra Features via Lua ---
hl.bind(mainMod .. " + ALT + o", function()
	local current = hl.get_config("decoration.blur.enabled")
	hl.config({ decoration = { blur = { enabled = not current } } })
end)

local gamemode_active = false
hl.bind(mainMod .. " + SHIFT + g", function()
	gamemode_active = not gamemode_active
	if gamemode_active then
		hl.config({
			animations = { enabled = false },
			decoration = {
				blur = { enabled = false },
				shadow = { enabled = false },
			},
			general = {
				gaps_in = 0,
				gaps_out = 0,
			}
		})
		hl.exec_cmd("notify-send 'Modo Jogo Ativado' -t 2000")
	else
		hl.config({
			animations = { enabled = true },
			decoration = {
				blur = { enabled = true },
				shadow = { enabled = true },
			},
			general = {
				gaps_in = 5,
				gaps_out = 5,
			}
		})
		hl.exec_cmd("notify-send 'Modo Jogo Desativado' -t 2000")
	end
end)

hl.bind(mainMod .. " + CTRL + o", hl.dsp.exec_raw("hyprctl dispatch toggleopaque"))

-- --- Hardware & Media Keys ---
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. " volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. " volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. " volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. " brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness-down"))

-- Media playback controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. " media toggle"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. " media toggle"))
hl.bind("XF86MediaPlayPause", hl.dsp.exec_cmd(ipc .. " media toggle"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. " media next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. " media previous"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(ipc .. " media stop"))

-- -----------------------------------------------------------------------------
-- 9. Autostart Events
-- -----------------------------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("noctalia")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("snappy-switcher --daemon")
end)
