#!/usr/bin/env bash
# up: Litterbox for files, TinyURL for links, nothing sent without a yes (stub curl, no network).
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

eq "curl is the stub" "$(command -v curl)" "$T/bin/curl"
export CURL_LOG=$T/curl.log CLIP_FILE=$T/clip GUM_LOG=$T/gum.log WAYLAND_DISPLAY=stub
go() { # <arg> [env...]: run up with a fresh curl log and clipboard
  : >"$CURL_LOG"
  : >"$CLIP_FILE"
  local arg=$1
  shift
  run env "$@" bash "$SRC/bin/up" "$arg"
  sent=$(cat "$CURL_LOG")
}
mkdir "$T/f"
echo "hello" >"$T/f/note.txt"

go "https://example.com/a b?c=1&d=2" GUM_CONFIRM=0 CURL_REPLY=https://tinyurl.com/abc
eq "url exit 0" "$rc" 0
has "url goes to TinyURL" "$sent" "https://tinyurl.com/api-create.php"
has "url sent as text" "$sent" $'--data-urlencode\nurl=https://example.com/a b?c=1&d=2'
hasnt "url not sent to Litterbox" "$sent" "litterbox"
eq "short link copied" "$(cat "$CLIP_FILE")" "https://tinyurl.com/abc"
has "short link shown" "$out" "https://tinyurl.com/abc"
hasnt "link never on gum's argv" "$(<"$GUM_LOG")" "https://tinyurl.com/abc"

go "$T/f/note.txt" GUM_CONFIRM=0 GUM_CHOOSE=72h CURL_REPLY=https://litter.catbox.moe/x1.txt
eq "file exit 0" "$rc" 0
has "file goes to Litterbox" "$sent" "https://litterbox.catbox.moe/resources/internals/api.php"
has "file reqtype as text" "$sent" $'--form-string\nreqtype=fileupload'
has "file keeps the chosen time" "$sent" $'--form-string\ntime=72h'
has "file attached" "$sent" "fileToUpload=@\"$T/f/note.txt\""
eq "file link copied" "$(cat "$CLIP_FILE")" "https://litter.catbox.moe/x1.txt"

weird=$T/f/we\"ird\;name.txt
echo x >"$weird"
go "$weird" GUM_CONFIRM=0 GUM_CHOOSE=1h
has "quote in a file name escaped for curl -F" "$sent" "fileToUpload=@\"$T/f/we\\\"ird;name.txt\""

go "$T/f/note.txt" GUM_CONFIRM=1 GUM_CHOOSE=24h
eq "file refused without a yes" "$rc" 1
eq "file: curl never called" "$sent" ""
has "file: says cancelled" "$out" "Cancelled"

go "https://example.com" GUM_CONFIRM=1
eq "url refused without a yes" "$rc" 1
eq "url: curl never called" "$sent" ""

go "https://example.com" GUM_CONFIRM=0 CURL_REPLY="Error: rate limited"
eq "odd reply exits 1" "$rc" 1
eq "odd reply not copied" "$(cat "$CLIP_FILE")" ""

go "$T/f/missing.txt" GUM_CONFIRM=0
eq "neither file nor url exits 1" "$rc" 1
has "neither file nor url message" "$out" "not a file or URL"
eq "neither: curl never called" "$sent" ""

finish
