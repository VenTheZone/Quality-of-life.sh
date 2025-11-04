#!/bin/bash
# This script selects a directory via fzf.
# Note: Changing directories here won’t affect your current interactive shell.
dir=$(find . -type d | fzf)
if [ -z "$dir" ]; then
  echo "No directory selected."
else
  cd "$dir" || echo "Failed to change directory."
  # Optionally, print the new working directory:
  echo "Changed directory to: $(pwd)"
fi
