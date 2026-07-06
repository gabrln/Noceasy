-- =========================================================================
-- Inicialização Automática e Serviços (Módulo Lua)
-- =========================================================================

hl.on("hyprland.start", function()
	hl.exec_cmd("noctalia")

	-- Plugins hyprpm: bootstrap.lua verifica silenciosamente se ja
	-- estao instalados (~50ms no caso comum). Se faltar algum, abre
	-- um terminal visivel com o comando de instalacao. Nao roda
	-- durante a instalacao porque 'hyprpm update' precisa do
	-- Hyprland rodando para puxar os headers da versao em execucao.
	hl.exec_cmd("lua ~/.config/hypr/scripts/bootstrap.lua")

	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --gapplication-service")
end)
