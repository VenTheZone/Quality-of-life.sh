#!/bin/bash
# This script selects a file and displays its contents

file=$(find . -type f | fzf)
if [ -z "$file" ]; then
  echo "No file selected."
else
  cat "$file"
fi
