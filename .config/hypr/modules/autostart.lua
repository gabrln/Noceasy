-- =========================================================================
-- Inicialização Automática e Serviços (Módulo Lua)
-- =========================================================================

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")

	hl.exec_cmd([[bash -c '
		if ! hyprpm list 2>/dev/null | grep -q scrolloverview; then
			if ! hyprpm update && hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git && hyprpm enable scrolloverview; then
				notify-send -u critical "HyprPM" "Falha ao instalar o plugin scrolloverview. Verifique hyprpm manualmente."
			fi
		fi
		hyprpm reload 2>/dev/null || true
	']])

	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)
