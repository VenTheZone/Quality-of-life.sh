#!/usr/bin/env bash
# lib/ui.sh: terminal check, progress bar, and which previewer each kind of path gets.
# shellcheck disable=SC2016 # the bash -c scripts below expand $QOL_LIB themselves
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"
# shellcheck source=lib/ui.sh
. "$QOL_LIB"

# setsid drops the controlling terminal, so /dev/tty cannot be opened (as under a pipe or cron)
run env -u QOL_ASSUME_TTY setsid -w bash -c '. "$QOL_LIB"; ui_need_tty; echo reached'
eq "no terminal exits 1" "$rc" 1
has "no terminal says so" "$out" "needs a terminal"
hasnt "no terminal stops before the picker" "$out" "reached"
run bash -c '. "$QOL_LIB"; ui_need_tty; echo reached'
has "QOL_ASSUME_TTY lets tests through" "$out" "reached"

run bash -c '. "$QOL_LIB"; ui_die "boom"; echo after'
eq "ui_die exits 1" "$rc" 1
has "ui_die message" "$out" "boom"
hasnt "ui_die stops" "$out" "after"

y=$'\033[38;2;243;230;0m' g=$'\033[38;2;138;138;153m' o=$'\033[0m'
printf -v want '\r%sPass%s %s%s%s%s%s  50%%' "$y" "$o" "$y" "$(printf '█%.0s' {1..15})" "$g" "$(printf '░%.0s' {1..15})" "$o"
eq "bar at 50%" "$(ui_bar 50 Pass 2>&1)" "$want"
has "bar caps at 100%" "$(ui_bar 140 Pass 2>&1)" "100%"

eq "sizes" "$(ui_size 1048576)" "1.0MB"

eq "hex colour escape" "$(ui_fg '#02d7f2')" $'\033[38;2;2;215;242m'
eq "bad colour: no escape" "$(ui_fg 'red')" ""
run bash -c '. "$QOL_LIB"; ui_die "boom"'
has "error tag in red" "$out" $'\033[38;2;255;0;60m[ERR] //\033[0m boom'
run env QOL_ERR='#112233' bash -c '. "$QOL_LIB"; ui_die "boom"'
has "QOL_ERR overrides" "$out" $'\033[38;2;17;34;51m[ERR]'
has "ok tag" "$(ui_ok "done" 2>&1)" "[OK]"$'\033[0m done'
run bash -c '. "$QOL_LIB"; ui_banner "test run"'
has "banner name and subtitle" "$out" "▌"
has "banner subtitle upper case" "$out" "TEST RUN"
has "banner rule" "$out" "───"
has "fzf frame label" "$FZF_DEFAULT_OPTS" "--border-label=\"▌"
has "fzf colours after user options" "${FZF_DEFAULT_OPTS##*--color=}" "border:#f3e600"

export FZF_PREVIEW_COLUMNS=40 FZF_PREVIEW_LINES=12
touch "$T/pic.PNG" "$T/notes.txt"
mkdir "$T/folder"
eq "image outside kitty: chafa" "$(ui_preview_file "$T/pic.PNG")" \
  "chafa --format=symbols --size=40x12 --animate=off $T/pic.PNG"
eq "image in kitty: icat, trailing reset line dropped" "$(KITTY_WINDOW_ID=1 ui_preview_file "$T/pic.PNG")" \
  "kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=40x12@0x0 $T/pic.PNG"$'\e[m'
touch "$T/-x.png"
cd "$T"
# fd prints a relative name like -x.png without ./, which chafa and kitten would take as an option
eq "dash-named image outside kitty: chafa gets ./" "$(ui_preview_file -x.png)" \
  "chafa --format=symbols --size=40x12 --animate=off ./-x.png"
eq "dash-named image in kitty: icat gets ./" "$(KITTY_WINDOW_ID=1 ui_preview_file -x.png)" \
  "kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=40x12@0x0 ./-x.png"$'\e[m'
cd "$OLDPWD"
eq "folder: eza tree" "$(ui_preview_file "$T/folder")" "eza --tree --level=2 --color=always --icons=always -- $T/folder"
has "text: bat" "$(ui_preview_file "$T/notes.txt")" "bat --color=always"

finish
