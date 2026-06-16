#!/usr/bin/env bash
# /* ---- Custom Keybinds Cheat Sheet ---- */

# Toggle behavior: if yad is already running, kill it and exit
if pidof yad > /dev/null; then
  pkill yad
  exit 0
fi

# Use YAD with name yad-keyhints to match Hyprland window rules
yad --center \
    --name="yad-keyhints" \
    --title="Noctalia & Hyprland Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column="Key:" \
    --column="Description:" \
    --column="Command:" \
    --width=1000 --height=650 \
    "ESC" "Close this Cheat Sheet" "" \
    "SUPER KEY" "Main Modifier" "(Windows Key)" \
    "" "" "" \
    "SUPER + Return" "Open Terminal" "kitty" \
    "SUPER + B" "Launch Browser" "firefox" \
    "SUPER + E" "File Manager" "kitty -e yazi" \
    "SUPER + D" "App Launcher" "Noctalia launcher" \
    "SUPER + V" "Clipboard Manager" "Noctalia clipboard" \
    "SUPER + P" "Control Center / Audio" "Noctalia CC" \
    "SUPER + SHIFT + E" "Noctalia Settings" "Noctalia Settings" \
    "SUPER + SHIFT + N" "Notification Panel" "Noctalia Notifications" \
    "SUPER + SHIFT + D" "Window Info (Active)" "WindowInfo.sh" \
    "CTRL + ALT + L" "Lock screen" "Noctalia lock screen" \
    "CTRL + ALT + P" "Session Logout Menu" "Noctalia Logout" \
    "CTRL + ALT + Del" "Exit Hyprland Session" "exit" \
    "SUPER + Q / ALT + F4" "Close active window" "close" \
    "SUPER + SHIFT + Q" "Terminate active window" "kill" \
    "" "" "" \
    "SUPER + SHIFT + F" "Fullscreen" "Toggle fullscreen" \
    "SUPER + M" "Maximize" "Toggle maximized" \
    "SUPER + Space" "Float Toggle" "Toggle floating window" \
    "SUPER + ALT + Space" "Float All Windows" "float all" \
    "SUPER + O" "Float & Pin Window" "Float + Pin window" \
    "SUPER + SHIFT + I" "Toggle Split" "togglesplit" \
    "SUPER + G" "Toggle Group (Tabs)" "togglesgroup" \
    "SUPER + [ / ]" "Cycle Group Windows" "prev / next tab" \
    "SUPER + CTRL + G" "Lock Group" "lock active group" \
    "" "" "" \
    "SUPER + Left/Right/Up/Down" "Focus Window" "movefocus" \
    "SUPER + SHIFT + Left/Right/Up/Down" "Resize Window" "resize" \
    "SUPER + CTRL + Left/Right/Up/Down" "Move Window" "movewindow" \
    "SUPER + [0-9]" "Focus Workspace [1-10]" "workspace [1-10]" \
    "SUPER + SHIFT + [0-9]" "Move Window to Workspace" "movetoworkspace" \
    "SUPER + CTRL + [0-9]" "Move Window Silently to Workspace" "movetoworkspacesilent" \
    "SUPER + TAB / SHIFT + TAB" "Next / Prev Workspace" "workspace e+/-1" \
    "SUPER + Mouse Scroll" "Next / Prev Workspace" "workspace e+/-1" \
    "ALT + TAB" "Window Switcher" "Snappy Switcher" \
    "" "" "" \
    "SUPER + N" "Toggle Night Light (Azul)" "Noctalia nightlight" \
    "SUPER + Y" "Toggle Caffeine (Idle Inhibitor)" "Noctalia caffeine" \
    "SUPER + W" "Random Wallpaper" "Noctalia wallpaper" \
    "SUPER + SHIFT + T" "Toggle Dark/Light Theme" "Noctalia theme" \
    "SUPER + ALT + O" "Toggle Blur" "toggle blur" \
    "SUPER + SHIFT + G" "Toggle Gamemode" "toggle animations" \
    "SUPER + CTRL + O" "Toggle Opacity" "toggle opaque" \
    "" "" "" \
    "SUPER + = / -" "Resize Width (+/- 50)" "resize width" \
    "SUPER + SHIFT + = / -" "Resize Height (+/- 50)" "resize height" \
    "SUPER + ALT + Arrow keys" "Resize Window" "resizeactive" \
    "" "" "" \
    "SUPER + ALT + L" "Toggle Layout" "Dwindle / Scrolling" \
    "SUPER + period" "Move window to col (scrolling)" "move +col" \
    "SUPER + comma" "Swap column (scrolling)" "swapcol l" \
    "SUPER + SHIFT + period" "Resize column + (scrolling)" "colresize +conf" \
    "SUPER + SHIFT + comma" "Resize column - (scrolling)" "colresize -conf" \
    "SUPER + C" "Center View (scrolling)" "centerview" \
    "SUPER + SHIFT + X" "Consume/Expel window (scrolling)" "consume_or_expel" \
    "" "" "" \
    "SUPER + SHIFT + Enter" "Toggle Dropdown Terminal" "kitty-drop" \
    "SUPER + F1" "Toggle btop" "btop-scratch" \
    "SUPER + U" "Toggle special workspace" "special:magic" \
    "SUPER + SHIFT + U" "Move window to special workspace" "special:magic" \
    "" "" "" \
    "SUPER + Print" "Screenshot Fullscreen" "Noctalia screenshot" \
    "SUPER + SHIFT + Print" "Screenshot Region" "Noctalia screenshot" \
    "ALT + Print" "Screenshot Active Window" "Noctalia screenshot" \
    "Volume / Brightness Keys" "Media Controls" "Noctalia volume/brightness" \
    "Media Play / Pause / Next / Prev" "Media Playback" "Noctalia media" \
    "SUPER + F2" "Toggle Microphone Mute" "Noctalia mic-mute" \
    "SUPER + H" "Show Hyprland Cheat Sheet" "KeyHints.sh" \
    "SUPER + SHIFT + H" "Show Zsh/Nix Cheat Sheet" "AliasHints.sh"
