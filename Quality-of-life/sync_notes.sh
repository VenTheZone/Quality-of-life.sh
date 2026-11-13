#!/bin/bash
cd "/home/jt/Documents/Obsidian Vault"

echo "Starting Obsidian Vault sync..."

# Fetch remote changes
git fetch origin

# Pull and merge (using merge strategy)
git pull origin main

# Add all changes
git add .

# Commit with timestamp
git commit -m "Vault sync: $(date '+%Y-%m-%d %H:%M:%S')"

# Push to GitHub
git push origin main

echo "Sync complete!"
