#!/usr/bin/env lua
-- WindowInfo.lua - Display details of the active window via notification

local handle = io.popen("hyprctl activewindow 2>/dev/null")
local content = handle:read("*a")
handle:close()

if not content or content:match("^%s*$") or content:match("Invalid") then
    os.execute('notify-send -t 4000 -i dialog-error "Active Window Info" "No focused window found in Hyprland."')
    os.exit(1)
end

local address = content:match("Window%s+([%w]+)%s+->") or "N/A"
local pid = content:match("\n%s*pid:%s*(%d+)") or "N/A"
local class = content:match("\n%s*class:%s*([^\n]+)") or "N/A"
local title = content:match("\n%s*title:%s*([^\n]+)") or "N/A"
local ws_name = content:match("\n%s*workspace:%s*%d+%s*%(([^)]+)%)}") or content:match("\n%s*workspace:%s*([^\n]+)") or "N/A"
local floating_val = content:match("\n%s*floating:%s*(%d+)") or "0"
local floating_str = (floating_val == "1") and "Yes" or "No"

local msg = string.format(
    "<b>Address:</b> 0x%s\n<b>PID:</b> %s\n<b>Class (App ID):</b> %s\n<b>Title:</b> %s\n<b>Workspace:</b> %s\n<b>Floating:</b> %s",
    address, pid, class, title, ws_name, floating_str
)

local cmd = string.format('notify-send -t 8000 -i dialog-information "Active Window Info" %q', msg)
os.execute(cmd)
