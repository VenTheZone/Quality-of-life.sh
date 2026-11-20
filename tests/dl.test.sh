#!/usr/bin/env bash
# dl: the yt-dlp flags each choice sends (stub yt-dlp, no network).
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

export YTDLP_LOG=$T/ytdlp.log
go() { # <choice> <url> [env...]
  : >"$YTDLP_LOG"
  local choice=$1 url=$2
  shift 2
  run env GUM_CHOOSE="$choice" "$@" bash "$SRC/bin/dl" "$url"
  sent=$(cat "$YTDLP_LOG")
}

go "Video" "https://example.com/v?id=1"
eq "video exit 0" "$rc" 0
has "safe file names" "$sent" "--restrict-filenames"
has "url after --" "$sent" "-- https://example.com/v?id=1"
hasnt "video keeps the video" "$sent" " -x "

go "Audio (opus)" "https://example.com/v"
has "opus audio" "$sent" "-x --audio-format opus"

go "Audio (mp3)" "https://example.com/v"
has "mp3 audio" "$sent" "-x --audio-format mp3 --audio-quality 0"

go "Video" "" GUM_INPUT="https://example.com/pasted"
has "pasted url used" "$sent" "-- https://example.com/pasted"

go "Video" "--exec=rm"
eq "non-url refused" "$rc" 1
eq "non-url: yt-dlp never called" "$sent" ""

finish
