#!/usr/bin/env bash
# install_ctf_pwn.sh - Pwn tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

ensure_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        install_packages pipx
    fi
}

ensure_pipx

install_pwn_tools() {
    mapfile -t selections < <(prompt_choices \
        "Choose pwn tooling:" \
        "pwntools gef ropgadget qemu" \
        "pwntools:pwntools (pipx)" \
        "gef:GEF for GDB" \
        "pwndbg:pwndbg (AUR)" \
        "ropgadget:ROPgadget (pipx)" \
        "one_gadget:one_gadget (AUR)" \
        "qemu:QEMU full suite")

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
                if install_packages qemu qemu-arch-extra; then
                    record_summary "Pwn" "QEMU suite"
                else
                    log_warn "Failed to install QEMU suite."
                fi
                ;;
        esac
    done
}

install_pwn_tools
