#!/usr/bin/env lua
-- KeyHints_runner.lua — Cheatsheet interativo de keybindings para Hyprland.
-- Este arquivo é escrito à mão; apenas KeyHints_data.lua é gerado.

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local data = dofile(config_home .. "/hypr/scripts/KeyHints_data.lua")

local w1 = 0
for _, item in ipairs(data) do
    if item[2] ~= "" then
        w1 = math.max(w1, #item[1])
    end
end

local lines = {}
local map_action = {}
for _, item in ipairs(data) do
    local formatted
    if item[2] == "" then
        formatted = item[1]
    else
        formatted = string.format("%-" .. (w1 + 4) .. "s   %s", item[1], item[2])
    end
    table.insert(lines, formatted)
    map_action[formatted] = item[3]
end

local input_str = table.concat(lines, "\n")
local tmp_file = os.tmpname()
local f = io.open(tmp_file, "w")
if f then
    f:write(input_str)
    f:close()
end

local fzf_cmd = 'fzf --no-sort --cycle --header=" [ ENTER: Copiar ação | ESC: Sair ]" --layout=reverse --border=rounded --prompt=" Buscar ou navegar por categoria: "'
local handle = io.popen(string.format("cat %s | %s", tmp_file, fzf_cmd))
local selected = handle:read("*l")
handle:close()
os.remove(tmp_file)

if selected and selected ~= "" then
    selected = selected:match("^%s*(.-)%s*$")
    local action = map_action[selected]
    if not action then
        action = selected:match(".*%s+([^\n]+)$")
    end
    if action then
        local copy_cmd = string.format("printf '%%s' %q | wl-copy", action)
        os.execute(copy_cmd)
        os.execute(string.format(
            'notify-send "Atalho Copiado" "Ação \'%s\' copiada para a área de transferência!" -t 2000 -i edit-copy',
            action))
    end
end
