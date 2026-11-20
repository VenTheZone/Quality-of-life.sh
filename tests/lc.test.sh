#!/usr/bin/env bash
# lc: two-pane layout from fixed eza output at a fixed width, and the narrow fallback.
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

export EZA_DIRS=$T/dirs EZA_FILES=$T/files EZA_LOG=$T/eza.log
printf '\033[1;34msrc\033[0m\ndocs\n' >"$EZA_DIRS"
printf 'a-very-long-file-name-here.txt\n\033[32mrun.sh\033[0m\nREADME.md\n' >"$EZA_FILES"
mkdir "$T/here"

# 43 columns: each pane is (43 - 3) / 2 = 20 characters wide
want=$(
  printf 'Folders (2)%9s │ Files (3)\n' ''
  printf '\033[1;34msrc\033[0m%17s │ a-very-long-file-na…\n' ''
  printf 'docs%16s │ \033[32mrun.sh\033[0m\n' ''
  printf '%20s │ README.md\n' ''
)
run env COLUMNS=43 bash "$SRC/bin/lc" "$T/here"
eq "exit 0" "$rc" 0
eq "two panes at 43 columns" "$out" "$want"
has "newest first" "$(cat "$EZA_LOG")" "--sort=modified --reverse"
has "no colour when piped" "$(cat "$EZA_LOG")" "--color=never --icons=never"

run env COLUMNS=30 bash "$SRC/bin/lc" "$T/here"
eq "one column under 40" "$out" "$(cat "$EZA_DIRS" "$EZA_FILES")"

: >"$EZA_DIRS"
run env COLUMNS=43 bash "$SRC/bin/lc" "$T/here"
has "no folders" "$out" "Folders (0)"
eq "files still listed" "$(printf '%s\n' "$out" | sed -n 2p)" "$(printf '%20s │ a-very-long-file-na…' '')"

run bash "$SRC/bin/lc" "$T/nope"
eq "missing folder exits 1" "$rc" 1
has "missing folder message" "$out" "not a folder"

finish
