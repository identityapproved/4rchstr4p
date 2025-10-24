#!/usr/bin/env bash
# install_shell_tools.sh - shells, editors, dotfiles, and CLI niceties.

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

choose_editor() {
    mapfile -t editor_choice < <(multi_select \
        --title "Editor Selection" \
        --prompt "Select the editor stack to install (choose one):" \
        --default "neovim" \
        --options \
            "neovim:Neovim + LazyVim starter" \
            "vim:Vim (classic)" )

    echo "${editor_choice[0]:-}"
}

install_vim() {
    install_packages pacman vim
    record_summary "Editor" "Vim"
}

install_fnm_runtime() {
    if ! command -v fnm >/dev/null 2>&1; then
        install_packages pacman fnm
    fi

    if command -v fnm >/dev/null 2>&1; then
        fnm install --lts >/dev/null 2>&1 || true
        fnm use --install-if-missing --lts >/dev/null 2>&1 || true
    fi
}

setup_lazyvim() {
    local nvim_dir="${HOME}/.config/nvim"
    ensure_command git git

    install_packages pacman neovim ripgrep fd unzip python-pynvim
    install_fnm_runtime

    if [[ -d "${nvim_dir}" && ! -L "${nvim_dir}" ]]; then
        local backup="${nvim_dir}.bak.$(date +%Y%m%d_%H%M%S)"
        log_warn "Existing Neovim config detected; backing up to ${backup}"
        mv "${nvim_dir}" "${backup}"
    fi

    if [[ -d "${nvim_dir}" ]]; then
        log_info "LazyVim directory already present; skipping clone."
    else
        git clone --depth 1 https://github.com/LazyVim/starter "${nvim_dir}"
        rm -rf "${nvim_dir}/.git"
    fi

    record_summary "Editor" "Neovim + LazyVim starter"
}

run_shell_tools() {
    mapfile -t selections < <(multi_select \
        --title "Shell & Terminal" \
        --prompt "Choose shell tooling to install/configure:" \
        --default "zsh editor fzf tmux misc fonts dotfiles zsh_plugins" \
        --options \
            "zsh:Install Zsh" \
            "fish:Install Fish shell" \
            "editor:Configure editor (Vim/Neovim)" \
            "fzf:fzf fuzzy finder" \
            "tmux:tmux terminal multiplexer" \
            "misc:Misc CLI tools (bat, exa, tree, ripgrep, jq...)" \
            "fonts:Nerd fonts selection" \
            "dotfiles:Deploy repository dotfiles" \
            "zsh_plugins:Install Oh My Zsh custom plugins" )

    for item in "${selections[@]}"; do
        case "${item}" in
            zsh)
                install_shell zsh
                ;;
            fish)
                install_shell fish
                ;;
            editor)
                case "$(choose_editor)" in
                    neovim)
                        setup_lazyvim
                        ;;
                    vim)
                        install_vim
                        ;;
                    *)
                        log_warn "No editor selection made; skipping editor setup."
                        ;;
                esac
                ;;
            fzf)
                install_fzf
                ;;
            tmux)
                install_tmux
                ;;
            misc)
                install_misc_cli
                ;;
            fonts)
                install_fonts
                ;;
            dotfiles)
                run_module "${SCRIPT_DIR}/install_dotfiles.sh"
                ;;
            zsh_plugins)
                run_module "${SCRIPT_DIR}/install_zsh_plugins.sh"
                ;;
        esac
    done
}

run_shell_tools
