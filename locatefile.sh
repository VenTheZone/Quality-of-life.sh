#!/bin/bash
# locatefile.sh
# This script locates files in the current directory (and subdirectories)
# whose names match a given pattern.

# Check if a search pattern is provided
if [ "$#" -eq 0 ]; then
  echo "Usage: locatefile <pattern>"
  exit 1
fi

# Concatenate all provided arguments (this handles patterns with spaces)
pattern="$*"

# Use the find command to search for files whose names contain the pattern
find . -type f -name "*${pattern}*"
