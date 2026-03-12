#!/usr/bin/env bash
# install_ctf_pwn.sh - Pwn tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

ensure_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        install_packages python-pipx
    fi
}

ensure_pipx

select_qemu_variant() {
    local variant
    variant="$(prompt_single_choice \
        "Choose QEMU package variant (0 or q to cancel):" \
        "qemu-full" \
        "qemu-full:Full feature set with GUI and extra targets" \
        "qemu-base:Minimal headless build" \
        "qemu-desktop:Desktop-focused (x86_64 emulation)")"

    if (( PROMPT_CHOICES_EXIT_REQUESTED )); then
        PROMPT_CHOICES_EXIT_REQUESTED=0
        echo ""
        return
    fi

    if [[ -z "${variant}" ]]; then
        variant="qemu-full"
    fi
    printf "%s\n" "${variant}"
}

select_qemu_optional_packages() {
    local -a extra_keys=(libvirt virt-manager virt-viewer dnsmasq bridge-utils ovmf swtpm vde2 qemu-guest-agent)
    mapfile -t _extras < <(prompt_choices \
        "Select optional QEMU companion packages (0 or q to skip):" \
        "all" \
        "all:Install every optional companion package" \
        "libvirt:Libvirt daemon and tooling" \
        "virt-manager:GUI management for libvirt" \
        "virt-viewer:SPICE/remote viewer" \
        "dnsmasq:DNS/DHCP helper for libvirt networks" \
        "bridge-utils:Bridge utilities for networking" \
        "ovmf:UEFI firmware (OVMF)" \
        "swtpm:Software TPM emulator" \
        "vde2:Virtual Distributed Ethernet suite" \
        "qemu-guest-agent:Guest agent for virtual machines")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )); then
        PROMPT_CHOICES_EXIT_REQUESTED=0
        return
    fi

    if [[ " ${_extras[*]} " == *" all "* ]]; then
        _extras=("${extra_keys[@]}")
    fi

    for pkg in "${_extras[@]}"; do
        printf "%s\n" "${pkg}"
    done
}

install_pwn_tools() {
    local -a available_keys=(pwntools gef pwndbg ropgadget one_gadget qemu)
    mapfile -t selections < <(prompt_choices \
        "Choose pwn tooling:" \
        "all" \
        "all:Install every pwn tooling option" \
        "pwntools:pwntools (pipx)" \
        "gef:GEF for GDB" \
        "pwndbg:pwndbg (AUR)" \
        "ropgadget:ROPgadget (pipx)" \
        "one_gadget:one_gadget (AUR)" \
        "qemu:QEMU full suite")

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            pwntools)
                pipx install --force pwntools
                record_summary "Pwn" "pwntools via pipx"
                ;;
            gef)
                install_packages gdb curl
                if [[ ! -f "${HOME}/.gdbinit-gef.py" ]]; then
                    curl -fsSL https://gef.blah.cat/sh | sh
                fi
                record_summary "Pwn" "GEF"
                ;;
            pwndbg)
                if install_packages pwndbg; then
                    record_summary "Pwn" "pwndbg"
                else
                    log_warn "Failed to install pwndbg."
                fi
                ;;
            ropgadget)
                pipx install --force ropgadget
                record_summary "Pwn" "ROPgadget via pipx"
                ;;
            one_gadget)
                if install_packages one_gadget; then
                    record_summary "Pwn" "one_gadget"
                else
                    log_warn "Failed to install one_gadget."
                fi
                ;;
            qemu)
                local variant
                variant="$(select_qemu_variant)"
                if [[ -z "${variant}" ]]; then
                    log_info "QEMU installation canceled."
                    continue
                fi

                local -a packages=("${variant}")
                mapfile -t optional_pkgs < <(select_qemu_optional_packages)
                if [[ "${#optional_pkgs[@]}" -gt 0 ]]; then
                    packages+=("${optional_pkgs[@]}")
                fi

                if install_packages "${packages[@]}"; then
                    local summary="QEMU (${variant})"
                    if [[ "${#optional_pkgs[@]}" -gt 0 ]]; then
                        summary+=" + extras: ${optional_pkgs[*]}"
                    fi
                    record_summary "Pwn" "${summary}"
                else
                    log_warn "Failed to install QEMU (${variant})."
                fi
                ;;
        esac
    done
}

install_pwn_tools
