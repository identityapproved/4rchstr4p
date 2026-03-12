#!/usr/bin/env bash
# install_optional_extras.sh - Optional extras: prompts, terminals, QoL.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_posh() {
    install_packages oh-my-posh
    record_summary "Extras" "oh-my-posh"
}

install_starship() {
    install_packages starship
    record_summary "Extras" "Starship prompt"
}

install_terminal_theme() {
    install_packages alacritty
    record_summary "Extras" "Alacritty terminal"
}

install_misc() {
    install_packages neofetch yq
    record_summary "Extras" "neofetch, yq"
}

run_optional_extras() {
    local -a available_keys=(posh starship terminal misc)
    mapfile -t selections < <(prompt_choices \
        "Choose optional extras to install:" \
        "all" \
        "all:Install every optional extra" \
        "posh:oh-my-posh prompt" \
        "starship:Starship prompt" \
        "terminal:Alacritty terminal emulator" \
        "misc:Misc extras (neofetch, yq)")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )) || [[ "${#selections[@]}" -eq 0 ]]; then
        log_info "Skipping optional extras module."
        return
    fi

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

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
