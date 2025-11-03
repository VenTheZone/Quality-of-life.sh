#!/bin/bash
# Upload URL to 0x0 and copy the shortened URL to your clipboard

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

TARGET_URL="$1"
RESULT=$(curl -F "url=${TARGET_URL}" https://0x0.st)
if [ $? -eq 0 ]; then
  echo "$RESULT" | wl-copy
  echo "Shortened URL copied to clipboard! -> $RESULT"
else
  echo "URL upload failed."
  exit 1
fi
