#!/usr/bin/env bash
# install_wayland_sway.sh - Sway + Wayland desktop tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_available_packages() {
    local label="$1"; shift
    local -a pkgs=("$@")
    local -a available=()

    for pkg in "${pkgs[@]}"; do
        if package_available "${pkg}"; then
            available+=("${pkg}")
        else
            log_warn "Package '${pkg}' not found with ${PACKAGE_MANAGER}; skipping."
        fi
    done

    if (( ${#available[@]} )); then
        install_packages "${available[@]}"
        record_summary "Wayland" "${label}: ${available[*]}"
    fi
}

install_core() {
    install_available_packages "core" \
        sway waybar wofi swaync swww grim slurp wl-clipboard foot \
        xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-utils
}

install_media() {
    install_available_packages "media" \
        pipewire pipewire-pulse wireplumber playerctl pulsemixer
}

install_tools() {
    install_available_packages "tools" \
        yazi ffmpegthumbnailer unar poppler p7zip ueberzugpp light
}

install_apps() {
    install_available_packages "apps" \
        brave firefox chromium vscodium
}

install_theming() {
    install_available_packages "theming" \
        rose-pine-gtk-theme rose-pine-icon-theme
}

run_wayland_sway() {
    local -a available_keys=(core media tools apps theming dotfiles)
    mapfile -t selections < <(prompt_choices \
        "Choose Wayland/Sway components to install:" \
        "core media tools apps theming" \
        "all:Install every Wayland/Sway component" \
        "core:Sway + Wayland essentials" \
        "media:PipeWire, PulseAudio compatibility, playerctl" \
        "tools:File tools (yazi, thumbnails, archives, light)" \
        "apps:Browsers + VSCodium" \
        "theming:Rose Pine GTK/icon themes" \
        "dotfiles:Deploy Wayland dotfiles")

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            core) install_core ;;
            media) install_media ;;
            tools) install_tools ;;
            apps) install_apps ;;
            theming) install_theming ;;
            dotfiles) run_module "${SCRIPT_DIR}/install_dotfiles.sh" ;;
        esac
    done
}

run_wayland_sway
