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
