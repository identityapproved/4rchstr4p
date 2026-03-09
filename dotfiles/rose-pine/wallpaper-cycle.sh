#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/rose-pine"

if [[ ! -d "${WALLPAPER_DIR}" ]]; then
  exit 0
fi

mapfile -t wallpapers < <(find "${WALLPAPER_DIR}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  exit 0
fi

selected="${wallpapers[RANDOM % ${#wallpapers[@]}]}"

swww img "${selected}" --transition-type wipe --transition-duration 1
