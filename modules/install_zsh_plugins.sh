#!/usr/bin/env bash
# install_zsh_plugins.sh - Manage Oh My Zsh custom plugins.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

ensure_git() {
    if ! command -v git >/dev/null 2>&1; then
        install_packages pacman git
    fi
}

sync_plugin_repo() {
    local repo="$1"
    local name="$2"
    local dest="$3"

    if [[ -d "${dest}/.git" ]]; then
        log_info "Updating ${name} plugin."
        git -C "${dest}" pull --ff-only >/dev/null 2>&1 || {
            log_warn "Failed fast-forward on ${name}; keeping existing copy."
        }
    elif [[ -d "${dest}" ]]; then
        log_warn "Destination ${dest} exists without git metadata; skipping ${name}."
    else
        log_info "Cloning ${name} plugin."
        git clone --depth 1 "${repo}" "${dest}" >/dev/null 2>&1 || {
            log_warn "Clone failed for ${name}."
        }
    fi
}

install_zsh_plugins() {
    ensure_git

    local custom_root="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
    local plugin_dir="${custom_root}/plugins"
    mkdir -p "${plugin_dir}"

    local -a plugins=(
        "https://github.com/zsh-users/zsh-syntax-highlighting.git:zsh-syntax-highlighting"
        "https://github.com/zsh-users/zsh-autosuggestions.git:zsh-autosuggestions"
        "https://github.com/zshzoo/cd-ls.git:cd-ls"
        "https://github.com/jeffreytse/zsh-vi-mode.git:zsh-vi-mode"
        "https://github.com/djui/alias-tips.git:alias-tips"
        "https://github.com/thirteen37/fzf-alias.git:fzf-alias"
        "https://github.com/wbingli/zsh-wakatime.git:zsh-wakatime"
        "https://github.com/alexiszamanidis/zsh-git-fzf.git:zsh-git-fzf"
    )

    for entry in "${plugins[@]}"; do
        IFS=":" read -r repo name <<<"${entry}"
        sync_plugin_repo "${repo}" "${name}" "${plugin_dir}/${name}"
    done

    record_summary "Zsh" "Custom plugins synced"
}

install_zsh_plugins
