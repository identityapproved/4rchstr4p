#!/usr/bin/env bash
# install_ctf_reversing.sh - Reversing tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"

install_reversing() {
    mapfile -t selections < <(prompt_choices \
        "Choose reversing tools:" \
        "ghidra radare cutter" \
        "ghidra:Ghidra (AUR download)" \
        "radare:radare2 suite" \
        "cutter:Cutter GUI" \
        "binaryninja:Binary Ninja (manual install)" \
        "frida:Frida tools")

    local helper
    helper="$(require_aur_helper || true)"

    for item in "${selections[@]}"; do
        case "${item}" in
            ghidra)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" ghidra
                    record_summary "Reversing" "Ghidra"
                else
                    log_warn "Ghidra requires AUR helper; skipped."
                fi
                ;;
            radare)
                install_packages pacman radare2 radare2-cutter
                record_summary "Reversing" "radare2"
                ;;
            cutter)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" cutter
                else
                    install_packages pacman cutter
                fi
                record_summary "Reversing" "Cutter"
                ;;
            binaryninja)
                log_warn "Binary Ninja not available via repos; install manually."
                record_summary "Reversing" "Binary Ninja (manual)"
                ;;
            frida)
                install_packages pacman python-frida frida-tools
                record_summary "Reversing" "Frida"
                ;;
        esac
    done
}

install_reversing
