ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

zvm_after_init() {
  bindkey '^[[1;5C' forward-word
  bindkey '^[[1;5D' backward-word

  if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
    bindkey '^F' _fzf_file_no_hidden
  fi

  bindkey '^\' autosuggest-toggle

  bindkey '^R' atuin-search

  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}

bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
  bindkey '^F' _fzf_file_no_hidden
fi
bindkey '^\' autosuggest-toggle
bindkey '^R' atuin-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
