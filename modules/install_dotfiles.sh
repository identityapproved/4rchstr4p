#!/usr/bin/env bash
# install_dotfiles.sh - Deploy provided dotfiles into the user home.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
DOTFILES_DIR="${ROOT_DIR}/dotfiles"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

backup_file() {
    local target="$1"
    if [[ -e "${target}" && ! -L "${target}" ]]; then
        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"
        local backup="${target}.bak.${timestamp}"
        log_info "Backing up ${target} to ${backup}"
        cp -a "${target}" "${backup}"
    fi
}

deploy_file() {
    local src="$1"
    local dest="$2"
    local mode="${3:-644}"

    backup_file "${dest}"
    install -Dm"${mode}" "${src}" "${dest}"
    log_info "Deployed $(basename "${src}") to ${dest}"
}

install_dotfiles() {
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log_warn "Dotfiles directory ${DOTFILES_DIR} not found; skipping."
        return
    fi

    deploy_file "${DOTFILES_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
    deploy_file "${DOTFILES_DIR}/zsh/.aliases" "${HOME}/.aliases"

    if [[ -f "${DOTFILES_DIR}/vim/.vimrc" ]]; then
        deploy_file "${DOTFILES_DIR}/vim/.vimrc" "${HOME}/.vimrc"
    fi

    if [[ -f "${DOTFILES_DIR}/tmux/tmux.conf" ]]; then
        deploy_file "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
    fi

    if command -v alacritty >/dev/null 2>&1 && [[ -f "${DOTFILES_DIR}/alacritty/alacritty.toml" ]]; then
        deploy_file "${DOTFILES_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
    fi

    record_summary "Dotfiles" "Core dotfiles deployed from repository"
}

install_dotfiles
