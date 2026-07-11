#!/usr/bin/env lua
-- WindowInfo.lua - Capture all window details for Hyprland window rules,
-- copy to clipboard, and show as notification.

-- ── Fetch window data ──────────────────────────────────────────────────

local handle = io.popen("hyprctl activewindow -j 2>/dev/null")
local raw = handle:read("*a")
handle:close()

if not raw or raw == "" or raw:match("^%s*$") or raw:match("Invalid") or raw:match("not found") then
    os.execute('notify-send -t 4000 -i dialog-error "Window Info" "No focused window found."')
    os.exit(1)
end

-- ── Parse JSON (try cjson first, fallback to manual) ───────────────────

local win = nil

local ok, cjson = pcall(require, "cjson")
if ok then
    local ok2, parsed = pcall(cjson.decode, raw)
    if ok2 and parsed then
        win = parsed
    end
end

if not win then
    -- Manual regex parsing of hyprctl JSON output
    local function extract(pattern)
        local m = raw:match(pattern)
        return (m and m ~= "") and m or nil
    end

    local function extract_arr(prefix, idx)
        local pat = '"' .. prefix .. '":%s*%[%s*([^%]]+)%]'
        local arr_str = raw:match(pat)
        if not arr_str then return nil end
        local parts = {}
        for p in arr_str:gmatch("[%d%.%-]+") do
            table.insert(parts, tonumber(p) or p)
        end
        return parts[idx] or nil
    end

    local function extract_nested(prefix, field)
        local pat = '"' .. prefix .. '":%s*{[^}]*"' .. field .. '":%s*([%d%.%-]+)'
        local m = raw:match(pat)
        if m then return tonumber(m) end
        pat = '"' .. prefix .. '":%s*{[^}]*"' .. field .. '":%s*"([^"]+)"'
        m = raw:match(pat)
        return m
    end

    local function bool(v)
        if v == "true" then return true end
        if v == "false" then return false end
        return nil
    end

    local address  = extract('"address":%s*"([^"]+)"')
    local class    = extract('"class":%s*"([^"]+)"')
    local title    = extract('"title":%s*"([^"]+)"')
    local initCls  = extract('"initialClass":%s*"([^"]+)"')
    local initTtl  = extract('"initialTitle":%s*"([^"]+)"')
    local pid_s    = extract('"pid":%s*(%d+)')

    local ws_id    = extract_nested("workspace", "id")
    local ws_name  = extract_nested("workspace", "name")

    local floating = bool(extract('"floating":%s*(%a+)'))
    local pinned   = bool(extract('"pinned":%s*(%a+)'))
    local full_s   = extract('"fullscreen":%s*(%d+)')
    local mapped   = bool(extract('"mapped":%s*(%a+)'))
    local hidden   = bool(extract('"hidden":%s*(%a+)'))
    local  decorated  = bool(extract('"decorated":%s*(%a+)'))
    local swallowing  = bool(extract('"swallowing":%s*(%a+)'))
    local focus_id = extract('"focusHistoryID":%s*(%d+)')
    local mon_s    = extract('"monitor":%s*(%d+)')

    local at_x = extract_arr("at", 1)
    local at_y = extract_arr("at", 2)
    local size_w = extract_arr("size", 1)
    local size_h = extract_arr("size", 2)

    win = {
        address = address,
        class = class,
        title = title,
        initialClass = initCls,
        initialTitle = initTtl,
        pid = pid_s and tonumber(pid_s) or nil,
        workspace = ws_id and { id = ws_id, name = ws_name } or nil,
        monitor = mon_s and tonumber(mon_s) or nil,
        floating = floating,
        pinned = pinned,
        fullscreen = full_s and tonumber(full_s) or nil,
        mapped = mapped,
        hidden = hidden,
        decorated = decorated,
        swallowing = swallowing,
        focusHistoryID = focus_id and tonumber(focus_id) or nil,
        at = (at_x and at_y) and { at_x, at_y } or nil,
        size = (size_w and size_h) and { size_w, size_h } or nil,
    }
end

-- ── Helpers ────────────────────────────────────────────────────────────

local function val(v)
    if v == nil then return "N/A" end
    local t = type(v)
    if t == "boolean" then return v and "Yes" or "No" end
    if t == "number" then return tostring(v) end
    if t == "string" then
        if v == "" then return "(empty)" end
        return v
    end
    if t == "table" then
        if v.name then return v.name end
        if v.id then return tostring(v.id) end
        return "N/A"
    end
    return tostring(v)
end

-- ── Build output ───────────────────────────────────────────────────────

local class = win.class or "N/A"
local title = win.title or "N/A"
local initialClass = win.initialClass or "N/A"
local initialTitle = win.initialTitle or "N/A"
local ws_name = (win.workspace and win.workspace.name) or "N/A"
local ws_id = (win.workspace and win.workspace.id) or "N/A"

if title == "" then title = "(empty)" end
if initialTitle == "" then initialTitle = "(empty)" end

local function esc(s)
    return s:gsub('"', '\\"')
end

local function regex_escape(s)
    return s:gsub("[%(%)%.%*%+%?%[%]%^%$%%]", "%%%1")
end

local lines = {}
table.insert(lines, " Window Info - Hyprland")
table.insert(lines, string.rep("─", 50))
table.insert(lines, "")

table.insert(lines, "-- Match fields for window rules:")
table.insert(lines, string.format("class:         %s", class))
table.insert(lines, string.format("title:         %s", title))
table.insert(lines, string.format("initialClass:  %s", initialClass))
table.insert(lines, string.format("initialTitle:  %s", initialTitle))
table.insert(lines, "")
table.insert(lines, "-- Other properties:")
table.insert(lines, string.format("address:       0x%s", val(win.address)))
table.insert(lines, string.format("pid:           %s", val(win.pid)))
table.insert(lines, string.format("workspace:     %s (id: %s)", ws_name, val(ws_id)))
table.insert(lines, string.format("monitor:       %s", val(win.monitor)))
table.insert(lines, string.format("floating:      %s", val(win.floating)))
table.insert(lines, string.format("pinned:        %s", val(win.pinned)))
table.insert(lines, string.format("fullscreen:    %s", val(win.fullscreen)))
table.insert(lines, string.format("mapped:        %s", val(win.mapped)))
table.insert(lines, string.format("hidden:        %s", val(win.hidden)))
table.insert(lines, string.format("decorated:     %s", val(win.decorated)))
table.insert(lines, string.format("swallowing:    %s", val(win.swallowing)))
table.insert(lines, string.format("focusHistoryID:%s", val(win.focusHistoryID)))
if win.at and #win.at >= 2 then
    table.insert(lines, string.format("position:      %d, %d", win.at[1], win.at[2]))
end
if win.size and #win.size >= 2 then
    table.insert(lines, string.format("size:          %d x %d", win.size[1], win.size[2]))
end

table.insert(lines, "")
table.insert(lines, string.rep("─", 50))
table.insert(lines, " Lua Window Rule Examples")
table.insert(lines, string.rep("─", 50))
table.insert(lines, "")

-- Class-based float
table.insert(lines, string.format('hl.window_rule({ match = { class = "%s" }, float = true })', esc(class)))
-- Title-based float (if title is meaningful)
if title ~= "(empty)" and title ~= "N/A" then
    local safe_title = regex_escape(esc(title))
    if #safe_title > 60 then safe_title = safe_title:sub(1, 60) end
    table.insert(lines, string.format('hl.window_rule({ match = { title = ".*%s.*" }, float = true })', safe_title))
end
-- initialClass-based rules (useful for PWAs)
if initialClass ~= "N/A" and initialClass ~= class then
    table.insert(lines, string.format('hl.window_rule({ match = { initialClass = "%s" }, float = true })', esc(initialClass)))
end
-- Size/position rule
if win.size and #win.size >= 2 then
    table.insert(lines, string.format('hl.window_rule({ match = { class = "%s" }, size = "%d %d", center = true })', esc(class), win.size[1], win.size[2]))
end
-- Workspace rule
table.insert(lines, string.format('hl.window_rule({ match = { class = "%s" }, workspace = "special:%s" })', esc(class), esc(class:lower())))

table.insert(lines, "")
table.insert(lines, string.rep("─", 50))
table.insert(lines, " Pyprland Scratchpad Config")
table.insert(lines, string.rep("─", 50))
table.insert(lines, "")
table.insert(lines, string.format("[scratchpads.%s]", esc(class:lower())))
table.insert(lines, string.format('command = "%s"', esc(class:lower() == "kitty-drop" and "kitty --class kitty-drop" or esc(class))))
table.insert(lines, string.format('class = "%s"', esc(class)))
if win.size and #win.size >= 2 then
    table.insert(lines, string.format('size = "%d %d"', win.size[1], win.size[2]))
end
table.insert(lines, "animation = \"fromTop\"")
table.insert(lines, "lazy = true")

local out = table.concat(lines, "\n")

-- ── Copy to clipboard ──────────────────────────────────────────────────

local function shell_quote(s)
    -- Simple single-quote escaping for shell
    local escaped = s:gsub("'", "'\\''")
    return "'" .. escaped .. "'"
end

local clip_cmd = "printf " .. shell_quote(out) .. " | wl-copy"
os.execute(clip_cmd)

-- ── Show notification ──────────────────────────────────────────────────

local notify_parts = {}
table.insert(notify_parts, string.format("Class: %s", class))
table.insert(notify_parts, string.format("Title: %s", (#title > 60 and title:sub(1, 60) .. "..." or title)))
table.insert(notify_parts, string.format("InitClass: %s", initialClass))
table.insert(notify_parts, string.format("InitTitle: %s", (#initialTitle > 60 and initialTitle:sub(1, 60) .. "..." or initialTitle)))
if win.size and #win.size >= 2 then
    table.insert(notify_parts, string.format("Size: %dx%d  Float:%s Pin:%s", win.size[1], win.size[2], val(win.floating), val(win.pinned)))
end
table.insert(notify_parts, "")
table.insert(notify_parts, "Copied to clipboard!")

local msg = table.concat(notify_parts, "\n")
local notify_cmd = "notify-send -t 10000 -i dialog-information 'Window Info' " .. shell_quote(msg)
os.execute(notify_cmd)
