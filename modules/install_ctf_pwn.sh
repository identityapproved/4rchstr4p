#!/usr/bin/env bash
# install_ctf_pwn.sh - Pwn tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

ensure_pipx

install_pwn_tools() {
    mapfile -t selections < <(multi_select \
        --title "Pwn" \
        --prompt "Choose pwn tooling:" \
        --default "pwntools gef ropgadget qemu" \
        --options \
            "pwntools:pwntools (pipx)" \
            "gef:GEF for GDB" \
            "pwndbg:pwndbg (AUR)" \
            "ropgadget:ROPgadget (pipx)" \
            "one_gadget:one_gadget (AUR)" \
            "qemu:QEMU full suite" )

    local helper
    helper="$(require_aur_helper || true)"

    for item in "${selections[@]}"; do
        case "${item}" in
            pwntools)
                pipx install --force pwntools
                record_summary "Pwn" "pwntools via pipx"
                ;;
            gef)
                install_packages pacman gdb curl
                if [[ ! -f "${HOME}/.gdbinit-gef.py" ]]; then
                    curl -fsSL https://gef.blah.cat/sh | sh
                fi
                record_summary "Pwn" "GEF"
                ;;
            pwndbg)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" pwndbg
                    record_summary "Pwn" "pwndbg"
                else
                    log_warn "pwndbg requires AUR helper; skipped."
                fi
                ;;
            ropgadget)
                pipx install --force ropgadget
                record_summary "Pwn" "ROPgadget via pipx"
                ;;
            one_gadget)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" one_gadget
                    record_summary "Pwn" "one_gadget"
                else
                    log_warn "one_gadget requires AUR helper; skipped."
                fi
                ;;
            qemu)
                install_packages pacman qemu qemu-arch-extra
                record_summary "Pwn" "QEMU suite"
                ;;
        esac
    done
}

install_pwn_tools
