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

go "Video" "https://example.com/v"
has "no routes file: current folder" "$sent" "-P $PWD"

mkdir -p "$HOME/.config/qol"
printf '%s\n' '# comment' '' 'clips.example ~/Videos/clips' "Other.example $T/other" \
  >"$HOME/.config/qol/dl-routes"

go "Video" "https://www.CLIPS.example/watch/x"
has "routed subdomain, ~ expanded" "$sent" "-P $HOME/Videos/clips"
check "routed folder made" test -d "$HOME/Videos/clips"

go "Video" "https://user@other.example:8080/v"
has "user info and port ignored" "$sent" "-P $T/other"

go "Video" "https://clips.example.evil.org/v"
has "lookalike host: current folder" "$sent" "-P $PWD"

go "Video" "https://notclips.example/v"
has "suffix without dot: current folder" "$sent" "-P $PWD"

go "Video" "--exec=rm"
eq "non-url refused" "$rc" 1
eq "non-url: yt-dlp never called" "$sent" ""

finish
