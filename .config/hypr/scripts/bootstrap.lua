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
    "kitty --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Press Enter to close\"; read'",
    "foot --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Press Enter to close\"; read'",
    "alacritty --title hyprpm-bootstrap -e bash -c '" .. cmd .. "; echo; echo \"Press Enter to close\"; read'",
    "gnome-terminal -- bash -c '" .. cmd .. "; echo; echo \"Press Enter to close\"; read'",
  }
  for _, full in ipairs(candidates) do
    -- Checa se o binario existe antes de tentar abrir
    local bin = full:match("^(%S+)")
    if bin and exec_capture("command -v " .. bin) ~= "" then
      hl.exec_cmd(full)
      return true
    end
  end
  -- Fallback: notification if no terminal is available.
  hl.exec_cmd([[notify-send -u critical "Noceasy bootstrap" "Plugin hyprpm missing. Run manually: ]] .. cmd .. ["]])
  return false
end

-- Manifesto de plugins (espelha installer/manifests/hyprpm.toml).
-- Mantido inline para nao depender de python/tomllib no startup do hyprland.
local PLUGINS = {
  { name = "scrolloverview", repo = "yayuuu/hyprland-scroll-overview" },
}

for _, plugin in ipairs(PLUGINS) do
  if plugin_installed(plugin.name) then
    -- Already installed: silent path, ~50ms cost.
    goto continue
  end

  local cmd = string.format(
    "hyprpm update && hyprpm add https://github.com/%s.git && hyprpm enable %s && hyprpm reload",
    plugin.repo, plugin.name
  )
  open_terminal_with(cmd)
  ::continue::
end

-- Apply scrolloverview plugin config. Done here (not in settings.lua)
-- because hyprpm plugins are only loaded AFTER hyprpm enable, so
-- plugin-specific keywords would otherwise be rejected on first boot.
-- Safe to re-run; keywords are idempotent.
if plugin_installed("scrolloverview") and hl.dsp and hl.dsp.exec_raw then
    local function kw(k, v) hl.dispatch(hl.dsp.exec_raw("keyword " .. k .. " " .. v)) end
    kw("plugin:scrolloverview:gesture_distance", "300")
    kw("plugin:scrolloverview:scale", "0.5")
    kw("plugin:scrolloverview:workspace_gap", "100")
    kw("plugin:scrolloverview:layout", "vertical")
    kw("plugin:scrolloverview:wallpaper", "0")
    kw("plugin:scrolloverview:blur", "false")
    kw("plugin:scrolloverview:input:scrolling_mode", "1")
    kw("scrolloverview-gesture", "3, up, overview")
end
