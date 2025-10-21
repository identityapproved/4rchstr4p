#!/usr/bin/env bash
# lib/common.sh - shared helpers for CTF bootstrap scripts.

set -euo pipefail

LOG_COLORS=${LOG_COLORS:-1}

init_environment() {
    local root="${1:-$(pwd)}"
    export CTF_BOOTSTRAP_ROOT="${root}"
    export CTF_BOOTSTRAP_LOG_DIR="${root}/logs"
    mkdir -p "${CTF_BOOTSTRAP_LOG_DIR}"
    export CTF_BOOTSTRAP_LOG_FILE="${CTF_BOOTSTRAP_LOG_DIR}/bootstrap_$(date +%Y%m%d_%H%M%S).log"
    export CTF_BOOTSTRAP_SUMMARY="${CTF_BOOTSTRAP_LOG_DIR}/summary_$(date +%Y%m%d_%H%M%S).txt"
    touch "${CTF_BOOTSTRAP_LOG_FILE}" "${CTF_BOOTSTRAP_SUMMARY}"
}

_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date +"%Y-%m-%d %H:%M:%S")"
    printf "[%s] %s %s\n" "${ts}" "${level}" "${msg}" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}" >&2
}

log_info()  { _log "INFO " "$*"; }
log_warn()  { _log "WARN " "$*"; }
log_error() { _log "ERROR" "$*"; }
log_section() {
    local bar
    bar="$(printf '%*s' 60 '' | tr ' ' '=')"
    _log "INFO " "${bar} $* ${bar}"
}

ensure_command() {
    local cmd="$1"
    local pkg="${2:-}"
    if command -v "${cmd}" >/dev/null 2>&1; then
        return 0
    fi
    if [[ -n "${pkg}" ]]; then
        install_packages pacman "${pkg}"
    fi
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        log_error "Required command '${cmd}' not available."
        exit 2
    fi
}

ensure_pacman() {
    if ! command -v pacman >/dev/null 2>&1; then
        log_error "pacman is unavailable. Are you on Arch Linux?"
        exit 2
    fi
}

ensure_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo is required for privileged actions."
        exit 2
    fi
    if ! sudo -n true >/dev/null 2>&1; then
        log_info "Requesting sudo access..."
        sudo -v
    fi
}

install_packages() {
    local manager="$1"; shift
    local pkgs=("$@")
    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        return 0
    fi

    case "${manager}" in
        pacman)
            sudo pacman --noconfirm --needed -S "${pkgs[@]}" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}"
            ;;
        yay|paru)
            "${manager}" --noconfirm --needed -S "${pkgs[@]}" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}"
            ;;
        *)
            log_error "Unknown package manager '${manager}'"
            return 1
            ;;
    esac
}

aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        echo "yay"
        return
    fi
    if command -v paru >/dev/null 2>&1; then
        echo "paru"
        return
    fi
    echo ""
}

require_aur_helper() {
    local helper
    helper="$(aur_helper)"
    if [[ -z "${helper}" ]]; then
        log_warn "No AUR helper detected."
        return 1
    fi
    echo "${helper}"
}

detect_virtualbox() {
    if systemd-detect-virt --quiet --vm --type oracle; then
        echo "virtualbox"
        return
    fi
    if systemd-detect-virt --quiet --vm; then
        echo "other-vm"
        return
    fi
    echo "none"
}

run_module() {
    local module_path="$1"; shift
    log_section "Running module: $(basename "${module_path}")"
    if [[ ! -x "${module_path}" ]]; then
        chmod +x "${module_path}"
    fi
    "${module_path}" "$@" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}"
}

record_summary() {
    local label="$1"; shift
    printf "%s: %s\n" "${label}" "$*" >> "${CTF_BOOTSTRAP_SUMMARY}"
}

print_summary() {
    log_section "Summary"
    if [[ -s "${CTF_BOOTSTRAP_SUMMARY}" ]]; then
        cat "${CTF_BOOTSTRAP_SUMMARY}"
    else
        log_info "No changes recorded."
    fi
    log_info "Detailed log: ${CTF_BOOTSTRAP_LOG_FILE}"
}

menu_backend=""

ensure_menu_backend() {
    if [[ -n "${menu_backend}" ]]; then
        return
    fi
    if command -v whiptail >/dev/null 2>&1; then
        menu_backend="whiptail"
    elif command -v dialog >/dev/null 2>&1; then
        menu_backend="dialog"
    elif command -v fzf >/dev/null 2>&1; then
        menu_backend="fzf"
    else
        menu_backend="select"
        log_warn "No whiptail/dialog/fzf detected; falling back to basic prompts."
    fi
}

multi_select() {
    local title=""
    local prompt=""
    local default=""
    local options=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            --prompt) prompt="$2"; shift 2 ;;
            --default) default="$2"; shift 2 ;;
            --options) shift; while [[ $# -gt 0 && "$1" != --* ]]; do options+=("$1"); shift; done ;;
            *) shift ;;
        esac
    done

    case "${menu_backend}" in
        whiptail)
            local checklist=()
            for opt in "${options[@]}"; do
                IFS=":" read -r key desc <<< "${opt}"
                local state="OFF"
                if [[ " ${default} " == *" ${key} "* ]]; then state="ON"; fi
                checklist+=("${key}" "${desc}" "${state}")
            done
            local result
            result=$(whiptail --title "${title}" --checklist "${prompt}" 20 74 10 "${checklist[@]}" 3>&1 1>&2 2>&3) || true
            result="${result//\"/}"
            for item in ${result}; do printf "%s\n" "${item}"; done
            ;;
        dialog)
            local checklist=()
            for opt in "${options[@]}"; do
                IFS=":" read -r key desc <<< "${opt}"
                local state="off"
                if [[ " ${default} " == *" ${key} "* ]]; then state="on"; fi
                checklist+=("${key}" "${desc}" "${state}")
            done
            local result
            result=$(dialog --stdout --checklist "${prompt}" 20 74 10 "${checklist[@]}") || true
            for item in ${result}; do printf "%s\n" "${item}"; done
            ;;
        fzf)
            local defaults=()
            for opt in "${options[@]}"; do
                IFS=":" read -r key desc <<< "${opt}"
                defaults+=("${key}\t${desc}")
            done
            printf "%s\n" "${defaults[@]}" | fzf --multi --header="${prompt}" --prompt="${title}> " | cut -f1
            ;;
        select)
            printf "%s\n" "${prompt}"
            local index=1
            for opt in "${options[@]}"; do
                IFS=":" read -r key desc <<< "${opt}"
                printf " [%d] %s - %s\n" "${index}" "${key}" "${desc}"
                index=$((index + 1))
            done
            if [[ -n "${default}" ]]; then
                printf "Default selections: %s\n" "${default}"
            fi
            printf "Enter choices (space separated, blank for default): "
            read -r answer
            if [[ -z "${answer}" && -n "${default}" ]]; then
                answer="${default}"
            fi
            for token in ${answer}; do
                case "${token}" in
                    *[!0-9]*)
                        printf "%s\n" "${token}"
                        ;;
                    *)
                        if (( token >= 1 && token <= ${#options[@]} )); then
                            IFS=":" read -r key _ <<< "${options[$((token-1))]}"
                            printf "%s\n" "${key}"
                        fi
                        ;;
                esac
            done
            ;;
    esac
}
