# Shared look and helpers for every qol command. Each bin/ script sources this file
# through $QOL_LIB, which the Nix wrapper sets (tests/lib.sh sets it in tests).
set -euo pipefail # the options writeShellApplication sets, so tests behave like the package

# One palette for every command (ANSI 256 colour numbers).
QOL_ACCENT=212 QOL_OK=78 QOL_ERR=203 QOL_DIM=245
export GUM_CHOOSE_CURSOR_FOREGROUND=$QOL_ACCENT GUM_CHOOSE_SELECTED_FOREGROUND=$QOL_ACCENT GUM_CHOOSE_HEADER_FOREGROUND=$QOL_DIM
export GUM_INPUT_CURSOR_FOREGROUND=$QOL_ACCENT GUM_INPUT_PROMPT_FOREGROUND=$QOL_ACCENT GUM_INPUT_HEADER_FOREGROUND=$QOL_DIM
export GUM_CONFIRM_PROMPT_FOREGROUND=$QOL_ACCENT GUM_CONFIRM_SELECTED_BACKGROUND=$QOL_ACCENT
# Our layout first; the user's FZF_DEFAULT_OPTS (the rice's colours) comes after, so it wins.
export FZF_DEFAULT_OPTS="--layout=reverse --border=rounded --info=inline-right --preview-window=right,55%,border-left --color=pointer:$QOL_ACCENT,prompt:$QOL_ACCENT ${FZF_DEFAULT_OPTS-}"

ui_die() { # <message>: red error on stderr, exit 1
  printf '\033[38;5;%sm✗ %s\033[0m\n' "$QOL_ERR" "$*" >&2
  exit 1
}

ui_ok() { # <message>: green line on stderr
  printf '\033[38;5;%sm✓ %s\033[0m\n' "$QOL_OK" "$*" >&2
}

ui_need_tty() { # fzf and gum draw on /dev/tty: without one, say so and exit 1 (tests set QOL_ASSUME_TTY=1)
  if [[ -n ${QOL_ASSUME_TTY-} ]]; then return 0; fi
  { : >/dev/tty; } 2>/dev/null || ui_die "${0##*/} needs a terminal"
}

ui_box() { # <line>...: rounded box in the accent colour (needs gum)
  gum style --border=rounded --padding="0 1" --border-foreground="$QOL_ACCENT" "$@"
}

ui_size() { # <bytes>: 48MB, 1.2GB (needs coreutils)
  numfmt --to=iec --suffix=B "$1"
}

ui_bar() { # <percent> <label>: redraw one 30-cell progress line on stderr
  local pct=$1 fill rest
  if ((pct > 100)); then pct=100; fi
  printf -v fill '%*s' $((pct * 30 / 100)) ''
  printf -v rest '%*s' $((30 - pct * 30 / 100)) ''
  printf '\r\033[38;5;%sm%s\033[0m %s%s %3d%%' "$QOL_ACCENT" "$2" "${fill// /█}" "${rest// /░}" "$pct" >&2
}

ui_preview_image() { # <image> <cols> <rows>: draw an image in an fzf preview pane (kitty, else chafa)
  if [[ -n ${KITTY_WINDOW_ID-} ]] && command -v kitten >/dev/null; then
    # fzf's own recipe: the last line is a lone reset code that makes fzf show a scroll offset
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no \
      --place="${2}x${3}@0x0" "$1" | sed '$d' | sed $'$s/$/\e[m/'
  else
    chafa --format=symbols --size="${2}x${3}" --animate=off "$1"
  fi
}

ui_preview_file() { # <path>: fzf preview for an image, a folder or a text file (needs eza, bat, chafa)
  local cols=${FZF_PREVIEW_COLUMNS:-80} rows=${FZF_PREVIEW_LINES:-24}
  case ${1,,} in
    *.png | *.jpg | *.jpeg | *.gif | *.webp | *.bmp) ui_preview_image "$1" "$cols" "$rows" ;;
    *)
      if [[ -d $1 ]]; then
        eza --tree --level=2 --color=always --icons=always -- "$1"
      else
        bat --color=always --style=numbers --line-range=:500 -- "$1"
      fi
      ;;
  esac
}
