#!/usr/bin/env bash
# install_ctf_reversing.sh - Reversing tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_reversing() {
    local -a available_keys=(ghidra radare cutter binaryninja frida)
    mapfile -t selections < <(prompt_choices \
        "Choose reversing tools:" \
        "all" \
        "all:Install every reversing tool" \
        "ghidra:Ghidra (AUR download)" \
        "radare:radare2 suite" \
        "cutter:Cutter GUI" \
        "binaryninja:Binary Ninja (manual install)" \
        "frida:Frida tools")

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            ghidra)
                if install_packages ghidra; then
                    record_summary "Reversing" "Ghidra"
                else
                    log_warn "Failed to install Ghidra with ${PACKAGE_MANAGER}."
                fi
                ;;
            radare)
                if install_packages radare2 radare2-cutter; then
                    record_summary "Reversing" "radare2"
                else
                    log_warn "Failed to install radare2."
                fi
                ;;
            cutter)
                if install_packages cutter; then
                    record_summary "Reversing" "Cutter"
                else
                    log_warn "Failed to install Cutter."
                fi
                ;;
            binaryninja)
                log_warn "Binary Ninja not available via repos; install manually."
                record_summary "Reversing" "Binary Ninja (manual)"
                ;;
            frida)
                if install_packages python-frida frida-tools; then
                    record_summary "Reversing" "Frida"
                else
                    log_warn "Failed to install Frida tools."
                fi
                ;;
        esac
    done
}

install_reversing
