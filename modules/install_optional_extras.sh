#!/usr/bin/env bash
# install_optional_extras.sh - Optional extras: prompts, terminals, QoL.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

install_posh() {
    install_packages pacman oh-my-posh
    record_summary "Extras" "oh-my-posh"
}

install_starship() {
    install_packages pacman starship
    record_summary "Extras" "Starship prompt"
}

install_terminal_theme() {
    install_packages pacman alacritty
    record_summary "Extras" "Alacritty terminal"
}

install_misc() {
    install_packages pacman neofetch yq
    record_summary "Extras" "neofetch, yq"
}

run_optional_extras() {
    mapfile -t selections < <(multi_select \
        --title "Optional Extras" \
        --prompt "Choose optional extras to install:" \
        --options \
            "posh:oh-my-posh prompt" \
            "starship:Starship prompt" \
            "terminal:Alacritty terminal emulator" \
            "misc:Misc extras (neofetch, yq)" )

    for item in "${selections[@]}"; do
        case "${item}" in
            posh) install_posh ;;
            starship) install_starship ;;
            terminal) install_terminal_theme ;;
            misc) install_misc ;;
        esac
    done
}

run_optional_extras
