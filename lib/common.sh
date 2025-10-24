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

ensure_environment() {
    local root="${1:-$(pwd)}"
    if [[ -z "${CTF_BOOTSTRAP_LOG_FILE:-}" || -z "${CTF_BOOTSTRAP_SUMMARY:-}" ]]; then
        init_environment "${root}"
    fi
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

prompt_choices() {
    local title="$1"
    local default="$2"
    shift 2
    local options=("$@")

    if [[ "${#options[@]}" -eq 0 ]]; then
        return 0
    fi

    if [[ -n "${title}" ]]; then
        printf "%s\n" "${title}" >&2
    fi

    local -a keys=()
    local idx=0
    for option in "${options[@]}"; do
        IFS=":" read -r key desc <<< "${option}"
        keys+=("${key}")
        printf " %2d) %-16s %s\n" $((idx + 1)) "${key}" "${desc}" >&2
        idx=$((idx + 1))
    done

    if [[ -n "${default}" ]]; then
        printf "Default selection: %s\n" "${default}" >&2
    fi
    printf "Enter choices (e.g. 1 3 5 or 1-3). " >&2
    if [[ -n "${default}" ]]; then
        printf "Press Enter for default." >&2
    else
        printf "Press Enter to skip." >&2
    fi
    printf "\n> " >&2

    local answer
    read -r answer
    if [[ -z "${answer}" ]]; then
        if [[ -z "${default}" ]]; then
            return 0
        fi
        answer="${default}"
    fi

    declare -A selections=()
    for token in ${answer}; do
        if [[ "${token}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            if (( start > end )); then
                local tmp="${start}"
                start="${end}"
                end="${tmp}"
            fi
            for ((i=start; i<=end; i++)); do
                if (( i >= 1 && i <= ${#keys[@]} )); then
                    selections["${keys[$((i-1))]}"]=1
                else
                    log_warn "Ignoring out-of-range selection '${i}'."
                fi
            done
        elif [[ "${token}" =~ ^[0-9]+$ ]]; then
            local num="${token}"
            if (( num >= 1 && num <= ${#keys[@]} )); then
                selections["${keys[$((num-1))]}"]=1
            else
                log_warn "Ignoring out-of-range selection '${token}'."
            fi
        else
            local matched=""
            for idx in "${!keys[@]}"; do
                if [[ "${keys[$idx]}" == "${token}" ]]; then
                    matched="${keys[$idx]}"
                    break
                fi
            done
            if [[ -n "${matched}" ]]; then
                selections["${matched}"]=1
            else
                log_warn "Ignoring unknown option '${token}'."
            fi
        fi
    done

    for key in "${keys[@]}"; do
        if [[ -n "${selections[$key]:-}" ]]; then
            printf "%s\n" "${key}"
        fi
    done
}

prompt_single_choice() {
    local title="$1"
    local default="$2"
    shift 2
    mapfile -t _choices < <(prompt_choices "${title}" "${default}" "$@")
    if [[ "${#_choices[@]}" -gt 0 ]]; then
        printf "%s\n" "${_choices[0]}"
    fi
}
