#!/usr/bin/env lua
-- KeyHints.lua - Hyprland Cheat Sheet & Shortcut Launcher in Lua

local shortcuts = {
  { "Hypr",     "SUPER + Return",            "Open Terminal",                 "kitty" },
  { "Hypr",     "SUPER + SHIFT + Q",         "Close Window",                  "hl.dsp.window.close()" },
  { "Hypr",     "SUPER + Space",             "Toggle Float",                  "hl.dsp.window.float({ action = 'toggle' })" },
  { "Hypr",     "SUPER + M",                 "Fit Active (Maximize)",         "hl.dsp.layout('fit active')" },
  { "Hypr",     "SUPER + F",                 "Toggle Fullscreen",             "hl.dsp.window.fullscreen()" },
  { "Hypr",     "SUPER + C",                 "Center Window",                 "hl.dsp.window.center()" },
  { "Hypr",     "SUPER + R",                 "Preset Column Width",           "hl.dsp.layout('colresize')" },
  { "Hypr",     "SUPER + H/J/K/L",           "Move Focus (Vim keys)",         "hl.dsp.focus({ direction = 'left/down/up/right' })" },
  { "Hypr",     "SUPER + SHIFT + H/J/K/L",   "Move Window (Vim keys)",        "hl.dsp.window.move({ direction = 'left/down/up/right' })" },
  { "Hypr",     "CTRL + ALT + Arrows",       "Resize Window (Pixels)",        "hl.dsp.window.resize({ x, y, relative = true })" },
  { "Hypr",     "SUPER + [1-9] / 0",         "Switch to Workspace [1-10]",    "hl.dsp.focus({ workspace = i })" },
  { "Hypr",     "SUPER + SHIFT + [1-9] / 0", "Move Window to Workspace [1-10]", "hl.dsp.window.move({ workspace = i })" },
  { "Hypr",     "SUPER + TAB / SHIFT + TAB", "Next/Prev Workspace",           "hl.dsp.focus({ workspace = 'e+/-1' })" },
  { "Hypr",     "ALT + TAB",                 "Toggle Overview",               "hl.dispatch('toggleoverview')" },
  { "Hypr",     "SUPER + SHIFT + Return",    "Toggle Dropdown Terminal",      "kitty-drop (Scratchpad)" },
  { "Hypr",     "SUPER + F1",                "Toggle btop Monitor",           "btop-scratch (Scratchpad)" },
  { "Hypr",     "SUPER + /",                 "Show Hyprland Cheat Sheet",     "keyhints-scratch (Scratchpad)" },
  { "Hypr",     "CTRL + ALT + Del",          "Exit Hyprland Session",         "hl.dsp.exit()" },

  { "Noctalia", "SUPER + D",                 "App Launcher",                  "noctalia msg panel-toggle launcher" },
  { "Noctalia", "SUPER + V",                 "Clipboard Manager",             "noctalia msg panel-toggle clipboard" },
  { "Noctalia", "SUPER + P",                 "Control Center",                "noctalia msg panel-toggle control-center" },
  { "Noctalia", "SUPER + SHIFT + P",         "Logout Menu",                   "noctalia msg panel-toggle session" },
  { "Noctalia", "SUPER + I",                 "Noctalia Settings",             "noctalia msg settings-toggle" },
  { "Noctalia", "SUPER + SHIFT + N",         "Notification Panel",            "noctalia msg panel-toggle control-center notifications" },
  { "Noctalia", "SUPER + SHIFT + D",         "Active Window Info",            "lua $HOME/.config/hypr/scripts/WindowInfo.lua" },
  { "Noctalia", "CTRL + ALT + L",            "Lock Screen",                   "noctalia msg session lock" },
  { "Noctalia", "SUPER + N",                 "Toggle Night Light",            "noctalia msg nightlight-toggle" },
  { "Noctalia", "SUPER + Y",                 "Toggle Caffeine (No Sleep)",    "noctalia msg caffeine-toggle" },
  { "Noctalia", "SUPER + W",                 "Random Wallpaper",              "noctalia msg wallpaper-random" },
  { "Noctalia", "SUPER + SHIFT + T",         "Toggle Dark/Light Theme",       "noctalia msg theme-mode-toggle" },
  { "Noctalia", "SUPER + F2",                "Toggle Microphone Mute",        "noctalia msg mic-mute" },
  { "Noctalia", "SUPER + Print",             "Screenshot Fullscreen",         "noctalia msg screenshot-fullscreen" },
  { "Noctalia", "SUPER + SHIFT + Print",     "Screenshot Region",             "noctalia msg screenshot-region" },
  { "Noctalia", "ALT + Print",               "Screenshot Active Window",      "noctalia msg screenshot-fullscreen pick" },
  { "Noctalia", "Volume/Brightness Keys",    "Volume/Brightness controls",    "noctalia volume/brightness" },
  { "Noctalia", "Play/Pause/Next/Prev",      "Media controls",                "noctalia msg media toggle/next/prev" },

  { "Term",     "SUPER + Return",            "Open Terminal",                 "kitty" },
  { "Term",     "SUPER + B",                 "Launch Browser",                "firefox" },
  { "Term",     "SUPER + E",                 "File Manager (Yazi)",           "kitty -e yazi" },
  { "Term",     "SUPER + SHIFT + E",         "File Manager (Nautilus)",       "nautilus" },
  { "Term",     "c / q",                     "Clear / Exit",                  "c / q" },
  { "Term",     ".. / ... / ....",           "Navigate Up",                   "cd .. / ... / ...." },
  { "Term",     "ls / ll / la / lt",         "List Files (eza)",              "ls / ll / la / lt" },
  { "Term",     "grep / find",               "ripgrep / fd",                  "rg / fd" },
  { "Term",     "update",                    "System Update (yay)",           "yay -Syu" },
  { "Term",     "install <pkg>",             "Install Package",               "yay -S" },
  { "Term",     "remove <pkg>",              "Remove Package",                "yay -Rns" },
  { "Term",     "search <pkg>",              "Search Package",                "yay -Ss" },
  { "Term",     "make / ninja",              "Parallel Build",                "make -j$(nproc) / ninja -j$(nproc)" },
  { "Term",     "conf-hypr",                 "Edit Hyprland Config",          "nvim ~/.config/hypr/hyprland.lua" },
  { "Term",     "conf-zsh",                  "Edit Zsh Config",               "nvim ~/.config/zsh/.zshrc" },
  { "Term",     "conf-kitty",                "Edit Kitty Config",             "nvim ~/.config/kitty/kitty.conf" },
  { "Term",     "conf-zj",                   "Edit Zellij Config",            "nvim ~/.config/zellij/config.kdl" },
  { "Term",     "reload-zsh",                "Reload Zsh Config",             "source ~/.config/zsh/.zshrc" },
  { "Term",     "g / gst / gd",              "Git Status/Diff",               "git status/diff" },
  { "Term",     "ga / gc / gp / gpl",        "Git Add/Commit/Push/Pull",      "git add/commit/push/pull" },
  { "Term",     "gl / glog / gadog",         "Git Log",                       "git log variants" },
  { "Term",     "zj / zja / zm",             "Zellij Sessions",               "zellij" },
  { "Term",     "zjl / zjda",                "Zellij List/Delete All",        "zellij list/delete" },
  { "Term",     "dk-start / dk-stop",        "Docker Control",                "systemctl docker" },
  { "Term",     "zplu",                      "Update Zsh Plugins",            "zplugin-update" },
  { "Term",     "y",                         "Yazi (preserve cwd)",           "yazi wrapper" }
}

local w1, w2, w3 = 0, 0, 0
for _, item in ipairs(shortcuts) do
    w1 = math.max(w1, #item[1])
    w2 = math.max(w2, #item[2])
    w3 = math.max(w3, #item[3])
end

local lines = {}
local map_action = {}
for _, item in ipairs(shortcuts) do
    local formatted = string.format("%-" .. w1 .. "s   %-" .. w2 .. "s   %-" .. w3 .. "s   %s", item[1], item[2], item[3], item[4])
    table.insert(lines, formatted)
    map_action[formatted] = item[4]
end

local input_str = table.concat(lines, "\n")
local tmp_file = os.tmpname()
local f = io.open(tmp_file, "w")
if f then
    f:write(input_str)
    f:close()
end

local fzf_cmd = 'fzf --header=" [ ENTER: Copiar comando para o clipboard | ESC: Sair ]" --layout=reverse --border=rounded --prompt=" Pesquisar atalho: "'
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
        os.execute(string.format('notify-send "Atalho Copiado" "Comando \'%s\' copiado para o clipboard!" -t 2000 -i edit-copy', action))
    end
end
