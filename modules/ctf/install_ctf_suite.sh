#!/usr/bin/env bash
# install_ctf_suite.sh - Web pentest + hashcracking tooling dispatcher.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="${SCRIPT_DIR}"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

CTF_MODULES=(
    "install_ctf_web.sh:Web exploitation & pentesting tools"
    "install_ctf_hashcracking.sh:Hash cracking tools (hashcat, john, hcxtools)"
)

run_ctf_suite() {
    local -a module_keys=(
        install_ctf_web.sh
        install_ctf_hashcracking.sh
    )
    mapfile -t picks < <(prompt_choices \
        "Select web pentest/hashcracking categories to install:" \
        "all" \
        "all:Install every web pentest/hashcracking module" \
        "${CTF_MODULES[@]}")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )) || [[ "${#picks[@]}" -eq 0 ]]; then
        log_info "Skipping web pentest/hashcracking module."
        return
    fi

    if [[ " ${picks[*]} " == *" all "* ]]; then
        picks=("${module_keys[@]}")
    fi

    for module in "${picks[@]}"; do
        run_module "${MODULE_ROOT}/${module}"
    done
}

run_ctf_suite
