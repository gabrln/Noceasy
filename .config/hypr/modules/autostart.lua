-- =========================================================================
-- Automatic startup and services (Lua module)
-- =========================================================================

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")

	-- Pyprland: delay ensures Hyprland socket is fully ready
	hl.timer(function()
		hl.exec_cmd("pypr")
	end, { timeout = 2000, type = "oneshot" })
end)
