#!/usr/bin/env lua
-- KeyHints.lua - Hyprland Cheat Sheet & Shortcut Launcher in Lua

local shortcuts = {
  -- Janelas & Workspaces
  { "SUPER + T",                 "Open Terminal (Kitty)",               "kitty" },
  { "SUPER + Q",                 "Close Window",                        "hl.dsp.window.close()" },
  { "ALT + F4",                  "Close/Kill Window Safely",            "lua $HOME/.config/hypr/scripts/AltF4.lua" },
  { "SUPER + Space",             "Toggle Float",                        "hl.dsp.window.float({ action = 'toggle' })" },
  { "SUPER + ALT + Space",       "Pin Floating Window (All Workspaces)","hl.dsp.window.pin({ action = 'toggle' })" },
  { "SUPER + M",                 "Fit Active Window (Maximize)",        "hl.dsp.layout('fit active')" },
  { "SUPER + F",                 "Toggle Fullscreen",                   "hl.dsp.window.fullscreen()" },
  { "SUPER + C",                 "Center Window",                       "hl.dsp.window.center()" },
  { "SUPER + R",                 "Preset Column Width",                 "hl.dsp.layout('colresize')" },
  { "SUPER + G",                 "Toggle Window Group (Tabbed Mode)",   "hyprctl dispatch togglegroup" },
  { "SUPER + ALT + H / L",       "Change Group Tab (Prev / Next)",      "hyprctl dispatch changegroupactive b/f" },
  { "SUPER + . / ,",             "Move Scrolling Column Right / Left",  "hl.dsp.layout('move +/-col')" },
  { "SUPER + SHIFT + . / ,",     "Swap Scrolling Column Right / Left",  "hl.dsp.layout('swapcol r/l')" },
  { "SUPER + H / J / K / L",     "Move Focus (Vim keys)",               "hl.dsp.focus({ direction = 'left/down/up/right' })" },
  { "SUPER + SHIFT + H/J/K/L",   "Move Window (Vim keys)",              "hl.dsp.window.move({ direction = 'left/down/up/right' })" },
  { "CTRL + ALT + Arrows",       "Resize Window (Pixels)",              "hl.dsp.window.resize({ x, y, relative = true })" },
  { "SUPER + [1-9] / 0",         "Switch to Workspace [1-10]",          "hl.dsp.focus({ workspace = i })" },
  { "SUPER + SHIFT + [1-9] / 0", "Move Window to Workspace [1-10]",     "hl.dsp.window.move({ workspace = i })" },
  { "SUPER + TAB / ALT + TAB",   "Toggle Overview (Scrolloverview)",    "toggle_overview" },
  { "SUPER + SHIFT + TAB",       "Previous Workspace",                  "hl.dsp.focus({ workspace = 'e-1' })" },
  { "SUPER + SHIFT + T",         "Toggle Dropdown Terminal",            "kitty-drop (Scratchpad)" },
  { "SUPER + F1",                "Toggle btop Monitor",                 "btop-scratch (Scratchpad)" },
  { "SUPER + /",                 "Show Hyprland Cheat Sheet",           "keyhints-scratch (Scratchpad)" },
  { "CTRL + ALT + Del",          "Exit Hyprland Session",               "hl.dsp.exit()" },

  -- Noctalia Desktop Shell
  { "SUPER + D",                 "App Launcher",                        "noctalia msg panel-toggle launcher" },
  { "SUPER + V",                 "Clipboard Manager",                   "noctalia msg panel-toggle clipboard" },
  { "SUPER + P",                 "Control Center",                      "noctalia msg panel-toggle control-center" },
  { "SUPER + SHIFT + P",         "Logout / Session Menu",               "noctalia msg panel-toggle session" },
  { "SUPER + I",                 "Noctalia Settings",                   "noctalia msg settings-toggle" },
  { "SUPER + SHIFT + N",         "Notification Panel",                  "noctalia msg panel-toggle control-center notifications" },
  { "SUPER + SHIFT + D",         "Active Window Info",                  "lua $HOME/.config/hypr/scripts/WindowInfo.lua" },
  { "CTRL + ALT + L",            "Lock Screen",                         "noctalia msg session lock" },
  { "SUPER + N",                 "Toggle Night Light",                  "noctalia msg nightlight-toggle" },
  { "SUPER + Y",                 "Toggle Caffeine (No Sleep)",          "noctalia msg caffeine-toggle" },
  { "SUPER + W",                 "Random Wallpaper",                    "noctalia msg wallpaper-random" },
  { "SUPER + SHIFT + W",         "Toggle Dark / Light Theme",           "noctalia msg theme-mode-toggle" },
  { "SUPER + F2",                "Toggle Microphone Mute",              "noctalia msg mic-mute" },
  { "SUPER + Print",             "Screenshot Fullscreen",               "noctalia msg screenshot-fullscreen" },
  { "SUPER + SHIFT + Print",     "Screenshot Region",                   "noctalia msg screenshot-region" },
  { "ALT + Print",               "Screenshot Active Window",            "noctalia msg screenshot-fullscreen pick" },
  { "Volume / Brightness Keys",  "Volume / Brightness Controls",        "noctalia volume/brightness" },
  { "Media Keys",                "Play / Pause / Next / Prev",          "noctalia msg media toggle/next/prev" },

  -- Terminal & Comandos Rápidos
  { "SUPER + B",                 "Launch Browser (Firefox)",            "firefox" },
  { "SUPER + E",                 "File Manager (Yazi TUI)",             "kitty -e yazi" },
  { "SUPER + SHIFT + E",         "File Manager (Nautilus GUI)",         "nautilus" },
  { "c / q",                     "Clear / Exit Terminal",               "c / q" },
  { ".. / ... / ....",           "Navigate Up Directory",               "cd .. / ... / ...." },
  { "ls / ll / la / lt",         "List Files (eza)",                    "ls / ll / la / lt" },
  { "grep / find",               "ripgrep / fd Search",                 "rg / fd" },
  { "update",                    "System Update (yay)",                 "yay -Syu" },
  { "install <pkg>",             "Install Package",                     "yay -S" },
  { "remove <pkg>",              "Remove Package",                      "yay -Rns" },
  { "search <pkg>",              "Search Package",                      "yay -Ss" },
  { "make / ninja",              "Parallel Build",                      "make -j$(nproc) / ninja -j$(nproc)" },
  { "conf-hypr",                 "Edit Hyprland Config",                "nvim ~/.config/hypr/hyprland.lua" },
  { "conf-zsh",                  "Edit Zsh Config",                     "nvim ~/.config/zsh/.zshrc" },
  { "conf-kitty",                "Edit Kitty Config",                   "nvim ~/.config/kitty/kitty.conf" },
  { "conf-zj",                   "Edit Zellij Config",                  "nvim ~/.config/zellij/config.kdl" },
  { "reload-zsh",                "Reload Zsh Config",                   "source ~/.config/zsh/.zshrc" },
  { "g / gst / gd",              "Git Status / Diff",                   "git status/diff" },
  { "ga / gc / gp / gpl",        "Git Add / Commit / Push / Pull",      "git add/commit/push/pull" },
  { "gl / glog / gadog",         "Git Log Variants",                    "git log" },
  { "zj / zja / zm",             "Zellij Sessions",                     "zellij" },
  { "zjl / zjda",                "Zellij List / Delete All",            "zellij list/delete" },
  { "dk-start / dk-stop",        "Docker Control",                      "systemctl docker" },
  { "zplu",                      "Update Zsh Plugins",                  "zplugin-update" },
  { "y",                         "Yazi Wrapper (Preserve CWD)",         "y" }
}

local w1 = 0
for _, item in ipairs(shortcuts) do
    w1 = math.max(w1, #item[1])
end

local lines = {}
local map_action = {}
for _, item in ipairs(shortcuts) do
    local formatted = string.format("%-" .. (w1 + 4) .. "s   %s", item[1], item[2])
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
