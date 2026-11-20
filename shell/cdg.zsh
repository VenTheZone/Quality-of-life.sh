# cdg for zsh. The qol home module puts this in ~/.zshrc with @fd@ @fzf@ @eza@ set to store paths.
# qol: Jump to a folder with fzf and a tree preview (zsh function)
cdg() {
  local dir
  dir=$(@fd@ --type d --hidden --exclude .git -- . "${1:-.}" |
    @fzf@ --scheme=path --prompt='cd> ' --preview '@eza@ --tree --level=2 --color=always --icons=always -- {}') || return
  cd -- "$dir"
}
