#!/usr/bin/env bash
# bootstrap.sh - Arch Linux CTF environment orchestrator.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
MODULE_DIR="${SCRIPT_DIR}/modules"

# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"

prompt_terminal_emulators() {
    mapfile -t terminals < <(prompt_choices \
        "Select terminal emulator(s) to install (0 or q to skip):" \
        "" \
        "kitty:Kitty GPU accelerated terminal" \
        "alacritty:Alacritty GPU accelerated terminal" \
        "terminator:Terminator tiling terminal" \
        "st:Simple Terminal (suckless st)" \
        "none:No additional terminal")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )) || [[ "${#terminals[@]}" -eq 0 ]]; then
        log_info "Skipping additional terminal emulator installation."
        return
    fi

    for term in "${terminals[@]}"; do
        case "${term}" in
            none)
                log_info "No terminal emulator selected for installation."
                return
                ;;
            kitty)
                if command -v kitty >/dev/null 2>&1; then
                    log_info "kitty already installed; skipping."
                else
                    install_packages kitty && record_summary "Terminal" "kitty" || log_warn "Failed to install kitty."
                fi
                ;;
            alacritty)
                if command -v alacritty >/dev/null 2>&1; then
                    log_info "Alacritty already installed; skipping."
                else
                    install_packages alacritty && record_summary "Terminal" "Alacritty" || log_warn "Failed to install Alacritty."
                fi
                ;;
            terminator)
                if command -v terminator >/dev/null 2>&1; then
                    log_info "Terminator already installed; skipping."
                else
                    install_packages terminator && record_summary "Terminal" "Terminator" || log_warn "Failed to install Terminator."
                fi
                ;;
            st)
                if command -v st >/dev/null 2>&1; then
                    log_info "st already installed; skipping."
                else
                    if install_packages st; then
                        record_summary "Terminal" "st (suckless)"
                    else
                        log_warn "Failed to install st terminal."
                    fi
                fi
                ;;
            *)
                log_warn "Unknown terminal selection '${term}'; skipping."
                ;;
        esac
    done
}

main() {
    init_environment "${SCRIPT_DIR}"
    ensure_pacman
    ensure_sudo
    ensure_package_manager
    prompt_terminal_emulators

    log_section "Arch Linux CTF bootstrap started"

    local -a category_keys=("arch" "languages" "shell" "ctf" "extras")
    local -a category_options=(
        "all:Run every category (arch, languages, shell, ctf, extras)"
        "arch:Arch Linux essentials (helpers, system tuning, virtualization)"
        "languages:Programming languages and runtimes"
        "shell:Shell & terminal tooling"
        "ctf:CTF tooling suite (choose sub-categories inside)"
        "extras:Optional extras & polish"
    )

    while true; do
        mapfile -t top_choices < <(prompt_choices \
            "Select the categories you want to configure (0 or q to quit):" \
            "all" \
            "${category_options[@]}")

        if (( PROMPT_CHOICES_EXIT_REQUESTED )); then
            log_info "Exit requested; leaving bootstrap menu."
            break
        fi

        if [[ "${#top_choices[@]}" -eq 0 ]]; then
            log_warn "No categories selected; returning to menu."
            continue
        fi

        if [[ " ${top_choices[*]} " == *" all "* ]]; then
            top_choices=("${category_keys[@]}")
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
    done

    log_section "Bootstrap complete"
    print_summary
}

main "$@"
