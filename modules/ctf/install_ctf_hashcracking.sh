#!/usr/bin/env bash
# install_ctf_hashcracking.sh - Hash cracking tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_hashcracking() {
    local -a available_keys=(hashcat john hcxtools hashid)
    mapfile -t selections < <(prompt_choices \
        "Choose hash cracking tools:" \
        "all" \
        "all:Install every hash cracking tool" \
        "hashcat:Hashcat + OpenCL" \
        "john:John the Ripper jumbo" \
        "hcxtools:WPA/WPA2 capture conversion tools" \
        "hashid:Hash type identifier")

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            hashcat)
                if install_packages hashcat opencl-mesa; then
                    record_summary "Hashcracking" "Hashcat"
                else
                    log_warn "Failed to install Hashcat."
                fi
                ;;
            john)
                if install_packages john; then
                    record_summary "Hashcracking" "John the Ripper"
                else
                    log_warn "Failed to install John the Ripper."
                fi
                ;;
            hcxtools)
                if install_packages hcxtools; then
                    record_summary "Hashcracking" "hcxtools"
                else
                    log_warn "Failed to install hcxtools."
                fi
                ;;
            hashid)
                if install_packages hashid; then
                    record_summary "Hashcracking" "hashid"
                else
                    log_warn "Failed to install hashid."
                fi
                ;;
        esac
    done
}

install_hashcracking
