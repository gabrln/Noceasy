-- =========================================================================
-- Inicialização Automática e Serviços (Módulo Lua)
-- =========================================================================

hl.on("hyprland.start", function()
	-- Prioridade máxima: iniciar o desktop shell (wallpaper, painel e notificações) imediatamente
	hl.exec_cmd("noctalia")

	-- Instalar e carregar plugins do Hyprland
	hl.exec_cmd("~/.config/hypr/scripts/hyprpm.lua")

	-- Serviços de chaves (chaveiro GNOME) - Polkit é gerido nativamente pelo Noctalia
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

	-- Utilitários do sistema e clipboard
	hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)
