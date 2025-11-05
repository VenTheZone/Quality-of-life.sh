#!/usr/bin/env bash
read -p "Enter the video URL: " URL
if [[ -z "$URL" ]]; then
  echo "No URL provided. Exiting."
  exit 1
fi

proxychains4 yt-dlp "$URL"
