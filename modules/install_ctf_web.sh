#!/usr/bin/env bash
# install_ctf_web.sh - Web exploitation tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"

install_web_tools() {
    mapfile -t selections < <(prompt_choices \
        "Choose web exploitation tools:" \
        "burp zap dirsearch gobuster wfuzz sqlmap" \
        "burp:Burp Suite Community (AUR)" \
        "zap:OWASP ZAP" \
        "dirsearch:dirsearch" \
        "gobuster:gobuster" \
        "wfuzz:wfuzz" \
        "sqlmap:sqlmap" \
        "ffuf:ffuf (AUR)")

    local helper
    helper="$(require_aur_helper || true)"

    for item in "${selections[@]}"; do
        case "${item}" in
            burp)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" burpsuite
                    record_summary "Web" "Burp Suite"
                else
                    log_warn "Burp Suite requires AUR helper; skipped."
                fi
                ;;
            zap)
                install_packages pacman zaproxy
                record_summary "Web" "OWASP ZAP"
                ;;
            dirsearch)
                install_packages pacman dirsearch
                record_summary "Web" "dirsearch"
                ;;
            gobuster)
                install_packages pacman gobuster
                record_summary "Web" "gobuster"
                ;;
            wfuzz)
                install_packages pacman wfuzz
                record_summary "Web" "wfuzz"
                ;;
            sqlmap)
                install_packages pacman sqlmap
                record_summary "Web" "sqlmap"
                ;;
            ffuf)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" ffuf
                    record_summary "Web" "ffuf"
                else
                    log_warn "ffuf requires AUR helper; skipped."
                fi
                ;;
        esac
    done
}

install_web_tools
