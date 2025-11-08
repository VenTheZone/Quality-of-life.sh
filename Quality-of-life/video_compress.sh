#!/bin/bash
# Requirements: ffmpeg, ffprobe, fzf

# --- Dependency check ---
deps=("ffmpeg" "ffprobe" "fzf")
missing=()

for dep in "${deps[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Missing dependency: $dep"
    missing+=("$dep")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo
  echo "Some required tools are missing."
  echo "Install them with:"
  echo "  sudo pacman -S ffmpeg fzf"
  exit 1
fi

# --- Video selection via fzf ---
echo "Selecting video file via fzf..."
video=$(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" \) |
  sed 's|^./||' | fzf --prompt="Select video> ")

if [ -z "$video" ]; then
  echo "No selection made, exiting."
  exit 0
fi

echo "Selected: $video"

# --- Ask for target size ---
read -rp "Enter target size in MB: " target_mb
if [[ ! "$target_mb" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (($(echo "$target_mb <= 0" | bc -l))); then
  echo "Invalid target size."
  exit 1
fi

# --- Get duration using ffprobe ---
duration_sec=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video")

if [[ -z "$duration_sec" || $(echo "$duration_sec <= 0" | bc -l) -eq 1 ]]; then
  echo "Could not determine duration."
  exit 1
fi

echo "Duration: $duration_sec seconds"

# --- Calculate bitrate ---
audio_kbps=128
target_kbits=$(echo "$target_mb * 8 * 1024" | bc -l)
total_kbps=$(echo "$target_kbits / $duration_sec" | bc -l)
video_kbps=$(echo "$total_kbps - $audio_kbps" | bc -l)

if (($(echo "$video_kbps < 50" | bc -l))); then
  echo "Warning: Target size too small, bitrate ${video_kbps%.*} kbps is too low."
  exit 1
fi

echo "Calculated video bitrate: ${video_kbps%.*} kbps (audio $audio_kbps kbps)"

# --- Output filename ---
base="${video%.*}"
output="${base}_compressed.mp4"

# --- Compress video ---
echo "Running ffmpeg..."
ffmpeg -i "$video" -c:v libx264 -b:v "${video_kbps%.*}k" -c:a aac -b:a 128k -preset slow "$output"

if [ $? -ne 0 ]; then
  echo "ffmpeg command failed."
  exit 1
fi

echo "Compression complete. Output file: $output"
