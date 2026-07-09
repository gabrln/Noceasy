-- =========================================================================
-- Automatic startup and services (Lua module)
-- =========================================================================

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")

	-- hyprpm plugins: bootstrap.lua checks silently (~50ms in the
	-- common case). If any are missing, it opens a visible terminal
	-- with the install command. This does not run during 'install.sh'
	-- because 'hyprpm update' needs Hyprland running to fetch the
	-- headers for the current version.
	hl.exec_cmd("lua ~/.config/hypr/scripts/bootstrap.lua")

	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)
