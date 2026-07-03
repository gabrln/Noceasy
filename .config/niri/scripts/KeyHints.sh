#!/usr/bin/env bash

shortcuts=(
  "Niri      ::  SUPER + Return              ::  Open Terminal                 ::  kitty"
  "Niri      ::  SUPER + Q                   ::  Close Window                  ::  niri msg action close-window"
  "Niri      ::  SUPER + SHIFT + Q           ::  Close Window (alt)            ::  niri msg action close-window"
  "Niri      ::  SUPER + Space               ::  Toggle Float                  ::  niri msg action toggle-window-floating"
  "Niri      ::  SUPER + M                   ::  Maximize Column               ::  niri msg action maximize-column"
  "Niri      ::  SUPER + F                   ::  Toggle Fullscreen             ::  niri msg action fullscreen-window"
  "Niri      ::  SUPER + C                   ::  Center Window                 ::  niri msg action center-window"
  "Niri      ::  SUPER + R                   ::  Switch Column Width           ::  niri msg action switch-preset-column-width"
  "Niri      ::  SUPER + SHIFT + R           ::  Reset Window Height           ::  niri msg action reset-window-height"
  "Niri      ::  SUPER + Arrow Keys          ::  Move Focus                    ::  niri msg action focus-column-left/right / focus-window-up/down"
  "Niri      ::  SUPER + SHIFT + Arrow Keys   ::  Move Column/Window            ::  niri msg action move-column-left/right / move-window-up/down"
  "Niri      ::  CTRL + ALT + Arrow Keys     ::  Resize Column/Window          ::  niri msg action set-column-width / set-window-height"
  "Niri      ::  SUPER + [1-9]               ::  Switch to Workspace [1-9]     ::  niri msg action focus-workspace [1-9]"
  "Niri      ::  SUPER + SHIFT + [1-9]       ::  Move Window to Workspace [1-9]::  niri msg action move-window-to-workspace [1-9]"
  "Niri      ::  SUPER + TAB / SHIFT + TAB   ::  Next/Prev Workspace           ::  niri msg action focus-workspace-down/up"
  "Niri      ::  ALT + TAB                   ::  Toggle Preview (Overview)     ::  niri msg action toggle-preview"
  "Niri      ::  SUPER + SHIFT + Return      ::  Toggle Dropdown Terminal      ::  kitty-drop"
  "Niri      ::  SUPER + F1                  ::  Toggle btop Monitor           ::  btop-scratch"
  "Niri      ::  SUPER + H                   ::  Show Niri Cheat Sheet         ::  KeyHints.sh"
  "Niri      ::  CTRL + ALT + Del            ::  Exit Niri Session             ::  niri msg action quit"

  "Noctalia  ::  SUPER + D                  ::  App Launcher                  ::  noctalia msg panel-toggle launcher"
  "Noctalia  ::  SUPER + V                  ::  Clipboard Manager             ::  noctalia msg panel-toggle clipboard"
  "Noctalia  ::  SUPER + P                  ::  Control Center                ::  noctalia msg panel-toggle control-center"
  "Noctalia  ::  SUPER + SHIFT + P          ::  Logout Menu                   ::  noctalia msg panel-toggle session"
  "Noctalia  ::  SUPER + I                  ::  Noctalia Settings             ::  noctalia msg settings-toggle"
  "Noctalia  ::  SUPER + SHIFT + N          ::  Notification Panel            ::  noctalia msg panel-toggle control-center notifications"
  "Noctalia  ::  SUPER + SHIFT + D          ::  Active Window Info            ::  $HOME/.config/niri/scripts/WindowInfo.sh"
  "Noctalia  ::  CTRL + ALT + L             ::  Lock Screen                   ::  noctalia msg session lock"
  "Noctalia  ::  SUPER + N                  ::  Toggle Night Light            ::  noctalia msg nightlight-toggle"
  "Noctalia  ::  SUPER + Y                  ::  Toggle Caffeine (No Sleep)    ::  noctalia msg caffeine-toggle"
  "Noctalia  ::  SUPER + W                  ::  Random Wallpaper              ::  noctalia msg wallpaper-random"
  "Noctalia  ::  SUPER + SHIFT + T          ::  Toggle Dark/Light Theme       ::  noctalia msg theme-mode-toggle"
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
  "Term      ::  conf-niri                  ::  Edit Niri Config              ::  nvim ~/.config/niri/config.kdl"
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
