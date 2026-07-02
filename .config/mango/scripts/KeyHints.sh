#!/usr/bin/env bash

shortcuts=(
  "App Launchers :: SUPER + Return :: Open Terminal :: kitty"
  "App Launchers :: SUPER + B :: Launch Browser :: firefox"
  "App Launchers :: SUPER + E :: File Manager (Yazi) :: kitty -e yazi"
  "App Launchers :: SUPER + D :: App Launcher :: noctalia msg panel-toggle launcher"
  "App Launchers :: SUPER + V :: Clipboard Manager :: noctalia msg panel-toggle clipboard"
  "App Launchers :: SUPER + P :: Control Center / Audio :: noctalia msg panel-toggle session"
  "App Launchers :: SUPER + I :: Noctalia Settings :: noctalia msg settings-toggle"
  "App Launchers :: SUPER + SHIFT + E :: File Manager (Nautilus) :: nautilus"
  "App Launchers :: SUPER + SHIFT + N :: Notification Panel :: noctalia msg panel-toggle control-center notifications"
  "App Launchers :: SUPER + SHIFT + D :: Active Window Info :: $HOME/.config/mango/scripts/WindowInfo.sh"

  "Session Control :: CTRL + ALT + L :: Lock Screen :: noctalia msg session lock"
  "Session Control :: CTRL + ALT + P :: Logout Menu :: noctalia msg panel-toggle session"
  "Session Control :: CTRL + ALT + Del :: Exit MangoWM Session :: mmsg dispatch quit"

  "Window Management :: SUPER + Q :: Close Window :: mmsg dispatch killclient"
  "Window Management :: ALT + F4 :: Force Kill Window (with protection) :: $HOME/.config/mango/scripts/AltF4.sh"
  "Window Management :: SUPER + SHIFT + Q :: Close Window (alt) :: mmsg dispatch killclient"
  "Window Management :: SUPER + F :: Toggle Fullscreen :: mmsg dispatch togglefullscreen"
  "Window Management :: SUPER + M :: Toggle Maximized :: mmsg dispatch togglemaximizescreen"
  "Window Management :: SUPER + Space :: Toggle Float :: mmsg dispatch togglefloating"
  "Window Management :: SUPER + O :: Toggle Overlay (Sticky) :: mmsg dispatch toggleoverlay"
  "Window Management :: SUPER + R :: Reload Config :: mmsg dispatch reload_config"

  "Navigation :: SUPER + Arrow Keys :: Move Focus :: mmsg dispatch focusdir l/r/u/d"
  "Navigation :: SUPER + SHIFT + Arrow Keys :: Move/Swap Window :: mmsg dispatch exchange_client l/r/u/d"
  "Navigation :: CTRL + ALT + Arrow Keys :: Resize Active Window :: mmsg dispatch resizewin"
  "Navigation :: SUPER + [1-0] :: Switch to Tag [1-10] :: mmsg dispatch view [1-10]"
  "Navigation :: SUPER + SHIFT + [1-0] :: Move Window to Tag [1-10] :: mmsg dispatch tag [1-10]"
  "Navigation :: SUPER + TAB / SHIFT + TAB :: Next/Prev Tag :: mmsg dispatch viewtoright/viewtoleft"
  "Navigation :: ALT + TAB :: Toggle Overview (Window Switcher) :: mmsg dispatch toggleoverview"
  "Navigation :: SUPER + J / K :: Focus Next/Prev Stack :: mmsg dispatch focusstack next/prev"
  "Navigation :: SUPER + Mouse Scroll :: Next/Prev Tag :: mmsg dispatch viewtoright/viewtoleft"

  "Noctalia Features :: SUPER + N :: Toggle Night Light :: noctalia msg nightlight-toggle"
  "Noctalia Features :: SUPER + Y :: Toggle Caffeine (No Sleep) :: noctalia msg caffeine-toggle"
  "Noctalia Features :: SUPER + W :: Random Wallpaper :: noctalia msg wallpaper-random"
  "Noctalia Features :: SUPER + SHIFT + T :: Toggle Dark/Light Theme :: noctalia msg theme-mode-toggle"
  "Noctalia Features :: SUPER + SHIFT + B :: Toggle Screen Blur :: $HOME/.config/mango/scripts/ToggleBlur.sh"
  "Noctalia Features :: SUPER + SHIFT + G :: Toggle Gamemode :: $HOME/.config/mango/scripts/ToggleGamemode.sh"
  "Noctalia Features :: SUPER + F2 :: Toggle Microphone Mute :: noctalia msg mic-mute"

  "Scratchpads :: SUPER + SHIFT + Return :: Toggle Dropdown Terminal :: kitty-drop"
  "Scratchpads :: SUPER + F1 :: Toggle btop Monitor :: btop-scratch"
  "Scratchpads :: SUPER + U :: Toggle Special Scratchpad :: toggle_scratchpad"
  "Scratchpads :: SUPER + SHIFT + U :: Send Window to Scratchpad :: mmsg dispatch minimized"

  "Media & Hardware :: SUPER + Print :: Screenshot Fullscreen :: noctalia msg screenshot-fullscreen"
  "Media & Hardware :: SUPER + SHIFT + Print :: Screenshot Region :: noctalia msg screenshot-region"
  "Media & Hardware :: ALT + Print :: Screenshot Active Window :: noctalia msg screenshot-fullscreen pick"
  "Media & Hardware :: Volume/Brightness Keys :: Volume/Brightness controls :: noctalia volume/brightness"
  "Media & Hardware :: Play/Pause/Next/Prev :: Media controls :: noctalia msg media toggle/next/prev"

  "Help Cheatsheets :: SUPER + H :: Show MangoWM Cheat Sheet :: KeyHints.sh"
)

selected=$(printf "%s\n" "${shortcuts[@]}" | column -t -s '::' | \
  fzf --header=" [ ENTER: Copiar comando para o clipboard | ESC: Sair ]" \
      --layout=reverse \
      --border=rounded \
      --prompt=" Pesquisar atalho: ")

if [[ -n "$selected" ]]; then
  selected_trimmed=$(echo "$selected" | xargs)

  for item in "${shortcuts[@]}"; do
    item_formatted=$(echo "$item" | sed 's/ :: /   /g' | xargs)
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
