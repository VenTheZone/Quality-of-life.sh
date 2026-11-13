#!/usr/bin/env bash
set -e

# dependencies
command -v fzf >/dev/null 2>&1 || {
  echo "fzf is required. Aborting."
  exit 1
}
command -v ffmpeg >/dev/null 2>&1 || {
  echo "ffmpeg is required. Aborting."
  exit 1
}

# select video file in current dir (non‑recursive)
file=$(find . -maxdepth 1 -type f | sed 's|^\./||' | fzf --prompt="Select a video: ")
if [[ -z "$file" ]]; then
  echo "No file selected."
  exit 1
fi

base="${file%.*}"

# resolution menu
res=$(printf "480p\n720p\n1080p" | fzf --prompt="Select output resolution: " --layout=reverse)
if [[ -z "$res" ]]; then
  echo "No resolution selected."
  exit 1
fi

case "$res" in
480p) height=480 ;;
720p) height=720 ;;
1080p) height=1080 ;;
*)
  echo "Invalid selection: $res"
  exit 1
  ;;
esac

out="${base}_SD_${res}.mp4"

echo "Converting \"$file\" → \"$out\" at height ${height}…"
ffmpeg -i "$file" -vf "scale=-2:${height}" -c:v libx264 -crf 23 -preset medium -c:a copy "$out"

echo "Done: $out"
