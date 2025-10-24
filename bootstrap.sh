#!/usr/bin/env bash
# bootstrap.sh - Arch Linux CTF environment orchestrator.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
MODULE_DIR="${SCRIPT_DIR}/modules"

# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"

main() {
    init_environment "${SCRIPT_DIR}"
    ensure_pacman
    ensure_sudo

    log_section "Arch Linux CTF bootstrap started"

    mapfile -t top_choices < <(prompt_choices \
        "Select the categories you want to configure:" \
        "arch languages shell ctf" \
        "arch:Arch Linux essentials (helpers, system tuning, virtualization)" \
        "languages:Programming languages and runtimes" \
        "shell:Shell & terminal tooling" \
        "ctf:CTF tooling suite (choose sub-categories inside)" \
        "extras:Optional extras & polish")

    if [[ "${#top_choices[@]}" -eq 0 ]]; then
        log_warn "No categories selected; exiting without changes."
        print_summary
        exit 0
    fi

    for choice in "${top_choices[@]}"; do
        case "${choice}" in
            arch)
                run_module "${MODULE_DIR}/install_arch_essentials.sh"
                ;;
            languages)
                run_module "${MODULE_DIR}/install_programming_languages.sh"
                ;;
            shell)
                run_module "${MODULE_DIR}/install_shell_tools.sh"
                ;;
            ctf)
                run_module "${MODULE_DIR}/install_ctf_suite.sh"
                ;;
            extras)
                run_module "${MODULE_DIR}/install_optional_extras.sh"
                ;;
            *)
                log_warn "Unknown selection '${choice}', skipping."
                ;;
        esac
    done

    log_section "Bootstrap complete"
    print_summary
}

main "$@"
