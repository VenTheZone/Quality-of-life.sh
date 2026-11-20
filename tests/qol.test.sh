#!/usr/bin/env bash
# qol: the built package lists every bin/ command and cdg, each with its line-2 description.
# Needs PKG (the built qol package); the flake check sets it.
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"
: "${PKG:?set PKG to the built qol package}"

run "$PKG/bin/qol" --list
eq "list exit 0" "$rc" 0
n=0
for f in "$SRC"/bin/* "$SRC/shell/cdg.zsh"; do
  name=${f##*/}
  name=${name%.zsh}
  desc=$(sed -n 2p "$f")
  desc=${desc#\# qol: }
  check "$name has a description" test -n "$desc"
  has "$name listed with its description" "$out" "$(printf '%-10s %s' "$name" "$desc")"
  n=$((n + 1))
done
eq "nothing else listed" "$(printf '%s\n' "$out" | wc -l)" "$n"

run "$PKG/bin/qol"
has "piped output is the list" "$out" "qol "

finish
