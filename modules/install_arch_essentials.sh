#!/usr/bin/env bash
# install_arch_essentials.sh - Arch essentials and base tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_arch_packages() {
    mapfile -t essentials < <(prompt_choices \
        "Select base packages to install:" \
        "update base-devel network utils virtualbox" \
        "update:System update & keyring refresh" \
        "base-devel:base-devel toolchain" \
        "network:Networking utilities (net-tools, inetutils, traceroute)" \
        "virtualbox:Virtualization support (VirtualBox detection)" \
        "utils:System utilities (htop, lsof, p7zip, unzip, zip)" \
        "containers:Podman stack" \
        "fonts:Base fonts (ttf-dejavu, liberation)" )

    for choice in "${essentials[@]}"; do
        case "${choice}" in
            update)
                perform_system_update
                install_packages archlinux-keyring
                record_summary "System" "Updated via ${PACKAGE_MANAGER}"
                ;;
            base-devel)
                install_packages base-devel git cmake ninja
                record_summary "Packages" "base-devel"
                ;;
            network)
                install_packages net-tools inetutils traceroute nmap openbsd-netcat tcpdump
                record_summary "Packages" "networking tools"
                ;;
            virtualbox)
                virt="$(detect_virtualbox)"
                if [[ "${virt}" == "virtualbox" ]]; then
                    local utils_pkg="virtualbox-guest-utils"
                    if ! pacman_has_package "${utils_pkg}" && pacman_has_package "virtualbox-guest-utils-nox"; then
                        utils_pkg="virtualbox-guest-utils-nox"
                    fi

                    local modules_pkg=""
                    if [[ "$(uname -r)" == *"-arch"* ]]; then
                        modules_pkg="virtualbox-guest-modules-arch"
                    else
                        modules_pkg="virtualbox-guest-dkms"
                    fi
                    if [[ -n "${modules_pkg}" && ! pacman_has_package "${modules_pkg}" ]]; then
                        if pacman_has_package "virtualbox-guest-dkms"; then
                            modules_pkg="virtualbox-guest-dkms"
                        else
                            modules_pkg=""
                        fi
                    fi

                    local -a packages=("${utils_pkg}")
                    if [[ -n "${modules_pkg}" ]]; then
                        packages+=("${modules_pkg}")
                    fi

                    if [[ ${#packages[@]} -eq 0 ]]; then
                        log_warn "No suitable VirtualBox guest packages found in repositories; skipping."
                        record_summary "VirtualBox" "Skipped (packages unavailable)"
                    else
                        local install_ok=0
                        if install_packages "${packages[@]}"; then
                            install_ok=1
                        else
                            log_error "${PACKAGE_MANAGER} failed to install VirtualBox guest packages (${packages[*]})."
                        fi
                        if (( install_ok )); then
                            sudo systemctl enable --now vboxservice.service || log_warn "Could not enable vboxservice; verify manually."
                            record_summary "VirtualBox" "Guest additions installed (${packages[*]})"
                        else
                            record_summary "VirtualBox" "Guest additions installation failed"
                        fi
                    fi
                else
                    log_warn "VirtualBox not detected (found: ${virt}); skipping guest additions."
                    record_summary "VirtualBox" "Skipped (not detected)"
                fi
                ;;
            utils)
                install_packages htop lsof p7zip unzip zip tree wget curl bind ripgrep rsync
                record_summary "Packages" "System utilities"
                ;;
            containers)
                install_packages podman podman-docker buildah skopeo
                sudo systemctl enable --now podman.socket
                record_summary "Containers" "Podman stack"
                ;;
            fonts)
                install_packages ttf-dejavu ttf-liberation noto-fonts
                record_summary "Fonts" "Base fonts"
                ;;
        esac
    done
}

install_arch_packages
