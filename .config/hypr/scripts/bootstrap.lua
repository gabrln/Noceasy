#!/usr/bin/env lua 

local function exec_capture(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then return "" end
  local out = handle:read("*a") or ""
  handle:close()
  return out
end

local function plugin_installed(name)
  -- 'hyprpm list' imprime uma linha por plugin com o nome na coluna 4.
  -- grep -q com exit code 0 se encontrar.
  local handle = io.popen("hyprpm list 2>/dev/null | grep -qw " .. name .. " ; echo $?")
  if not handle then return true end
  local code = handle:read("*a") or "1"
  handle:close()
  return tonumber(code) == 0
end

local function open_terminal_with(cmd)
  -- Tenta o terminal padrao do ambiente. Cobre os 4 mais comuns em
  -- setups Hyprland. Se nenhum existir, cai para notify-send.
  local candidates = {
    "kitty --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Pressione Enter para fechar\"; read'",
    "foot --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Pressione Enter para fechar\"; read'",
    "alacritty --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Pressione Enter para fechar\"; read'",
    "gnome-terminal -- bash -c '" .. cmd .. "; echo; echo \"Pressione Enter para fechar\"; read'",
  }
  for _, full in ipairs(candidates) do
    -- Checa se o binario existe antes de tentar abrir
    local bin = full:match("^(%S+)")
    if bin and exec_capture("command -v " .. bin) ~= "" then
      hl.exec(full)
      return true
    end
  end
  -- Fallback: notificacao. O usuario roda manualmente.
  hl.exec([[notify-send -u critical "Arch-gabrln bootstrap" "Plugin hyprpm faltando. Rode manualmente: ]] .. cmd .. [["]])
  return false
end

-- Manifesto de plugins (espelha installer/manifests/hyprpm.toml).
-- Mantido inline para nao depender de python/tomllib no startup do hyprland.
local PLUGINS = {
  { name = "scrolloverview", repo = "yayuuu/hyprland-scroll-overview" },
}

for _, plugin in ipairs(PLUGINS) do
  if plugin_installed(plugin.name) then
    -- Ja instalado: silent path, custo ~50ms.
    goto continue
  end

  local cmd = string.format(
    "hyprpm update && hyprpm add https://github.com/%s.git && hyprpm enable %s && hyprpm reload",
    plugin.repo, plugin.name
  )
  open_terminal_with(cmd)
  ::continue::
end
