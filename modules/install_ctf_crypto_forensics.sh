#!/usr/bin/env bash
# install_ctf_crypto_forensics.sh - Crypto & Forensics tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

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

    for item in "${selections[@]}"; do
        case "${item}" in
            hashcat)
                if install_packages hashcat opencl-mesa; then
                    record_summary "Crypto" "Hashcat"
                else
                    log_warn "Failed to install Hashcat."
                fi
                ;;
            john)
                if install_packages john; then
                    record_summary "Crypto" "John the Ripper"
                else
                    log_warn "Failed to install John the Ripper."
                fi
                ;;
            cyberchef)
                if install_packages cyberchef; then
                    record_summary "Forensics" "CyberChef"
                else
                    log_warn "Failed to install CyberChef."
                fi
                ;;
            binwalk)
                if install_packages binwalk squashfs-tools gzip bzip2 tar; then
                    record_summary "Forensics" "binwalk"
                else
                    log_warn "Failed to install binwalk or its dependencies."
                fi
                ;;
            volatility)
                if install_packages volatility3; then
                    record_summary "Forensics" "Volatility3"
                else
                    log_warn "Failed to install Volatility3."
                fi
                ;;
            stegsolve)
                if install_packages stegsolve; then
                    record_summary "Forensics" "Stegsolve"
                else
                    log_warn "Failed to install Stegsolve."
                fi
                ;;
            sleuthkit)
                if install_packages sleuthkit autopsy; then
                    record_summary "Forensics" "Sleuth Kit & Autopsy"
                else
                    log_warn "Failed to install Sleuth Kit & Autopsy."
                fi
                ;;
            ghidra)
                if command -v ghidra >/dev/null 2>&1; then
                    record_summary "Forensics" "Ghidra already present"
                elif install_packages ghidra; then
                    record_summary "Forensics" "Ghidra"
                else
                    log_warn "Failed to install Ghidra."
                fi
                ;;
        esac
    done
}

install_crypto_forensics
