#!/usr/bin/env bash
# compress: bitrate maths, output naming, and the ffmpeg calls each target makes (stub ffmpeg).
# shellcheck source=tests/lib.sh
. "$SRC/tests/lib.sh"
# shellcheck source=bin/compress
. "$SRC/bin/compress" # defines the functions; main does not run when sourced

# --- pure maths: 10 MB over 60 s = 10 * 8388.608 * 0.98 / 60 = 1370.14 kbit/s in total
eq "10 MB, 60 s, audio" "$(compress_bitrates 10 60 1)" "1242 128"
eq "5 MB, 60 s: audio drops to 96k" "$(compress_bitrates 5 60 1)" "589 96"
eq "10 MB, 60 s, no audio" "$(compress_bitrates 10 60 0)" "1370 0"
eq "1 MB, 600 s, no audio still fits" "$(compress_bitrates 1 600 0)" "13 0"
run compress_bitrates 1 600 1
eq "1 MB, 600 s, audio: refused" "$rc" 1
run compress_bitrates 10 0 1
eq "zero duration: refused" "$rc" 1

# --- output naming never reuses a name
mkdir "$T/v"
eq "first name" "$(compress_outname "$T/v/clip.mov")" "$T/v/clip.compressed.mp4"
touch "$T/v/clip.compressed.mp4"
eq "taken name gets -1" "$(compress_outname "$T/v/clip.mov")" "$T/v/clip.compressed-1.mp4"
eq "name without extension" "$(compress_outname "$T/v/raw")" "$T/v/raw.compressed.mp4"

# --- whole command with stub ffprobe/ffmpeg/gum
export FFMPEG_LOG=$T/ffmpeg.log
in=$T/v/in.mkv
touch "$in"
go() { # <gum choice> [env...]: run compress on $in with a fresh ffmpeg log
  : >"$FFMPEG_LOG"
  local choice=$1
  shift
  run env GUM_CHOOSE="$choice" "$@" bash "$SRC/bin/compress" "$in"
  log=$(cat "$FFMPEG_LOG")
}

go "10 MB"
eq "10 MB exit 0" "$rc" 0
eq "two passes" "$(wc -l <"$FFMPEG_LOG")" 2
has "pass 1" "$(sed -n 1p "$FFMPEG_LOG")" "-b:v 1242k -pix_fmt yuv420p -pass 1"
has "pass 1 to null" "$(sed -n 1p "$FFMPEG_LOG")" "-an -f null /dev/null"
has "pass 2 audio" "$(sed -n 2p "$FFMPEG_LOG")" "-pass 2"
has "pass 2 aac 128k" "$(sed -n 2p "$FFMPEG_LOG")" "-c:a aac -b:a 128k"
has "pass 2 output" "$(sed -n 2p "$FFMPEG_LOG")" "-n -i $in"
eq "output written" "$(stat -c %s "$T/v/in.compressed.mp4")" 1000
has "result box" "$out" "in.compressed.mp4"

go "25 MB"
has "second run picks a new name" "$log" "$T/v/in.compressed-1.mp4"
eq "first output kept" "$(stat -c %s "$T/v/in.compressed.mp4")" 1000

go "Custom MB" GUM_INPUT=5
has "custom 5 MB" "$log" "-b:v 589k"
has "custom 5 MB audio 96k" "$log" "-b:a 96k"

go "10 MB" PROBE_AUDIO=0
has "no audio: whole budget to video" "$log" "-b:v 1370k"
hasnt "no audio: no aac" "$log" "aac"

go "10 MB" PROBE_DURATION=6000
eq "impossible target exits 1" "$rc" 1
has "impossible target says why" "$out" "too small"
eq "impossible target runs no ffmpeg" "$log" ""

go "10 MB" PROBE_SIZE=1000000
eq "already small exits 0" "$rc" 0
has "already small says so" "$out" "already"
eq "already small runs no ffmpeg" "$log" ""

go "720p"
eq "720p one pass" "$(wc -l <"$FFMPEG_LOG")" 1
has "720p crf" "$log" "-crf 23"
has "720p scale, never upscale" "$log" "scale=-2:'min(720,ih)'"

go "Custom MB" GUM_INPUT=abc
eq "bad custom size exits 1" "$rc" 1
has "bad custom size message" "$out" "not a whole number"

rm -f "$T"/v/in.compressed*
go "10 MB" PROBE_DURATION=N/A
eq "unreadable duration exits 1" "$rc" 1
check "unreadable duration leaves no output" test ! -e "$T/v/in.compressed.mp4"

finish
