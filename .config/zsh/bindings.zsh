# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# Custom keybindings register via zsh-vi-mode hook to survive reset
zvm_after_init() {
  # Ctrl+Right -> move forward one word
  bindkey '^[[1;5C' forward-word
  # Ctrl+Left -> move backward one word
  bindkey '^[[1;5D' backward-word

  # Ctrl+F -> fzf file picker (no hidden files)
  if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
    bindkey '^F' _fzf_file_no_hidden
  fi

  # Ctrl+\ -> toggle autosuggestions
  bindkey '^\' autosuggest-toggle

  # Up/Down -> history search by substring
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}

# Fallback bindings if zsh-vi-mode is not active or hasn't loaded yet
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
  bindkey '^F' _fzf_file_no_hidden
fi
bindkey '^\' autosuggest-toggle
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
