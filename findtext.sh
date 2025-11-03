#!/bin/bash
# findtext.sh
# This script searches for files that mention a given text and prints
# the directory and filename for each match.

# Check if a search term is provided
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <text-to-search>"
  exit 1
fi

# Join all provided arguments into a single search term
search="$*"

# Use grep to recursively list file names that contain the search term.
# This approach avoids issues with filenames that have spaces.
grep -R -l "$search" . 2>/dev/null | while IFS= read -r file; do
  echo "Directory: $(dirname "$file") | File: $(basename "$file")"
done
