#!/bin/bash
# File: git-clean-branches.sh
# Description: Interactive Git branch cleaner (keeps only main/master) with live repo preview

# --- Requirements ---
# Packages needed: fzf, tree, git
# ---------------------

# Find Git repos in current directory
repos=($(find . -maxdepth 1 -type d -exec test -d "{}/.git" \; -print | sed 's|^\./||'))

if [ ${#repos[@]} -eq 0 ]; then
  echo "No git repositories found in current directory."
  exit 1
fi

# Interactive repo selector with tree preview
echo "Select a repository to clean (use ↑↓ to navigate, Enter to select):"
selected_repo=$(printf '%s\n' "${repos[@]}" | fzf \
  --prompt="Repo> " \
  --height=40% \
  --preview 'tree -L 2 --dirsfirst --noreport {} 2>/dev/null || echo "No preview available"' \
  --preview-window=right:60%:wrap)

if [ -z "$selected_repo" ]; then
  echo "No selection made. Exiting."
  exit 1
fi

cd "$selected_repo" || exit 1
echo
echo "Cleaning repository: $selected_repo"
echo

# Ensure we're on main or master
if git rev-parse --verify main &>/dev/null; then
  git switch main >/dev/null 2>&1 || git checkout main
elif git rev-parse --verify master &>/dev/null; then
  git switch master >/dev/null 2>&1 || git checkout master
else
  echo "No 'main' or 'master' branch found."
  exit 1
fi

# Preview branches to delete
echo "Previewing branches to delete:"
git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vE '^(main|master)$'
git for-each-ref --format='%(refname:short)' refs/remotes/origin | sed 's@^origin/@@' | grep -vE '^(HEAD|main|master)$'
echo

read -p "Proceed with deletion? [y/N]: " confirm
[[ $confirm =~ ^[Yy]$ ]] || {
  echo "Cancelled."
  exit 0
}

# Delete local branches except main/master
git for-each-ref --format='%(refname:short)' refs/heads/ |
  grep -vE '^(main|master)$' |
  xargs -r git branch -D

# Delete remote branches except main/master
git for-each-ref --format='%(refname:short)' refs/remotes/origin |
  sed 's@^origin/@@' |
  grep -vE '^(HEAD|main|master)$' |
  xargs -r -n1 git push origin --delete

# Prune stale refs
git fetch --prune

echo
echo "Cleanup complete for '$selected_repo'."
echo "---------------------------------------"
echo "Remaining branches:"
echo
echo "Local branches:"
git branch
echo
echo "Remote branches:"
git branch -r
