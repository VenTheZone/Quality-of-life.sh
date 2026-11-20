#!/usr/bin/env bash
# vault: round trip with a stub age, file naming, and that nothing is deleted without a yes.
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

w=$T/w
mkdir -p "$w/secret/sub"
echo "one" >"$w/secret/a.txt"
echo "two" >"$w/secret/sub/b.txt"
cp -r "$w/secret" "$T/copy"

run bash "$SRC/bin/vault"
eq "no argument exits 1" "$rc" 1
has "usage shown" "$out" "usage: vault"

# encrypt, answer no: archive made, original kept
run env GUM_CONFIRM=1 bash "$SRC/bin/vault" "$w/secret"
eq "encrypt exit 0" "$rc" 0
eq "archive named <name>.tar.age" "$(head -c 7 "$w/secret.tar.age")" STUBAGE
eq "original kept without a yes" "$(cat "$w/secret/a.txt")" one
check "no .part left" test ! -e "$w/secret.tar.age.part"

run env GUM_CONFIRM=1 bash "$SRC/bin/vault" "$w/secret"
eq "existing archive refused" "$rc" 1
has "existing archive message" "$out" "already exists"

# decrypt while the folder still exists: nothing overwritten, archive kept even with a yes
echo "changed" >"$w/secret/a.txt"
run env GUM_CONFIRM=0 bash "$SRC/bin/vault" "$w/secret.tar.age"
check "decrypt over existing files fails" test "$rc" -ne 0
eq "existing file not overwritten" "$(cat "$w/secret/a.txt")" changed
check "archive kept after failed decrypt" test -e "$w/secret.tar.age"

# decrypt into a clean folder, answer no: contents match, archive kept
rm -rf "$w/secret"
run env GUM_CONFIRM=1 bash "$SRC/bin/vault" "$w/secret.tar.age"
eq "decrypt exit 0" "$rc" 0
check "round trip restores the folder" diff -r "$T/copy" "$w/secret"
check "archive kept without a yes" test -e "$w/secret.tar.age"

# encrypt with a yes: original removed only after the check passed
rm "$w/secret.tar.age"
run env GUM_CONFIRM=0 bash "$SRC/bin/vault" "$w/secret"
eq "encrypt+delete exit 0" "$rc" 0
check "original deleted after yes" test ! -e "$w/secret"
check "archive there after yes" test -e "$w/secret.tar.age"

# failing age: original survives, no archive or .part left
cp -r "$T/copy" "$w/keep"
run env AGE_FAIL=1 GUM_CONFIRM=0 bash "$SRC/bin/vault" "$w/keep"
check "age failure exits non-zero" test "$rc" -ne 0
check "original survives a failed run" diff -r "$T/copy" "$w/keep"
check "no archive after failure" test ! -e "$w/keep.tar.age"
check "no .part after failure" test ! -e "$w/keep.tar.age.part"

# the check after encrypting fails: original kept even with a yes
cp -r "$T/copy" "$w/bad"
run env AGE_CORRUPT=1 GUM_CONFIRM=0 bash "$SRC/bin/vault" "$w/bad"
check "failed check exits non-zero" test "$rc" -ne 0
check "failed check keeps the original" diff -r "$T/copy" "$w/bad"

# a single file works too
echo "solo" >"$w/note.txt"
run env GUM_CONFIRM=0 bash "$SRC/bin/vault" "$w/note.txt"
check "single file encrypted" test -e "$w/note.txt.tar.age"
check "single file original deleted after yes" test ! -e "$w/note.txt"

finish
