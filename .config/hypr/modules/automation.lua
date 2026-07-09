-- =========================================================================
-- Automações Nativas em Lua (Módulo Lua v0.55+)
-- =========================================================================

-- 1. Automatic Layout Switching (Single vs Multi-monitor)
-- Keeps scrolling layout as default for single screen, switches to dwindle on multi-monitor
local function auto_select_layout()
    local monitors = hl.get_monitors()
    if monitors and #monitors > 1 then
        hl.config({ general = { layout = "dwindle" } })
    else
        hl.config({ general = { layout = "scrolling" } })
    end
end

hl.on("monitor.added", auto_select_layout)
hl.on("monitor.removed", auto_select_layout)

-- 2. Auto Game Mode (disables blur, shadows and animations in games)
local gamemode_active = false

local function update_gamemode()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local windows = hl.get_workspace_windows(ws.name)
    if not windows then return end

    local has_game = false
    for _, win in ipairs(windows) do
        local cls = string.lower(win.class or "")
        local title = string.lower(win.title or "")
        -- Anchor matches to the class name boundaries to avoid
        -- false positives like "autoplace.exe" matching "dota".
        if cls:find("steam_app") or cls:find("gamescope") or cls:find("lutris")
            or cls:find("heroic") or cls:find("dota2") or cls:find("cs2")
            or cls:find("wine") then
            has_game = true
            break
        end
    end

    if has_game and not gamemode_active then
        gamemode_active = true
        hl.exec_cmd("notify-send -t 3000 -a System 'Game Mode' 'Automatically enabled (reduced visual effects)'")
        hl.config({
            decoration = {
                blur = { enabled = false },
                drop_shadow = false,
            },
            animations = { enabled = false }
        })
    elseif not has_game and gamemode_active then
        gamemode_active = false
        hl.exec_cmd("notify-send -t 3000 -a System 'Game Mode' 'Disabled (visual effects restored)'")
        hl.config({
            decoration = {
                blur = { enabled = true },
                drop_shadow = true,
            },
            animations = { enabled = true }
        })
    end
end

hl.on("workspace.active", update_gamemode)
hl.on("window.destroy", update_gamemode)
hl.on("window.move_to_workspace", update_gamemode)

-- 3. Native battery monitoring via Lua timer (lightweight 30s check)
local notified_10 = false
local notified_20 = false

local function check_battery()
    local f_cap = io.open("/sys/class/power_supply/BAT0/capacity", "r")
    local f_stat = io.open("/sys/class/power_supply/BAT0/status", "r")
    if not f_cap or not f_stat then
        if f_cap then f_cap:close() end
        if f_stat then f_stat:close() end
        return
    end
    
    local cap_str = f_cap:read("*all")
    local stat = f_stat:read("*all"):gsub("%s+", "")
    f_cap:close()
    f_stat:close()
    
    local cap = tonumber(cap_str)
    if not cap then return end
    
    if stat == "Discharging" then
        if cap <= 10 and not notified_10 then
            notified_10 = true
            hl.exec_cmd("notify-send -t 10000 -u critical -i battery-empty -a System 'Critical Battery!' 'Only " .. cap .. "% remaining. Plug in the charger immediately.'")
        elseif cap <= 20 and not notified_20 then
            notified_20 = true
            hl.exec_cmd("notify-send -t 10000 -u critical -i battery-low -a System 'Low Battery!' 'Less than 20% (" .. cap .. "%) remaining.'")
        end
    elseif stat == "Charging" or stat == "Full" or stat == "Notcharging" then
        if cap > 20 then notified_20 = false end
        if cap > 10 then notified_10 = false end
    end
end

hl.timer(check_battery, { timeout = 30000, type = "repeat" })
