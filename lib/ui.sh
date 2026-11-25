# Shared look and helpers for every qol command. Each bin/ script sources this file
# through $QOL_LIB, which the Nix wrapper sets (tests/lib.sh sets it in tests).
set -euo pipefail # the options writeShellApplication sets, so tests behave like the package

# One palette for every command: hex colours, each overridable from the environment.
# Yellow frames and prompts, cyan for what is selected or moving, red for errors.
: "${QOL_ACCENT:=#f3e600}" "${QOL_SELECT:=#02d7f2}" "${QOL_OK:=#00ff9f}" "${QOL_ERR:=#ff003c}" "${QOL_DIM:=#8a8a99}"

ui_fg() { # <#rrggbb>: truecolor foreground escape; anything else prints nothing
  local h=${1#\#}
  if [[ $h =~ ^[0-9A-Fa-f]{6}$ ]]; then printf '\033[38;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"; fi
}
# shellcheck disable=SC2034 # read by the bin/ scripts
C_ACCENT=$(ui_fg "$QOL_ACCENT") C_SELECT=$(ui_fg "$QOL_SELECT") C_OK=$(ui_fg "$QOL_OK")
C_ERR=$(ui_fg "$QOL_ERR") C_DIM=$(ui_fg "$QOL_DIM") C_OFF=$'\033[0m'

export GUM_CHOOSE_CURSOR="▸ " GUM_CHOOSE_CURSOR_FOREGROUND=$QOL_SELECT GUM_CHOOSE_SELECTED_FOREGROUND=$QOL_SELECT
export GUM_CHOOSE_HEADER_FOREGROUND=$QOL_ACCENT
export GUM_INPUT_PROMPT=">> " GUM_INPUT_PROMPT_FOREGROUND=$QOL_ACCENT GUM_INPUT_CURSOR_FOREGROUND=$QOL_SELECT
export GUM_INPUT_HEADER_FOREGROUND=$QOL_ACCENT
export GUM_CONFIRM_PROMPT_FOREGROUND=$QOL_ACCENT GUM_CONFIRM_SELECTED_BACKGROUND=$QOL_ACCENT
export GUM_CONFIRM_SELECTED_FOREGROUND="#000000" GUM_CONFIRM_UNSELECTED_FOREGROUND=$QOL_DIM
# Layout first, so the user's FZF_DEFAULT_OPTS can change it; colours and frame last, so qol keeps
# its look (set QOL_* to change those). The frame label is the command's name.
qol_name=${0##*/}
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline-right --preview-window=right,55%,border-left ${FZF_DEFAULT_OPTS-} --border=sharp --border-label=\"▌${qol_name^^} //\" --border-label-pos=3 --pointer=▸ --marker=▪ --prompt='>> ' --color=border:$QOL_ACCENT,label:$QOL_ACCENT,prompt:$QOL_ACCENT,pointer:$QOL_SELECT,marker:$QOL_ERR,hl:$QOL_ACCENT,hl+:$QOL_ACCENT,fg+:$QOL_SELECT,info:$QOL_DIM,spinner:$QOL_SELECT,header:$QOL_DIM,separator:$QOL_DIM,scrollbar:$QOL_DIM"

ui_die() { # <message>: red [ERR] line on stderr, exit 1
  printf '%s[ERR] //%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2
  exit 1
}

ui_ok() { # <message>: [OK] line on stderr
  printf '%s[OK]%s %s\n' "$C_OK" "$C_OFF" "$*" >&2
}

ui_banner() { # <subtitle>: "▌NAME // SUBTITLE ────" header on stderr, as wide as the terminal (max 60)
  local head="▌${qol_name^^} // ${1^^} " cols rule
  cols=$({ stty size </dev/tty; } 2>/dev/null) || cols=
  cols=${cols#* }
  [[ $cols =~ ^[0-9]+$ ]] || cols=60
  ((cols > 60)) && cols=60
  printf -v rule '%*s' $((cols > ${#head} ? cols - ${#head} : 0)) ''
  printf '%s▌%s%s %s//%s %s%s %s%s%s\n' "$C_ACCENT" "${qol_name^^}" "$C_OFF" "$C_ERR" "$C_OFF" \
    "$C_ACCENT" "${1^^}" "$C_DIM" "${rule// /─}" "$C_OFF" >&2
}

ui_need_tty() { # fzf and gum draw on /dev/tty: without one, say so and exit 1 (tests set QOL_ASSUME_TTY=1)
  if [[ -n ${QOL_ASSUME_TTY-} ]]; then return 0; fi
  { : >/dev/tty; } 2>/dev/null || ui_die "${0##*/} needs a terminal"
}

ui_box() { # <line>...: sharp box in the accent colour (needs gum); no lines: reads them from stdin
  gum style --border=normal --padding="0 1" --border-foreground="$QOL_ACCENT" "$@"
}

ui_size() { # <bytes>: 48MB, 1.2GB (needs coreutils)
  numfmt --to=iec --suffix=B "$1"
}

ui_bar() { # <percent> <label>: redraw one 30-cell progress line on stderr
  local pct=$1 fill rest
  if ((pct > 100)); then pct=100; fi
  printf -v fill '%*s' $((pct * 30 / 100)) ''
  printf -v rest '%*s' $((30 - pct * 30 / 100)) ''
  printf '\r%s%s%s %s%s%s%s%s %3d%%' "$C_ACCENT" "$2" "$C_OFF" "$C_ACCENT" "${fill// /█}" "$C_DIM" "${rest// /░}" "$C_OFF" "$pct" >&2
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
  [[ $1 == /* ]] || set -- "./$1" # a name like -x.png must not read as an option to chafa or kitten
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
