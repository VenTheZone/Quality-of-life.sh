#!/usr/bin/env bash
# pw: length validation, the copied password, and no password in any gum argv (stub gum and wl-copy).
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

# Local gum: picks the first line of its stdin, so the pick is a real generated password.
rm -f "$T/bin/gum" # the copied stub is read-only in the build sandbox
cat >"$T/bin/gum" <<EOF
#!$BASH
printf 'gum %s\n' "\$*" >>"\$GUM_LOG"
case \$1 in
  choose) head -n1 ;;
  style) shift; n=0; for a; do if [[ \$a != -* ]]; then echo "\$a"; n=1; fi; done; if ((n == 0)); then cat; fi ;;
esac
EOF
chmod +x "$T/bin/gum"
export GUM_LOG=$T/gum.log CLIP_FILE=$T/clip WAYLAND_DISPLAY=dummy-no-real-clipboard

for bad in 08 010 7 129 18446744073709551624 abc; do
  run bash "$SRC/bin/pw" "$bad"
  eq "pw $bad: rc" "$rc" 1
  has "pw $bad: message" "$out" "usage: pw [length 8-128]"
  hasnt "pw $bad: no arithmetic error" "$out" "line"
done

: >"$GUM_LOG"
run bash "$SRC/bin/pw" 24
eq "valid run exit 0" "$rc" 0
pick=$(<"$CLIP_FILE")
eq "copied password has the asked length" "${#pick}" 24
allowed() { [[ $1 =~ ^[A-Za-z0-9@#%^\&*_+=]+$ ]]; }
check "copied password uses the allowed characters" allowed "$pick"
has "box shows the pick" "$out" "$pick"
has "box says copied" "$out" "copied to the clipboard"
hasnt "pick never in a gum argv" "$(<"$GUM_LOG")" "$pick"

run bash "$SRC/bin/pw"
pick=$(<"$CLIP_FILE")
eq "default length 20" "${#pick}" 20

finish
