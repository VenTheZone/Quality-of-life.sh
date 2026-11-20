#!/usr/bin/env bash
# README: the commands table has one row per command, with the command's line-2 description.
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

readme=$(<"$SRC/README.md")
n=0
for f in "$SRC"/bin/* "$SRC/shell/cdg.zsh"; do
  name=${f##*/}
  name=${name%.zsh}
  desc=$(sed -n 2p "$f")
  desc=${desc#\# qol: }
  has "README row for $name" "$readme" "| \`$name\` | $desc |"
  n=$((n + 1))
done
eq "no extra rows" "$(grep -c '^| `' "$SRC/README.md")" "$n"

finish
