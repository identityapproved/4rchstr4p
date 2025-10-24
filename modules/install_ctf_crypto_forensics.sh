#!/usr/bin/env bash
# install_ctf_crypto_forensics.sh - Crypto & Forensics tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"

install_crypto_forensics() {
    mapfile -t selections < <(prompt_choices \
        "Choose crypto/forensics tools:" \
        "hashcat cyberchef binwalk volatility stegsolve" \
        "hashcat:Hashcat + OpenCL" \
        "john:John the Ripper jumbo" \
        "cyberchef:CyberChef (AUR)" \
        "binwalk:binwalk + dependencies" \
        "volatility:Volatility3" \
        "stegsolve:Stegsolve (AUR)" \
        "sleuthkit:Sleuth Kit & Autopsy" \
        "ghidra:Install Ghidra if missing")

    local helper
    helper="$(require_aur_helper || true)"

    for item in "${selections[@]}"; do
        case "${item}" in
            hashcat)
                install_packages pacman hashcat opencl-mesa
                record_summary "Crypto" "Hashcat"
                ;;
            john)
                install_packages pacman john
                record_summary "Crypto" "John the Ripper"
                ;;
            cyberchef)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" cyberchef
                    record_summary "Forensics" "CyberChef"
                else
                    log_warn "CyberChef requires AUR helper; skipped."
                fi
                ;;
            binwalk)
                install_packages pacman binwalk squashfs-tools gzip bzip2 tar
                record_summary "Forensics" "binwalk"
                ;;
            volatility)
                install_packages pacman volatility3
                record_summary "Forensics" "Volatility3"
                ;;
            stegsolve)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" stegsolve
                    record_summary "Forensics" "Stegsolve"
                else
                    log_warn "Stegsolve requires AUR helper; skipped."
                fi
                ;;
            sleuthkit)
                install_packages pacman sleuthkit autopsy
                record_summary "Forensics" "Sleuth Kit & Autopsy"
                ;;
            ghidra)
                if command -v ghidra >/dev/null 2>&1; then
                    record_summary "Forensics" "Ghidra already present"
                elif [[ -n "${helper}" ]]; then
                    install_packages "${helper}" ghidra
                    record_summary "Forensics" "Ghidra"
                else
                    log_warn "Ghidra requires AUR helper; skipped."
                fi
                ;;
        esac
    done
}

install_crypto_forensics
