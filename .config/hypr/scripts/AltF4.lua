#!/usr/bin/env lua
-- AltF4.lua - Force-close the active window in Hyprland

local handle = io.popen("hyprctl activewindow 2>/dev/null")
local content = handle:read("*a")
handle:close()

if not content or content:match("^%s*$") or content:match("Invalid") then
    os.execute('notify-send -t 3000 -i dialog-error "Close Error" "No focused window found in Hyprland."')
    os.exit(1)
end

local pid_str = content:match("\n%s*pid:%s*(%d+)")
local pid = tonumber(pid_str)
local class = content:match("\n%s*class:%s*([^\n]+)") or "Unknown"
local title = content:match("\n%s*title:%s*([^\n]+)") or "Application"

local protected_apps = {
    "noctalia", "systemd", "dbus-daemon", "dbus-broker",
    "xwayland", "pipewire", "wireplumber", "greetd",
    "hyprland", "antigravity"
}

local class_lower = class:lower()
local title_lower = title:lower()

for _, protected in ipairs(protected_apps) do
    if class_lower:find(protected, 1, true) or title_lower:find(protected, 1, true) then
        os.execute(string.format('notify-send -t 3000 -i dialog-error "Access Denied" "Cannot close a system process: %s"', title))
        os.exit(1)
    end
end

if pid and pid <= 1000 then
    os.execute(string.format('notify-send -t 3000 -i dialog-error "Access Denied" "Cannot close system processes (PID: %d)"', pid))
    os.exit(1)
end

if pid then
    os.execute(string.format("kill -9 %d", pid))
    os.execute(string.format('notify-send -t 4000 -i dialog-warning "Process Closed" "<b>%s</b> (PID: %d, Class: %s) has been force-closed."', title, pid, class))
else
    os.execute("hyprctl dispatch closewindow active")
    os.execute('notify-send -t 3000 -i dialog-information "Window Closed" "The window was closed via the default Hyprland method."')
end
