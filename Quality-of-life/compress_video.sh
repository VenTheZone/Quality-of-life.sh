#!/bin/bash

# If argument is provided, use it. Otherwise, prompt.
if [ -n "$1" ]; then
  input="$1"
else
  read -p "Enter video file path: " input
fi

# Check if file exists
if [ ! -f "$input" ]; then
  echo "Error: File not found."
  exit 1
fi

# Extract filename and extension
filename=$(basename -- "$input")
name="${filename%.*}"

# Define output name
output="${name}_compressed.mp4"

# Run ffmpeg compression
ffmpeg -i "$input" -c:v libx265 -crf 23 -preset slow -c:a aac -b:a 128k "./$output"
