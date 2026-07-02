#!/usr/bin/env bash

shortcuts=(
  "Mango     ::  SUPER + Return              ::  Open Terminal                 ::  kitty"
  "Mango     ::  SUPER + Q                   ::  Close Window                  ::  mmsg dispatch killclient"
  "Mango     ::  ALT + F4                    ::  Force Kill Window             ::  $HOME/.config/mango/scripts/AltF4.sh"
  "Mango     ::  SUPER + SHIFT + Q           ::  Close Window (alt)            ::  mmsg dispatch killclient"
  "Mango     ::  SUPER + F                   ::  Toggle Fullscreen             ::  mmsg dispatch togglefullscreen"
  "Mango     ::  SUPER + M                   ::  Toggle Maximized              ::  mmsg dispatch togglemaximizescreen"
  "Mango     ::  SUPER + Space               ::  Toggle Float                  ::  mmsg dispatch togglefloating"
  "Mango     ::  SUPER + O                   ::  Toggle Overlay (Sticky)       ::  mmsg dispatch toggleoverlay"
  "Mango     ::  SUPER + R                   ::  Reload Config                 ::  mmsg dispatch reload_config"
  "Mango     ::  SUPER + Arrow Keys          ::  Move Focus                    ::  mmsg dispatch focusdir l/r/u/d"
  "Mango     ::  SUPER + SHIFT + Arrow Keys   ::  Move/Swap Window              ::  mmsg dispatch exchange_client l/r/u/d"
  "Mango     ::  CTRL + ALT + Arrow Keys     ::  Resize Active Window          ::  mmsg dispatch resizewin"
  "Mango     ::  SUPER + [1-0]               ::  Switch to Tag [1-10]          ::  mmsg dispatch view [1-10]"
  "Mango     ::  SUPER + SHIFT + [1-0]       ::  Move Window to Tag [1-10]     ::  mmsg dispatch tag [1-10]"
  "Mango     ::  SUPER + TAB / SHIFT + TAB   ::  Next/Prev Tag                 ::  mmsg dispatch viewtoright/viewtoleft"
  "Mango     ::  ALT + TAB                   ::  Toggle Overview               ::  mmsg dispatch toggleoverview"
  "Mango     ::  SUPER + J / K               ::  Focus Next/Prev Stack         ::  mmsg dispatch focusstack next/prev"
  "Mango     ::  SUPER + Mouse Scroll        ::  Next/Prev Tag                 ::  mmsg dispatch viewtoright/viewtoleft"
  "Mango     ::  SUPER + SHIFT + Return      ::  Toggle Dropdown Terminal      ::  kitty-drop"
  "Mango     ::  SUPER + F1                  ::  Toggle btop Monitor           ::  btop-scratch"
  "Mango     ::  SUPER + U                   ::  Toggle Special Scratchpad     ::  toggle_scratchpad"
  "Mango     ::  SUPER + SHIFT + U           ::  Send Window to Scratchpad     ::  mmsg dispatch minimized"
  "Mango     ::  SUPER + CTRL + U            ::  Restore Minimized             ::  mmsg dispatch restore_minimized"
  "Mango     ::  ALT + E                     ::  Set Proportion 1.0            ::  mmsg dispatch set_proportion 1.0"
  "Mango     ::  ALT + X                     ::  Switch Proportion Preset      ::  mmsg dispatch switch_proportion_preset"
  "Mango     ::  SUPER + Left Click          ::  Move Window                   ::  moveresize curmove"
  "Mango     ::  SUPER + Right Click         ::  Resize Window                 ::  moveresize curresize"
  "Mango     ::  SUPER + Scroll Up           ::  Previous Tag                  ::  viewtoleft_have_client"
  "Mango     ::  SUPER + Scroll Down         ::  Next Tag                      ::  viewtoright_have_client"
  "Mango     ::  SUPER + H                   ::  Show MangoWM Cheat Sheet      ::  KeyHints.sh"
  "Mango     ::  CTRL + ALT + Del            ::  Exit MangoWM Session          ::  mmsg dispatch quit"

  "Noctalia  ::  SUPER + D                  ::  App Launcher                  ::  noctalia msg panel-toggle launcher"
  "Noctalia  ::  SUPER + V                  ::  Clipboard Manager             ::  noctalia msg panel-toggle clipboard"
  "Noctalia  ::  SUPER + P                  ::  Control Center / Audio        ::  noctalia msg panel-toggle control-center"
  "Noctalia  ::  SUPER + SHIFT + P          ::  Logout Menu                   ::  noctalia msg panel-toggle session"
  "Noctalia  ::  SUPER + I                  ::  Noctalia Settings             ::  noctalia msg settings-toggle"
  "Noctalia  ::  SUPER + SHIFT + N          ::  Notification Panel            ::  noctalia msg panel-toggle control-center notifications"
  "Noctalia  ::  SUPER + SHIFT + D          ::  Active Window Info            ::  $HOME/.config/mango/scripts/WindowInfo.sh"
  "Noctalia  ::  CTRL + ALT + L             ::  Lock Screen                   ::  noctalia msg session lock"
  "Noctalia  ::  SUPER + N                  ::  Toggle Night Light            ::  noctalia msg nightlight-toggle"
  "Noctalia  ::  SUPER + Y                  ::  Toggle Caffeine (No Sleep)    ::  noctalia msg caffeine-toggle"
  "Noctalia  ::  SUPER + W                  ::  Random Wallpaper              ::  noctalia msg wallpaper-random"
  "Noctalia  ::  SUPER + SHIFT + T          ::  Toggle Dark/Light Theme       ::  noctalia msg theme-mode-toggle"
  "Noctalia  ::  SUPER + SHIFT + B          ::  Toggle Screen Blur            ::  $HOME/.config/mango/scripts/ToggleBlur.sh"
  "Noctalia  ::  SUPER + SHIFT + G          ::  Toggle Gamemode               ::  $HOME/.config/mango/scripts/ToggleGamemode.sh"
  "Noctalia  ::  SUPER + F2                 ::  Toggle Microphone Mute        ::  noctalia msg mic-mute"
  "Noctalia  ::  SUPER + Print              ::  Screenshot Fullscreen         ::  noctalia msg screenshot-fullscreen"
  "Noctalia  ::  SUPER + SHIFT + Print      ::  Screenshot Region             ::  noctalia msg screenshot-region"
  "Noctalia  ::  ALT + Print                ::  Screenshot Active Window      ::  noctalia msg screenshot-fullscreen pick"
  "Noctalia  ::  Volume/Brightness Keys     ::  Volume/Brightness controls    ::  noctalia volume/brightness"
  "Noctalia  ::  Play/Pause/Next/Prev       ::  Media controls                ::  noctalia msg media toggle/next/prev"

  "Term      ::  SUPER + Return             ::  Open Terminal                 ::  kitty"
  "Term      ::  SUPER + B                  ::  Launch Browser                ::  firefox"
  "Term      ::  SUPER + E                  ::  File Manager (Yazi)           ::  kitty -e yazi"
  "Term      ::  SUPER + SHIFT + E          ::  File Manager (Nautilus)       ::  nautilus"
  "Term      ::  c / q                      ::  Clear / Exit                  ::  c / q"
  "Term      ::  .. / ... / ....            ::  Navigate Up                    ::  cd .. / ... / ...."
  "Term      ::  ls / ll / la / lt          ::  List Files (eza)              ::  ls / ll / la / lt"
  "Term      ::  grep / find                ::  ripgrep / fd                  ::  rg / fd"
  "Term      ::  update                     ::  System Update (yay)            ::  yay -Syu"
  "Term      ::  install <pkg>              ::  Install Package               ::  yay -S"
  "Term      ::  remove <pkg>               ::  Remove Package                ::  yay -Rns"
  "Term      ::  search <pkg>               ::  Search Package                ::  yay -Ss"
  "Term      ::  make / ninja               ::  Parallel Build                ::  make -j\$(nproc) / ninja -j\$(nproc)"
  "Term      ::  conf-mango                 ::  Edit Mango Config             ::  nvim ~/.config/mango/config.conf"
  "Term      ::  conf-zsh                   ::  Edit Zsh Config               ::  nvim ~/.config/zsh/.zshrc"
  "Term      ::  conf-kitty                 ::  Edit Kitty Config             ::  nvim ~/.config/kitty/kitty.conf"
  "Term      ::  conf-zj                    ::  Edit Zellij Config            ::  nvim ~/.config/zellij/config.kdl"
  "Term      ::  reload-zsh                 ::  Reload Zsh Config             ::  source ~/.config/zsh/.zshrc"
  "Term      ::  g / gst / gd               ::  Git Status/Diff               ::  git status/diff"
  "Term      ::  ga / gc / gp / gpl         ::  Git Add/Commit/Push/Pull      ::  git add/commit/push/pull"
  "Term      ::  gl / glog / gadog          ::  Git Log                       ::  git log variants"
  "Term      ::  zj / zja / zm              ::  Zellij Sessions               ::  zellij"
  "Term      ::  zjl / zjda                 ::  Zellij List/Delete All        ::  zellij list/delete"
  "Term      ::  dk-start / dk-stop         ::  Docker Control                ::  systemctl docker"
  "Term      ::  zplu                       ::  Update Zsh Plugins            ::  zplugin-update"
  "Term      ::  y                          ::  Yazi (preserve cwd)           ::  yazi wrapper"
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
