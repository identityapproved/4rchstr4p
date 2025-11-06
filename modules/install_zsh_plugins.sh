#!/usr/bin/env bash
# install_zsh_plugins.sh - Manage Oh My Zsh custom plugins.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

ensure_git() {
    if ! command -v git >/dev/null 2>&1; then
        install_packages git
    fi
}

expand_path() {
    local raw="$1"
    if [[ "${raw}" == "~" ]]; then
        printf "%s\n" "${HOME}"
    elif [[ "${raw}" == ~* ]]; then
        printf "%s%s\n" "${HOME}" "${raw:1}"
    else
        printf "%s\n" "${raw}"
    fi
}

ensure_oh_my_zsh() {
    local omz_dir
    omz_dir="$(expand_path "${HOME}/.oh-my-zsh")"
    if [[ -d "${omz_dir}" ]]; then
        return
    fi

    ensure_git
    log_info "Installing Oh My Zsh framework."
    if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "${omz_dir}" >/dev/null 2>&1; then
        record_summary "Zsh" "Oh My Zsh installed"
    else
        log_warn "Failed to clone Oh My Zsh. Check network connectivity or clone manually."
    fi
}

sync_plugin_repo() {
    local repo="$1"
    local name="$2"
    local dest
    dest="$(expand_path "$3")"

    if [[ -d "${dest}/.git" ]]; then
        log_info "Updating ${name} plugin."
        git -C "${dest}" pull --ff-only >/dev/null 2>&1 || {
            log_warn "Failed fast-forward on ${name}; keeping existing copy."
        }
    elif [[ -d "${dest}" ]]; then
        log_warn "Destination ${dest} exists without git metadata; skipping ${name}."
    else
        log_info "Cloning ${name} plugin."
        if ! git clone --depth 1 "${repo}" "${dest}" >/dev/null 2>&1; then
            log_warn "Clone failed for ${name}; verify network and repository availability."
            return 1
        fi
    fi
}

install_zsh_plugins() {
    ensure_git
    ensure_oh_my_zsh

    local custom_root_raw="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
    local custom_root
    custom_root="$(expand_path "${custom_root_raw}")"
    export ZSH_CUSTOM="${custom_root}"

    local plugin_dir="${custom_root}/plugins"
    mkdir -p "${plugin_dir}"

    local -a plugins=(
        "https://github.com/zsh-users/zsh-syntax-highlighting.git:zsh-syntax-highlighting"
        "https://github.com/zsh-users/zsh-autosuggestions.git:zsh-autosuggestions"
        "https://github.com/zshzoo/cd-ls.git:cd-ls"
        "https://github.com/jeffreytse/zsh-vi-mode.git:zsh-vi-mode"
        "https://github.com/djui/alias-tips.git:alias-tips"
        "https://github.com/thirteen37/fzf-alias.git:fzf-alias"
        "https://github.com/zsh-users/zsh-history-substring-search.git:zsh-history-substring-search"
        "https://github.com/alexiszamanidis/zsh-git-fzf.git:zsh-git-fzf"
    )

    for entry in "${plugins[@]}"; do
        IFS=":" read -r repo name <<<"${entry}"
        sync_plugin_repo "${repo}" "${name}" "${plugin_dir}/${name}" || continue
    done

    record_summary "Zsh" "Custom plugins synced"
}

install_zsh_plugins
