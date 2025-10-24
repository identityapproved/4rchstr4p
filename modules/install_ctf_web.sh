#!/usr/bin/env bash
# install_ctf_web.sh - Web exploitation tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

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

    for item in "${selections[@]}"; do
        case "${item}" in
            burp)
                if install_packages burpsuite; then
                    record_summary "Web" "Burp Suite"
                else
                    log_warn "Failed to install Burp Suite."
                fi
                ;;
            zap)
                if install_packages zaproxy; then
                    record_summary "Web" "OWASP ZAP"
                else
                    log_warn "Failed to install OWASP ZAP."
                fi
                ;;
            dirsearch)
                if install_packages dirsearch; then
                    record_summary "Web" "dirsearch"
                else
                    log_warn "Failed to install dirsearch."
                fi
                ;;
            gobuster)
                if install_packages gobuster; then
                    record_summary "Web" "gobuster"
                else
                    log_warn "Failed to install gobuster."
                fi
                ;;
            wfuzz)
                if install_packages wfuzz; then
                    record_summary "Web" "wfuzz"
                else
                    log_warn "Failed to install wfuzz."
                fi
                ;;
            sqlmap)
                if install_packages sqlmap; then
                    record_summary "Web" "sqlmap"
                else
                    log_warn "Failed to install sqlmap."
                fi
                ;;
            ffuf)
                if install_packages ffuf; then
                    record_summary "Web" "ffuf"
                else
                    log_warn "Failed to install ffuf."
                fi
                ;;
        esac
    done
}

install_web_tools
