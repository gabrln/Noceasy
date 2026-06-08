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
    "SUPER + Space" "App Launcher" "Noctalia launcher" \
    "SUPER + V" "Clipboard Manager" "Noctalia clipboard" \
    "SUPER + P" "Control Center / Audio" "Noctalia CC" \
    "SUPER + L" "Lock screen" "Noctalia lock screen" \
    "SUPER + CTRL + L" "Session Logout Menu" "Noctalia Logout" \
    "SUPER + Q / ALT + F4" "Close active window" "close" \
    "SUPER + SHIFT + Q" "Terminate active window" "kill" \
    "" "" "" \
    "SUPER + F" "Fullscreen" "Toggle fullscreen" \
    "SUPER + M" "Maximize" "Toggle maximized" \
    "SUPER + SHIFT + F" "Float Toggle" "Toggle floating window" \
    "SUPER + O" "Float & Pin Window" "Float + Pin window" \
    "SUPER + J" "Toggle Split" "togglesplit" \
    "SUPER + G" "Toggle Group (Tabs)" "togglesgroup" \
    "SUPER + [ / ]" "Cycle Group Windows" "prev / next tab" \
    "SUPER + SHIFT + G" "Lock Group" "lock active group" \
    "" "" "" \
    "SUPER + Left/Right/Up/Down" "Focus Window" "movefocus" \
    "SUPER + SHIFT + Left/Right/Up/Down" "Move Window" "movewindow" \
    "SUPER + [0-9]" "Focus Workspace [1-10]" "workspace [1-10]" \
    "SUPER + SHIFT + [0-9]" "Move Window to Workspace" "movetoworkspace" \
    "SUPER + CTRL + [0-9]" "Move Window Silently to Workspace" "movetoworkspacesilent" \
    "SUPER + TAB / SHIFT + TAB" "Next / Prev Workspace" "workspace e+/-1" \
    "SUPER + Mouse Scroll" "Next / Prev Workspace" "workspace e+/-1" \
    "" "" "" \
    "SUPER + N" "Toggle Night Light (Azul)" "Noctalia nightlight" \
    "SUPER + Y" "Toggle Caffeine (Idle Inhibitor)" "Noctalia caffeine" \
    "SUPER + W" "Random Wallpaper" "Noctalia wallpaper" \
    "SUPER + SHIFT + T" "Toggle Dark/Light Theme" "Noctalia theme" \
    "" "" "" \
    "SUPER + = / -" "Resize Width (+/- 50)" "resize width" \
    "SUPER + SHIFT + = / -" "Resize Height (+/- 50)" "resize height" \
    "SUPER + ALT + Arrow keys" "Resize Window" "resizeactive" \
    "" "" "" \
    "SUPER + SHIFT + L" "Toggle Layout" "Dwindle / Scrolling" \
    "SUPER + period" "Move window to col (scrolling)" "move +col" \
    "SUPER + comma" "Swap column (scrolling)" "swapcol l" \
    "SUPER + SHIFT + period" "Resize column + (scrolling)" "colresize +conf" \
    "SUPER + SHIFT + comma" "Resize column - (scrolling)" "colresize -conf" \
    "SUPER + C" "Center View (scrolling)" "centerview" \
    "SUPER + SHIFT + X" "Consume/Expel window (scrolling)" "consume_or_expel" \
    "" "" "" \
    "SUPER + T" "Toggle Dropdown Terminal" "kitty-drop" \
    "SUPER + F1" "Toggle btop" "btop-scratch" \
    "SUPER + S" "Toggle special workspace" "special:magic" \
    "SUPER + SHIFT + S" "Move window to special workspace" "special:magic" \
    "" "" "" \
    "SUPER + Print" "Screenshot Region" "Noctalia screenshot" \
    "SUPER + SHIFT + Print" "Screenshot Fullscreen" "Noctalia screenshot" \
    "Volume / Brightness Keys" "Media Controls" "Noctalia volume/brightness" \
    "Media Play / Pause / Next / Prev" "Media Playback" "Noctalia media" \
    "SUPER + F2" "Toggle Microphone Mute" "Noctalia mic-mute" \
    "SUPER + H" "Show this Cheat Sheet" "KeyHints.sh"
