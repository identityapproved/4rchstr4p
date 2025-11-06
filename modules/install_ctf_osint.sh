#!/usr/bin/env bash
# install_ctf_osint.sh - OSINT tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

install_osint_tools() {
    local -a available_keys=(maltego spiderfoot sherlock holehe)
    mapfile -t selections < <(prompt_choices \
        "Choose OSINT tools:" \
        "all" \
        "all:Install every OSINT tool" \
        "maltego:Maltego (AUR)" \
        "spiderfoot:SpiderFoot" \
        "sherlock:sherlock username hunter" \
        "holehe:holehe (email reuse)")

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            maltego)
                if install_packages maltego; then
                    record_summary "OSINT" "Maltego"
                else
                    log_warn "Failed to install Maltego."
                fi
                ;;
            spiderfoot)
                if install_packages spiderfoot; then
                    record_summary "OSINT" "SpiderFoot"
                else
                    log_warn "Failed to install SpiderFoot."
                fi
                ;;
            sherlock)
                if install_packages sherlock; then
                    record_summary "OSINT" "Sherlock"
                else
                    log_warn "Failed to install Sherlock."
                fi
                ;;
            holehe)
                if install_packages holehe; then
                    record_summary "OSINT" "holehe"
                else
                    log_warn "Failed to install holehe."
                fi
                ;;
        esac
    done
}

install_osint_tools
