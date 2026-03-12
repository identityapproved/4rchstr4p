#!/usr/bin/env bash
# install_dotfiles.sh - Deploy provided dotfiles into the user home.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
DOTFILES_DIR="${ROOT_DIR}/dotfiles"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

backup_path() {
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

    backup_path "${dest}"
    install -Dm"${mode}" "${src}" "${dest}"
    log_info "Deployed $(basename "${src}") to ${dest}"
}

deploy_dir() {
    local src="$1"
    local dest="$2"

    backup_path "${dest}"
    mkdir -p "${dest}"
    cp -a "${src}/." "${dest}/"
    log_info "Deployed $(basename "${src}") to ${dest}"
}

install_dotfiles() {
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log_warn "Dotfiles directory ${DOTFILES_DIR} not found; skipping."
        return
    fi

    deploy_file "${DOTFILES_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
    deploy_file "${DOTFILES_DIR}/zsh/.aliases" "${HOME}/.aliases"
    if [[ -f "${DOTFILES_DIR}/zsh/.ctf.aliases" ]]; then
        deploy_file "${DOTFILES_DIR}/zsh/.ctf.aliases" "${HOME}/.ctf.aliases"
    fi

    if [[ -f "${DOTFILES_DIR}/vim/.vimrc" ]]; then
        deploy_file "${DOTFILES_DIR}/vim/.vimrc" "${HOME}/.vimrc"
    fi

    if [[ -f "${DOTFILES_DIR}/tmux/tmux.conf" ]]; then
        deploy_file "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
    fi

    if command -v alacritty >/dev/null 2>&1 && [[ -f "${DOTFILES_DIR}/alacritty/alacritty.toml" ]]; then
        deploy_file "${DOTFILES_DIR}/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/waybar" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/waybar" "${HOME}/.config/waybar"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/wofi" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/wofi" "${HOME}/.config/wofi"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/foot" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/foot" "${HOME}/.config/foot"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/lsd" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/lsd" "${HOME}/.config/lsd"
    fi

    if [[ -f "${DOTFILES_DIR}/rose-pine/yazi/theme.toml" ]]; then
        deploy_file "${DOTFILES_DIR}/rose-pine/yazi/theme.toml" "${HOME}/.config/yazi/theme.toml"
    fi

    if [[ -f "${DOTFILES_DIR}/rose-pine/fzf/rose-pine.sh" ]]; then
        deploy_file "${DOTFILES_DIR}/rose-pine/fzf/rose-pine.sh" "${HOME}/.config/fzf/rose-pine.sh"
    fi

    if [[ -f "${DOTFILES_DIR}/rose-pine/wallpaper-cycle.sh" ]]; then
        deploy_file "${DOTFILES_DIR}/rose-pine/wallpaper-cycle.sh" "${HOME}/.local/bin/wallpaper-cycle" "755"
    fi

    if [[ -f "${DOTFILES_DIR}/wayland/bin/configure-gtk" ]]; then
        deploy_file "${DOTFILES_DIR}/wayland/bin/configure-gtk" "${HOME}/.local/bin/configure-gtk" "755"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/wallpapers" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/wallpapers" "${HOME}/.local/share/wallpapers/rose-pine"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/startpage" ]]; then
        deploy_dir "${DOTFILES_DIR}/rose-pine/startpage" "${HOME}/.local/share/startpage"
    fi

    if [[ -d "${DOTFILES_DIR}/rose-pine/zsh/themes" ]]; then
        if [[ -d "${HOME}/.oh-my-zsh/custom" ]]; then
            deploy_dir "${DOTFILES_DIR}/rose-pine/zsh/themes" "${HOME}/.oh-my-zsh/custom/themes"
        else
            deploy_dir "${DOTFILES_DIR}/rose-pine/zsh/themes" "${HOME}/.config/zsh/themes"
        fi
    fi

    record_summary "Dotfiles" "Dotfiles deployed from repository"
}

install_dotfiles
