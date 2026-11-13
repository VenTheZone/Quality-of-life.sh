#!/usr/bin/env bash
# dir‑navigator with arrow‑key directory navigation

require_tools() {
  for cmd in fzf tree; do
    if ! command -v $cmd &>/dev/null; then
      echo "Required tool '$cmd' not found. Install it first."
      exit 1
    fi
  done
}

require_tools

current="."
while true; do
  # list visible directories only in current
  mapfile -t dirs < <(find "$current" -maxdepth 1 -type d -not -path "${current}/\.*" -printf '%f\n')
  if [ ${#dirs[@]} -eq 0 ]; then
    echo "No visible directories under '$current'."
    break
  fi

  selected=$(
    printf '%s\n' "${dirs[@]}" | fzf \
      --prompt="Dir> (↑↓ select, → enter, ← up, Esc quit) " \
      --height=40% \
      --preview "tree -d -L 1 --noreport \"$current/{}\" 2>/dev/null || echo 'No preview'" \
      --preview-window=right:60%:wrap \
      --bind "right:accept+reload(find \"$current/{}\" -maxdepth 1 -type d -not -path \"*/.*\" -printf '%f\n' | fzf --prompt=\"Dir> \" --height=40% --preview \"tree -d -L 1 --noreport \"$current/{}/{}\" 2>/dev/null || echo 'No preview'\" --bind \"right:accept+reload(...) ,left:reload(...)\")" \
      --bind "left:reload(find \"$(dirname "$current")\" -maxdepth 1 -type d -not -path \"*/.*\" -printf '%f\n' | fzf --prompt=\"Dir> \" --height=40% --preview \"tree -d -L 1 --noreport \"$(dirname "$current")/{}\" 2>/dev/null || echo 'No preview'\" --bind \"right:accept+reload(...),left:reload(...)\" )"
  )

  if [ -z "$selected" ]; then
    # Esc or nothing selected → exit
    break
  fi

  # update current directory
  current="$current/$selected"
done

cd "$current" || exit 1
echo "Final directory: $current"
