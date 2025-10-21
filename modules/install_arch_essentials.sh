#!/usr/bin/env bash
# install_arch_essentials.sh - Arch essentials and base tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

prompt_helper_choice() {
    mapfile -t helper_choice < <(multi_select \
        --title "AUR Helper" \
        --prompt "Select an AUR helper to install (if none, skip):" \
        --options \
            "yay:Install yay (Go-based helper)" \
            "paru:Install paru (Rust-based helper)")
    echo "${helper_choice[0]:-}"
}

install_aur_helper() {
    local helper="$1"
    if [[ -z "${helper}" ]]; then
        log_warn "Skipping AUR helper installation."
        return
    fi
    if command -v "${helper}" >/dev/null 2>&1; then
        log_info "${helper} already present."
        record_summary "AUR helper" "${helper} (already present)"
        return
    fi

    log_info "Installing ${helper}."
    sudo pacman --noconfirm --needed -S base-devel git
    local tmpdir
    tmpdir="$(mktemp -d)"
    case "${helper}" in
        yay)
            git clone https://aur.archlinux.org/yay.git "${tmpdir}/yay"
            (cd "${tmpdir}/yay" && makepkg -si --noconfirm)
            ;;
        paru)
            git clone https://aur.archlinux.org/paru.git "${tmpdir}/paru"
            (cd "${tmpdir}/paru" && makepkg -si --noconfirm)
            ;;
        *)
            log_warn "Unknown helper '${helper}', skipping."
            ;;
    esac
    rm -rf "${tmpdir}"
    record_summary "AUR helper" "${helper}"
}

install_arch_packages() {
    mapfile -t essentials < <(multi_select \
        --title "Arch Essentials" \
        --prompt "Select base packages to install:" \
        --default "update base-devel network utils virtualbox" \
        --options \
            "update:System update & keyring refresh" \
            "base-devel:base-devel toolchain" \
            "network:Networking utilities (net-tools, inetutils, traceroute)" \
            "virtualbox:Virtualization support (VirtualBox detection)" \
            "utils:System utilities (htop, lsof, p7zip, unzip, zip)" \
            "containers:Podman stack" \
            "fonts:Base fonts (ttf-dejavu, liberation)" )

    local helper_manager
    helper_manager="$(aur_helper)"

    for choice in "${essentials[@]}"; do
        case "${choice}" in
            update)
                log_info "Refreshing package databases."
                sudo pacman -Syyu --noconfirm
                sudo pacman --noconfirm -S archlinux-keyring
                record_summary "System" "Full system upgrade"
                ;;
            base-devel)
                install_packages pacman base-devel git cmake ninja
                record_summary "Packages" "base-devel"
                ;;
            network)
                install_packages pacman net-tools inetutils traceroute nmap openbsd-netcat tcpdump
                record_summary "Packages" "networking tools"
                ;;
            virtualbox)
                virt="$(detect_virtualbox)"
                if [[ "${virt}" == "virtualbox" ]]; then
                    install_packages pacman virtualbox-guest-utils virtualbox-guest-modules-arch
                    sudo systemctl enable --now vboxservice.service
                    record_summary "VirtualBox" "Guest additions installed"
                else
                    log_warn "VirtualBox not detected (found: ${virt}); skipping guest additions."
                    record_summary "VirtualBox" "Skipped (not detected)"
                fi
                ;;
            utils)
                install_packages pacman htop lsof p7zip unzip zip tree wget curl bind ripgrep rsync
                record_summary "Packages" "System utilities"
                ;;
            containers)
                install_packages pacman podman podman-docker buildah skopeo
                sudo systemctl enable --now podman.socket
                record_summary "Containers" "Podman stack"
                ;;
            fonts)
                install_packages pacman ttf-dejavu ttf-liberation noto-fonts
                record_summary "Fonts" "Base fonts"
                ;;
        esac
    done

    if [[ -z "${helper_manager}" ]]; then
        helper="$(prompt_helper_choice)"
        install_aur_helper "${helper}"
    else
        log_info "Using existing AUR helper: ${helper_manager}"
        record_summary "AUR helper" "${helper_manager} (pre-existing)"
    fi
}

install_arch_packages
