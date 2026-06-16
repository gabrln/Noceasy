# =========================================================
# fzf configuration
# =========================================================

# Check if fd, fzf, and bat are available
if command -v fzf &>/dev/null && command -v fd &>/dev/null; then
  # Use fd as backend
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

  # Styling & Layout
  export FZF_DEFAULT_OPTS='
    --height=60%
    --layout=reverse
    --border=rounded
    --prompt="  "
    --pointer="  "
    --preview-window=right:65%:wrap:border-left
  '

  # Bat as preview engine if available
  if command -v bat &>/dev/null; then
    export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
    export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"
  fi

  # Ctrl+F: file picker excluding hidden files
  _fzf_file_no_hidden() {
    local cmd result
    cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
    if command -v bat &>/dev/null; then
      result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD")
    else
      result=$(eval "${cmd:-find . -type f}" | fzf)
    fi
    if [[ -n "$result" ]]; then
      LBUFFER+="$result"
    fi
    zle reset-prompt
  }
  zle -N _fzf_file_no_hidden
fi
