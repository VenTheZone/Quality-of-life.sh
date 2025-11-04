#!/bin/bash

# Colors (ANSI)
GREEN='\033[0;32m'
NC='\033[0m'

# Generate one password
gen_pass() {
  cat /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 16
}

# Generate 5 passwords and sort them
passwords=()
for i in {1..5}; do
  passwords+=($(gen_pass))
done
sorted=($(printf '%s\n' "${passwords[@]}" | sort))

# Display
echo -e "${GREEN}Generated Passwords:${NC}"
echo "┌────────────────────────┐"
for i in "${!sorted[@]}"; do
  printf "│ %-24s │\n" "${sorted[$i]}"
  if [ $i -lt $((${#sorted[@]} - 1)) ]; then
    echo "│                        │"
  fi
done
echo "└────────────────────────┘"
