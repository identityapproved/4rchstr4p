#!/usr/bin/env bash
# install_shell_tools.sh - shells, editors, dotfiles, and CLI niceties.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_shell() {
    local shell="$1"
    install_packages "${shell}"
    record_summary "Shell" "${shell}"
}

install_fzf() {
    install_packages fzf fd
    record_summary "CLI" "fzf + fd"
}

install_tmux() {
    install_packages tmux
    record_summary "Terminal" "tmux"
}

install_misc_cli() {
    install_packages bat exa tree ripgrep fd dust procs jq zoxide
    record_summary "CLI" "bat, exa, tree, ripgrep, fd, dust, procs, jq, zoxide"
}

install_fonts() {
    mapfile -t fonts < <(prompt_choices \
        "Select nerd fonts to install:" \
        "nerd firacode jetbrains" \
        "nerd:nerd-fonts meta package" \
        "firacode:ttf-fira-code" \
        "jetbrains:ttf-jetbrains-mono" \
        "iosevka:ttf-iosevka-nerd (AUR)" \
        "powerline:powerline-fonts")
    for font in "${fonts[@]}"; do
        case "${font}" in
            nerd)
                if install_packages nerd-fonts; then
                    record_summary "Fonts" "Nerd Fonts collection"
                else
                    log_warn "Failed to install Nerd Fonts meta package."
                fi
                ;;
            iosevka)
                if install_packages ttf-iosevka-nerd; then
                    record_summary "Fonts" "Iosevka Nerd"
                else
                    log_warn "Failed to install Iosevka Nerd font with ${PACKAGE_MANAGER}; verify repository availability."
                fi
                ;;
            firacode)
                if install_packages ttf-fira-code; then
                    record_summary "Fonts" "FiraCode"
                else
                    log_warn "Failed to install FiraCode font."
                fi
                ;;
            jetbrains)
                if install_packages ttf-jetbrains-mono; then
                    record_summary "Fonts" "JetBrains Mono"
                else
                    log_warn "Failed to install JetBrains Mono font."
                fi
                ;;
            powerline)
                if install_packages powerline-fonts; then
                    record_summary "Fonts" "Powerline fonts"
                else
                    log_warn "Failed to install powerline fonts."
                fi
                ;;
        esac
    done
}

choose_editor() {
    prompt_single_choice \
        "Select the editor stack to install:" \
        "neovim" \
        "neovim:Neovim + LazyVim starter" \
        "vim:Vim (classic)"
}

install_vim() {
    install_packages vim
    record_summary "Editor" "Vim"
}

install_fnm_runtime() {
    if ! command -v fnm >/dev/null 2>&1; then
        install_packages fnm
    fi

    if command -v fnm >/dev/null 2>&1; then
        eval "$(fnm env --shell bash)"
        local lts_ref="lts-latest"
        local fallback_ref="latest"
        local chosen=""

        if fnm install "${lts_ref}" >/dev/null 2>&1; then
            chosen="${lts_ref}"
            log_info "[fnm] Installed Node.js ${lts_ref}"
        elif fnm install "${fallback_ref}" >/dev/null 2>&1; then
            chosen="${fallback_ref}"
            log_warn "fnm fell back to ${fallback_ref}."
        else
            log_warn "fnm failed to install Node.js runtime; LazyVim node tooling may be unavailable."
        fi

        if [[ -n "${chosen}" ]]; then
            fnm default "${chosen}" >/dev/null 2>&1 || log_warn "Unable to set fnm default to ${chosen}."
        fi
    fi
}

setup_lazyvim() {
    local nvim_dir="${HOME}/.config/nvim"
    ensure_command git git

    install_packages neovim ripgrep fd unzip python-pynvim
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
    mapfile -t selections < <(prompt_choices \
        "Choose shell tooling to install/configure:" \
        "zsh editor fzf tmux misc fonts dotfiles zsh_plugins" \
        "zsh:Install Zsh" \
        "fish:Install Fish shell" \
        "editor:Configure editor (Vim/Neovim)" \
        "fzf:fzf fuzzy finder" \
        "tmux:tmux terminal multiplexer" \
        "misc:Misc CLI tools (bat, exa, tree, ripgrep, jq...)" \
        "fonts:Nerd fonts selection" \
        "dotfiles:Deploy repository dotfiles" \
        "zsh_plugins:Install Oh My Zsh custom plugins")

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
