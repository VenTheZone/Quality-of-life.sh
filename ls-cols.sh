#!/bin/bash
# ls-cols.sh: Table with eza for icons/colors, mod time sort, wrapping for long names

# Requires eza installed with Nerd Fonts

# Colors (tput ANSI, but eza handles colors)
BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)
WHITE=$(tput setaf 7)

# Target directory
if [ $# -eq 0 ]; then
  TARGET="."
else
  TARGET="$1"
fi

# Terminal width
TERM_WIDTH=$(tput cols)
MIN_COL_WIDTH=20
COL_WIDTH=$(((TERM_WIDTH - 3) / 2 > MIN_COL_WIDTH ? (TERM_WIDTH - 3) / 2 : MIN_COL_WIDTH))

# Functions for ANSI handling
strip_ansi() {
  echo -n "$1" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3}){0,})?[mGK]//g"
}

visible_length() {
  local plain=$(strip_ansi "$1")
  echo ${#plain}
}

wrap_ansi() {
  local str="$1"
  local max="$2"
  local plain=$(strip_ansi "$str")
  local len=${#plain}
  if ((len <= max)); then
    echo "$str"
    return
  fi
  local output=""
  local line=""
  local visible=0
  local current_style=""
  local in_esc=0
  local esc_seq=""
  local i=0
  local char
  while ((i < ${#str})); do
    char="${str:i:1}"
    if [[ "$char" == $'\e' ]]; then
      in_esc=1
      esc_seq="$char"
    elif ((in_esc)); then
      esc_seq+="$char"
      if [[ "$char" =~ [mGK] ]]; then
        in_esc=0
        line+="$esc_seq"
        if [[ "$char" == "m" ]]; then
          if [[ "$esc_seq" == $'\e[0m' ]]; then
            current_style=""
          else
            current_style="$esc_seq"
          fi
        fi
      fi
    else
      line+="$char"
      ((visible++))
      if ((visible >= max)); then
        output+="$line"$'\n'
        line="$current_style"
        visible=0
      fi
    fi
    ((i++))
  done
  output+="$line"
  echo "$output"
}

# Fallback list <40 cols (using eza)
if [ "$TERM_WIDTH" -lt 40 ]; then
  DIRS=$(eza --only-dirs --icons=always --color=always --sort=modified --reverse -1 --no-permissions --no-user --no-time --no-filesize "$TARGET")
  if [ -n "$DIRS" ]; then
    echo "${YELLOW}${BOLD}Dirs:${RESET}"
    echo "$DIRS"
  fi
  FILES=$(eza --only-files --icons=always --color=always --sort=modified --reverse -1 --no-permissions --no-user --no-time --no-filesize "$TARGET")
  if [ -n "$FILES" ]; then
    echo "${YELLOW}${BOLD}Files:${RESET}"
    echo "$FILES"
  fi
  exit 0
fi

# Dirs
DIRS=$(eza --only-dirs --icons=always --color=always --sort=modified --reverse -1 --no-permissions --no-user --no-time --no-filesize "$TARGET")

# Files
FILES=$(eza --only-files --icons=always --color=always --sort=modified --reverse -1 --no-permissions --no-user --no-time --no-filesize "$TARGET")

# Load arrays
mapfile -t DIRS < <(echo "$DIRS")
mapfile -t FILES < <(echo "$FILES")
if [ ${#DIRS[@]} -eq 0 ] && [ ${#FILES[@]} -eq 0 ]; then
  exit 0
fi

if [ ${#DIRS[@]} -eq 0 ]; then
  echo "${YELLOW}${BOLD}Files:${RESET}"
  for file_str in "${FILES[@]}"; do
    echo "$file_str"
  done
  exit 0
fi

if [ ${#FILES[@]} -eq 0 ]; then
  echo "${YELLOW}${BOLD}Dirs:${RESET}"
  for dir_str in "${DIRS[@]}"; do
    echo "$dir_str"
  done
  exit 0
fi

LEN=${#DIRS[@]}
if [ ${#FILES[@]} -gt $LEN ]; then LEN=${#FILES[@]}; fi

# Header
printf "${YELLOW}${BOLD}%-${COL_WIDTH}s   %-${COL_WIDTH}s${RESET}\n" "DIRS" "FILES"

# Rows
for ((i = 0; i < LEN; i++)); do
  dir_str="${DIRS[i]:-"${WHITE}--${RESET}"}"
  file_str="${FILES[i]:-"${WHITE}--${RESET}"}"
  dir_wrapped=$(wrap_ansi "$dir_str" $COL_WIDTH)
  file_wrapped=$(wrap_ansi "$file_str" $COL_WIDTH)
  mapfile -t dir_lines < <(echo -n "$dir_wrapped")
  mapfile -t file_lines < <(echo -n "$file_wrapped")
  dir_num=${#dir_lines[@]}
  file_num=${#file_lines[@]}
  max_num=$((dir_num > file_num ? dir_num : file_num))
  for ((j = 0; j < max_num; j++)); do
    d_line="${dir_lines[j]:-}"
    f_line="${file_lines[j]:-}"
    if [[ -z "$d_line" ]]; then
      d_line=$(printf "%-${COL_WIDTH}s" " ")
    else
      d_vis=$(visible_length "$d_line")
      d_pad=$((COL_WIDTH - d_vis))
      d_line="$d_line$(printf "%*s" $d_pad " ")"
    fi
    if [[ -z "$f_line" ]]; then
      f_line=$(printf "%-${COL_WIDTH}s" " ")
    else
      f_vis=$(visible_length "$f_line")
      f_pad=$((COL_WIDTH - f_vis))
      f_line="$f_line$(printf "%*s" $f_pad " ")"
    fi
    printf "%s   %s\n" "$d_line" "$f_line"
  done
done
