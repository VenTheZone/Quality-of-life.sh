#!/usr/bin/env bash
# dl: the yt-dlp flags each choice sends and the status line it draws (stub yt-dlp, no network).
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"

export YTDLP_LOG=$T/ytdlp.log GUM_COUNT=$T/gum-count GUM_LOG=$T/gum.log
go() { # <choice> <url> [env...]: the quality menu answers Best unless GUM_CHOOSE2 is passed
  : >"$YTDLP_LOG"
  : >"$GUM_LOG"
  rm -f "$GUM_COUNT"
  local choice=$1 url=$2
  shift 2
  run env GUM_CHOOSE="$choice" GUM_CHOOSE2=Best "$@" bash "$SRC/bin/dl" "$url"
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

go "Video" "https://example.com/v"
hasnt "best: no format filter" "$sent" " -f "
has "video asks for quality" "$(cat "$GUM_LOG")" "--header Quality"

go "Video" "https://example.com/v" GUM_CHOOSE2=720p
has "720p filter with fallback" "$sent" "-f bv*[height<=720]+ba/b[height<=720]/bv*+ba/b"

go "Audio (mp3)" "https://example.com/v"
hasnt "audio: no quality menu" "$(cat "$GUM_LOG")" "--header Quality"

# Status line: progress redraws in place (\r, clear line), other output goes above it.
printf '%s\n' \
  'QOLP 1048576 4194304 2097152 3 720' \
  'QOLP 2097152 4194304 2097152 1 720' \
  'WARNING: something odd' \
  'QOLP 4194304 4194304 2097152 0 720' \
  'QOLM Merger' \
  "QOLF 4194304 $T/out dir/My_Clip [x1].mp4" >"$T/yt.out"
go "Video" "https://example.com/v" YTDLP_OUT="$T/yt.out"
eq "status exit 0" "$rc" 0
has "progress percent" "$out" " 25%"
has "progress bar" "$out" "█"
has "speed and eta" "$out" "2.0MiB/s  ETA 0:03"
has "height tag" "$out" "[720p]"
has "redraw in place" "$out" $'\r\033[2K'
has "merge step" "$out" "merging video and audio"
has "warning passed through" "$out" "WARNING: something odd"
has "done line: file name only" "$out" "✓"$'\033[0m'" My_Clip [x1].mp4 "
has "done line size" "$out" "(4.0MiB)"
# only these end a line: the warning, the done line and the final "Saved in"
eq "no scrolling progress" "$(printf '%s' "$out" | tr -cd '\n' | wc -c)" 3
has "cursor shown again" "$out" $'\033[?25h'

printf '%s\n' 'QOLP 10 NA NA NA NA' 'ERROR: Unsupported URL' >"$T/yt.out"
go "Video" "https://example.com/v" YTDLP_OUT="$T/yt.out" YTDLP_RC=1
eq "yt-dlp failure: exit 1" "$rc" 1
has "error shown" "$out" "ERROR: Unsupported URL"
has "failure reported" "$out" "download failed (yt-dlp exit 1)"
has "unknown size: bytes instead of percent" "$out" "10B"

printf '%s\n' "QOLF NA $T/a.mp4" >"$T/yt.out"
go "Video" "https://example.com/v" YTDLP_OUT="$T/yt.out"
has "done line without a known size" "$out" "a.mp4"$'\n'
hasnt "no placeholder size" "$out" "(?)"

go "Video" "--exec=rm"
eq "non-url refused" "$rc" 1
eq "non-url: yt-dlp never called" "$sent" ""

finish
