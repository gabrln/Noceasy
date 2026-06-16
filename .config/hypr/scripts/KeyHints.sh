#!/usr/bin/env bash
# /* ---- Custom Keybinds Cheat Sheet using FZF ---- */

# Toggle behavior: if fzf keyhints terminal is already running, we don't spawn another
# (Hyprland handles focusing, but this is a safeguard)

# Define shortcuts array
shortcuts=(
  "App Launchers :: SUPER + Return :: Open Terminal :: kitty"
  "App Launchers :: SUPER + B :: Launch Browser :: firefox"
  "App Launchers :: SUPER + E :: File Manager (Yazi) :: kitty -e yazi"
  "App Launchers :: SUPER + D :: App Launcher :: noctalia msg panel-toggle launcher"
  "App Launchers :: SUPER + V :: Clipboard Manager :: noctalia msg panel-toggle clipboard"
  "App Launchers :: SUPER + P :: Control Center / Audio :: noctalia msg panel-toggle session"
  "App Launchers :: SUPER + SHIFT + E :: Noctalia Settings :: noctalia msg settings-toggle"
  "App Launchers :: SUPER + SHIFT + N :: Notification Panel :: noctalia msg panel-toggle control-center notifications"
  "App Launchers :: SUPER + SHIFT + D :: Active Window Info :: /home/gsouza/.config/hypr/scripts/WindowInfo.sh"
  
  "Session Control :: CTRL + ALT + L :: Lock Screen :: noctalia msg session lock"
  "Session Control :: CTRL + ALT + P :: Logout Menu :: noctalia msg panel-toggle session"
  "Session Control :: CTRL + ALT + Del :: Exit Hyprland Session :: hyprctl dispatch exit"
  
  "Window Management :: SUPER + Q :: Close Window :: hyprctl dispatch closewindow"
  "Window Management :: ALT + F4 :: Force Kill Window (with protection) :: kill -9 <PID>"
  "Window Management :: SUPER + SHIFT + Q :: Terminate Connection (Client Kill) :: hyprctl dispatch killactive"
  "Window Management :: SUPER + SHIFT + F :: Toggle Fullscreen :: hyprctl dispatch fullscreen 0"
  "Window Management :: SUPER + M :: Toggle Maximized :: hyprctl dispatch fullscreen 1"
  "Window Management :: SUPER + Space :: Toggle Float :: hyprctl dispatch togglefloating"
  "Window Management :: SUPER + ALT + Space :: Float All Windows in Workspace :: float all windows"
  "Window Management :: SUPER + O :: Float & Pin Window (Sticky) :: hyprctl dispatch pin"
  "Window Management :: SUPER + SHIFT + I :: Toggle Split Layout :: hyprctl dispatch togglesplit"
  "Window Management :: SUPER + G :: Toggle Window Group (Tabs) :: hyprctl dispatch togglegroup"
  "Window Management :: SUPER + [ or ] :: Cycle Group Windows :: hyprctl dispatch changegroupactive f/b"
  "Window Management :: SUPER + CTRL + G :: Lock Group :: hyprctl dispatch lockactivegroup toggle"
  
  "Scrolling Layout :: SUPER + ALT + L :: Toggle Dwindle / Scrolling Layout :: toggle layout"
  "Scrolling Layout :: SUPER + Comma (,) :: Move Camera Left (Focus Prev Col) :: hyprctl dispatch layoutmsg move -col"
  "Scrolling Layout :: SUPER + Period (.) :: Move Camera Right (Focus Next Col) :: hyprctl dispatch layoutmsg move +col"
  "Scrolling Layout :: SUPER + SHIFT + Comma (,) :: Swap Column Left :: hyprctl dispatch layoutmsg swapcol l"
  "Scrolling Layout :: SUPER + SHIFT + Period (.) :: Swap Column Right :: hyprctl dispatch layoutmsg swapcol r"
  "Scrolling Layout :: SUPER + ALT + Comma (,) :: Decrease Column Width :: hyprctl dispatch layoutmsg colresize -conf"
  "Scrolling Layout :: SUPER + ALT + Period (.) :: Increase Column Width :: hyprctl dispatch layoutmsg colresize +conf"
  "Scrolling Layout :: SUPER + C :: Fit/Center Active Column :: hyprctl dispatch layoutmsg fit active"
  "Scrolling Layout :: SUPER + SHIFT + X :: Consume or Expel Window :: hyprctl dispatch layoutmsg consume_or_expel next"
  "Scrolling Layout :: SUPER + SHIFT + P :: Promote Window to New Column :: hyprctl dispatch layoutmsg promote"
  
  "Navigation :: SUPER + Arrow Keys :: Move Focus :: hyprctl dispatch movefocus l/r/u/d"
  "Navigation :: SUPER + SHIFT + Arrow Keys :: Resize Active Window :: hyprctl dispatch resizeactive"
  "Navigation :: SUPER + CTRL + Arrow Keys :: Move Window :: hyprctl dispatch movewindow l/r/u/d"
  "Navigation :: SUPER + [0-9] :: Switch to Workspace [1-10] :: hyprctl dispatch workspace [1-10]"
  "Navigation :: SUPER + SHIFT + [0-9] :: Move Window to Workspace :: hyprctl dispatch movetoworkspace [1-10]"
  "Navigation :: SUPER + CTRL + [0-9] :: Move Window Silently to Workspace :: hyprctl dispatch movetoworkspacesilent [1-10]"
  "Navigation :: SUPER + TAB / SHIFT + TAB :: Next/Prev Workspace :: hyprctl dispatch workspace e+/-1"
  "Navigation :: SUPER + Mouse Scroll :: Next/Prev Workspace :: hyprctl dispatch workspace e+/-1"
  "Navigation :: ALT + TAB :: Window Switcher :: snappy-switcher"
  
  "Noctalia Features :: SUPER + N :: Toggle Night Light :: noctalia msg nightlight-toggle"
  "Noctalia Features :: SUPER + Y :: Toggle Caffeine (No Sleep) :: noctalia msg caffeine-toggle"
  "Noctalia Features :: SUPER + W :: Random Wallpaper :: noctalia msg wallpaper-random"
  "Noctalia Features :: SUPER + SHIFT + T :: Toggle Dark/Light Theme :: noctalia msg theme-mode-toggle"
  "Noctalia Features :: SUPER + ALT + O :: Toggle Screen Blur :: toggle blur"
  "Noctalia Features :: SUPER + SHIFT + G :: Toggle Gamemode :: toggle animations & gaps"
  "Noctalia Features :: SUPER + CTRL + O :: Toggle Active Window Opacity :: hyprctl dispatch toggleopaque"
  
  "Scratchpads :: SUPER + SHIFT + Enter :: Toggle Dropdown Terminal :: kitty-drop"
  "Scratchpads :: SUPER + F1 :: Toggle btop Monitor :: btop-scratch"
  "Scratchpads :: SUPER + U :: Toggle Special Workspace :: hyprctl dispatch togglespecialworkspace magic"
  "Scratchpads :: SUPER + SHIFT + U :: Move Window to Special Workspace :: hyprctl dispatch movetoworkspace special:magic"
  
  "Media & Hardware :: SUPER + Print :: Screenshot Fullscreen :: noctalia msg screenshot-fullscreen"
  "Media & Hardware :: SUPER + SHIFT + Print :: Screenshot Region :: noctalia msg screenshot-region"
  "Media & Hardware :: ALT + Print :: Screenshot Active Window :: noctalia msg screenshot-fullscreen pick"
  "Media & Hardware :: Volume/Brightness Keys :: Volume/Brightness controls :: noctalia volume/brightness"
  "Media & Hardware :: Play/Pause/Next/Prev :: Media controls :: noctalia msg media toggle/next/prev"
  "Media & Hardware :: SUPER + F2 :: Toggle Microphone Mute :: noctalia msg mic-mute"
  
  "Help Cheatsheets :: SUPER + H :: Show Hyprland Cheat Sheet :: KeyHints.sh"
  "Help Cheatsheets :: SUPER + SHIFT + H :: Show Zsh/Nix Cheat Sheet :: AliasHints.sh"
)

# Pipe array through column formatting and into FZF
# FZF will hide the Action field but return it on selection
selected=$(printf "%s\n" "${shortcuts[@]}" | column -t -s '::' | \
  fzf --header=" [ ENTER: Copiar comando para o clipboard | ESC: Sair ]" \
      --layout=reverse \
      --border=rounded \
      --prompt="🔍 Pesquisar atalho: ")

if [[ -n "$selected" ]]; then
  # Parse the selected line to find the original shortcut item to extract the action
  # We do this by searching for the matching category/shortcut/description in our original array
  # Extract the text without leading/trailing whitespace
  selected_trimmed=$(echo "$selected" | xargs)
  
  for item in "${shortcuts[@]}"; do
    # Format the item the same way column does to find the match
    item_formatted=$(echo "$item" | sed 's/ :: /   /g' | xargs)
    # Check if the prefix matches
    if [[ "$selected_trimmed" == "$item_formatted"* ]]; then
      action=$(echo "$item" | awk -F ' :: ' '{print $4}')
      if [[ -n "$action" ]]; then
        echo -n "$action" | wl-copy
        notify-send "Atalho Copiado" "Comando '$action' copiado para o clipboard!" -t 2000 -i edit-copy
      fi
      break
    fi
  done
fi
