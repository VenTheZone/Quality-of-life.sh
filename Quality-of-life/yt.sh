#!/bin/bash

# YouTube video downloader that replaces spaces with underscores
read -p "Enter video URL: " url
yt-dlp --progress --newline -o "%(title)s.%(ext)s" "$url"

# Rename downloaded file(s): replace spaces with underscores
for f in *\ *; do
  mv "$f" "${f// /_}"
done
