#!/usr/bin/env bash
# install_shell_tools.sh - shells, editors, and CLI niceties.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

install_shell() {
    local shell="$1"
    install_packages pacman "${shell}"
    record_summary "Shell" "${shell}"
}

install_fzf() {
    install_packages pacman fzf fd
    record_summary "CLI" "fzf + fd"
}

install_editor() {
    install_packages pacman neovim
    record_summary "Editor" "Neovim"
}

install_tmux() {
    install_packages pacman tmux
    record_summary "Terminal" "tmux"
}

install_misc_cli() {
    install_packages pacman bat exa tree ripgrep fd dust procs jq
    record_summary "CLI" "bat, exa, tree, ripgrep, fd, dust, procs, jq"
}

install_fonts() {
    mapfile -t fonts < <(multi_select \
        --title "Fonts" \
        --prompt "Select nerd fonts to install:" \
        --default "iosevka firacode" \
        --options \
            "iosevka:ttf-iosevka-nerd (AUR)" \
            "firacode:nerd-fonts-fira-code" \
            "jetbrains:nerd-fonts-jetbrains-mono" \
            "powerline:powerline-fonts" )
    local helper
    helper="$(require_aur_helper || true)"
    for font in "${fonts[@]}"; do
        case "${font}" in
            iosevka)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" ttf-iosevka-nerd
                    record_summary "Fonts" "Iosevka Nerd"
                else
                    log_warn "Iosevka Nerd requires AUR helper; skipped."
                fi
                ;;
            firacode)
                install_packages pacman nerd-fonts-fira-code
                record_summary "Fonts" "FiraCode Nerd"
                ;;
            jetbrains)
                install_packages pacman nerd-fonts-jetbrains-mono
                record_summary "Fonts" "JetBrainsMono Nerd"
                ;;
            powerline)
                install_packages pacman powerline-fonts
                record_summary "Fonts" "Powerline fonts"
                ;;
        esac
    done
}

run_shell_tools() {
    mapfile -t selections < <(multi_select \
        --title "Shell & Terminal" \
        --prompt "Choose shell tooling to install/configure:" \
        --default "zsh fzf nvim tmux misc fonts" \
        --options \
            "zsh:Install Zsh" \
            "fish:Install Fish shell" \
            "fzf:fzf fuzzy finder" \
            "nvim:Neovim editor" \
            "tmux:tmux terminal multiplexer" \
            "misc:Misc CLI tools (bat, exa, tree, ripgrep, jq...)" \
            "fonts:Nerd fonts selection" )

    for item in "${selections[@]}"; do
        case "${item}" in
            zsh) install_shell zsh ;;
            fish) install_shell fish ;;
            fzf) install_fzf ;;
            nvim) install_editor ;;
            tmux) install_tmux ;;
            misc) install_misc_cli ;;
            fonts) install_fonts ;;
        esac
    done
}

run_shell_tools
