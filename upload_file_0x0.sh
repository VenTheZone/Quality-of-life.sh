#!/bin/bash
# Upload File to 0x0 and copy the resulting URL to your clipboard

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILE="$1"
RESULT=$(curl -F "file=@${FILE}" https://0x0.st)
if [ $? -eq 0 ]; then
  echo "$RESULT" | wl-copy
  echo "URL copied to clipboard! -> $RESULT"
else
  echo "File upload failed."
  exit 1
fi
