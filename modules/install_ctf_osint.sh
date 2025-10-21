#!/usr/bin/env bash
# install_ctf_osint.sh - OSINT tool installer.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

install_osint_tools() {
    mapfile -t selections < <(multi_select \
        --title "OSINT" \
        --prompt "Choose OSINT tools:" \
        --default "spiderfoot sherlock holehe" \
        --options \
            "maltego:Maltego (AUR)" \
            "spiderfoot:SpiderFoot" \
            "sherlock:sherlock username hunter" \
            "holehe:holehe (email reuse)" \
            "maigret:Maigret (AUR)" )

    local helper
    helper="$(require_aur_helper || true)"

    for item in "${selections[@]}"; do
        case "${item}" in
            maltego)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" maltego
                    record_summary "OSINT" "Maltego"
                else
                    log_warn "Maltego requires AUR helper; skipped."
                fi
                ;;
            spiderfoot)
                install_packages pacman spiderfoot
                record_summary "OSINT" "SpiderFoot"
                ;;
            sherlock)
                install_packages pacman sherlock
                record_summary "OSINT" "Sherlock"
                ;;
            holehe)
                install_packages pacman holehe
                record_summary "OSINT" "holehe"
                ;;
            maigret)
                if [[ -n "${helper}" ]]; then
                    install_packages "${helper}" maigret
                    record_summary "OSINT" "Maigret"
                else
                    log_warn "Maigret requires AUR helper; skipped."
                fi
                ;;
        esac
    done
}

install_osint_tools
