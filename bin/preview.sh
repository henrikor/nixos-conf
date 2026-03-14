#!/usr/bin/env bash
set -euo pipefail

# Simple image preview helper using fzf + viu, falls tilbake til kitty icat hvis tilgjengelig.
dir=${1:-.}

file=$(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' \) | fzf --preview 'viu -w 60 {}' --preview-window=right:60%)

if [ -n "${file}" ]; then
  if command -v kitty >/dev/null 2>&1; then
    kitty +kitten icat --silent "$file"
  else
    viu "$file"
  fi
fi
