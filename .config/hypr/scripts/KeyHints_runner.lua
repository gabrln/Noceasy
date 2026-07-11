#!/usr/bin/env lua
-- KeyHints_runner.lua — Cheatsheet interativo de keybindings para Hyprland.
-- Este arquivo é escrito à mão; apenas KeyHints_data.lua é gerado.

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local data = dofile(config_home .. "/hypr/scripts/KeyHints_data.lua")

-- Agrupar entradas por categoria (usando campo group, não prefixo na descrição)
local categories = {}
local category_order = {}
local entry_map = {}  -- key → {desc, action, group}

for _, item in ipairs(data) do
    local key, desc, action = item[1], item[2], item[3]
    local group = item[4] or "Misc"

    if not categories[group] then
        categories[group] = {}
        table.insert(category_order, group)
    end

    table.insert(categories[group], { key = key, desc = desc, action = action })
    entry_map[key] = { desc = desc, action = action, group = group }
end

-- Calcular largura máxima da chave
local max_key_len = 0
for _, cat in ipairs(category_order) do
    for _, entry in ipairs(categories[cat]) do
        max_key_len = math.max(max_key_len, #entry.key)
    end
end

-- Construir saída formatada com cabeçalhos de categoria
local lines = {}
for _, cat in ipairs(category_order) do
    -- Cabeçalho da categoria (ciano bold)
    local header = string.rep("═", 3) .. " " .. cat .. " " .. string.rep("═", math.max(0, 50 - #cat))
    table.insert(lines, "\27[1;36m" .. header .. "\27[0m")
    table.insert(lines, "")

    -- Entradas da categoria
    for _, entry in ipairs(categories[cat]) do
        local formatted = string.format(
            "\27[1m%-" .. (max_key_len + 2) .. "s\27[0m %s",
            entry.key,
            entry.desc
        )
        table.insert(lines, formatted)
    end

    table.insert(lines, "")
end

-- Escrever em arquivo temporário
local input_str = table.concat(lines, "\n")
local tmp_file = os.tmpname()
local f = io.open(tmp_file, "w")
if f then
    f:write(input_str)
    f:close()
end

-- Iniciar fzf
local fzf_cmd = table.concat({
    "fzf",
    "--no-sort",
    "--cycle",
    "--layout=reverse",
    "--border=rounded",
    '--header=" ENTER: Copiar | ESC: Sair "',
    '--prompt=" 🔍 Buscar: "',
    "--height=100%",
    "--info=inline",
    "--ansi",
}, " ")

local handle = io.popen(string.format("cat %s | %s", tmp_file, fzf_cmd))
local selected = handle:read("*l")
handle:close()
os.remove(tmp_file)

-- Tratar seleção
if selected and selected ~= "" then
    -- Extrair chave da linha formatada (remover códigos ANSI)
    local key = selected:match("^%s*\27%[[%d;]+m(.-)\27%[0m")
    if not key then
        key = selected:match("^%s*(.-)%s*$")
    end

    if key and key ~= "" then
        local entry = entry_map[key]
        if entry then
            -- Copiar ação para área de transferência
            local copy_cmd = string.format("printf '%%s' %q | wl-copy", entry.action)
            os.execute(copy_cmd)

            -- Mostrar notificação com descrição
            os.execute(string.format(
                'notify-send "Atalho Copiado" "%s copiado para a área de transferência!" -t 2000 -i edit-copy',
                entry.desc))
        end
    end
end
