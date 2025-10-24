#!/usr/bin/env bash
# lib/common.sh - shared helpers for CTF bootstrap scripts.

set -euo pipefail

LOG_COLORS=${LOG_COLORS:-1}
PROMPT_CHOICES_LAST_INPUT=""
PROMPT_CHOICES_EXIT_REQUESTED=0
PACKAGE_MANAGER=""
CTF_BOOTSTRAP_STATE_DIR=""

init_environment() {
    local root="${1:-$(pwd)}"
    export CTF_BOOTSTRAP_ROOT="${root}"
    export CTF_BOOTSTRAP_LOG_DIR="${root}/logs"
    mkdir -p "${CTF_BOOTSTRAP_LOG_DIR}"
    export CTF_BOOTSTRAP_LOG_FILE="${CTF_BOOTSTRAP_LOG_DIR}/bootstrap_$(date +%Y%m%d_%H%M%S).log"
    export CTF_BOOTSTRAP_SUMMARY="${CTF_BOOTSTRAP_LOG_DIR}/summary_$(date +%Y%m%d_%H%M%S).txt"
    touch "${CTF_BOOTSTRAP_LOG_FILE}" "${CTF_BOOTSTRAP_SUMMARY}"
    CTF_BOOTSTRAP_STATE_DIR="${root}/.state"
}

ensure_environment() {
    local root="${1:-$(pwd)}"
    if [[ -z "${CTF_BOOTSTRAP_LOG_FILE:-}" || -z "${CTF_BOOTSTRAP_SUMMARY:-}" ]]; then
        init_environment "${root}"
    fi
}

ensure_state_dir() {
    if [[ -z "${CTF_BOOTSTRAP_STATE_DIR}" ]]; then
        CTF_BOOTSTRAP_STATE_DIR="${CTF_BOOTSTRAP_ROOT:-$(pwd)}/.state"
    fi
    mkdir -p "${CTF_BOOTSTRAP_STATE_DIR}"
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
        install_packages "${pkg}"
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
    local manager
    case "$1" in
        pacman|yay|paru)
            manager="$1"
            shift
            ;;
        *)
            manager="${PACKAGE_MANAGER:-pacman}"
            ;;
    esac
    local pkgs=("$@")
    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        return 0
    fi
    local cmd_label=""
    local cmd_string=""
    local pkg_list="${pkgs[*]}"
    local status=0

    case "${manager}" in
        pacman)
            cmd_string="sudo pacman --noconfirm --needed -S ${pkg_list}"
            log_info "[pacman] ${cmd_string}"
            sudo pacman --noconfirm --needed -S "${pkgs[@]}" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}" || status=$?
            cmd_label="Command (pacman)"
            ;;
        yay|paru)
            cmd_string="${manager} --noconfirm --needed -S ${pkg_list}"
            log_info "[${manager}] ${cmd_string}"
            "${manager}" --noconfirm --needed -S "${pkgs[@]}" | tee -a "${CTF_BOOTSTRAP_LOG_FILE}" || status=$?
            cmd_label="Command (${manager})"
            ;;
        *)
            log_error "Unknown package manager '${manager}'"
            return 1
            ;;
    esac

    if (( status != 0 )); then
        log_error "Package installation command failed (exit ${status})."
        return "${status}"
    fi

    if [[ -n "${cmd_label}" ]]; then
        record_summary "${cmd_label}" "${cmd_string}"
    fi
}

pacman_has_package() {
    local pkg="$1"
    pacman -Si "${pkg}" >/dev/null 2>&1
}

detect_virtualbox() {
    local virt
    virt="$(systemd-detect-virt 2>/dev/null || true)"
    if [[ -z "${virt}" || "${virt}" == "none" ]]; then
        echo "none"
    elif [[ "${virt}" == "oracle" ]]; then
        echo "virtualbox"
    else
        echo "${virt}"
    fi
}

manager_state_file() {
    ensure_state_dir
    printf "%s\n" "${CTF_BOOTSTRAP_STATE_DIR}/package_manager"
}

update_state_file() {
    ensure_state_dir
    printf "%s\n" "${CTF_BOOTSTRAP_STATE_DIR}/initial_update_done"
}

load_package_manager() {
    local file
    file="$(manager_state_file)"
    if [[ -f "${file}" ]]; then
        local mgr
        mgr="$(<"${file}")"
        if command -v "${mgr}" >/dev/null 2>&1; then
            PACKAGE_MANAGER="${mgr}"
            return 0
        fi
        log_warn "Stored package manager '${mgr}' not found; re-selecting."
    fi
    return 1
}

save_package_manager() {
    local mgr="$1"
    local file
    file="$(manager_state_file)"
    printf "%s\n" "${mgr}" > "${file}"
}

install_yay_helper() {
    if command -v yay >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing yay AUR helper."
    sudo pacman --noconfirm --needed -S base-devel git
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "${tmpdir}/yay"
    (cd "${tmpdir}/yay" && makepkg -si --noconfirm)
    rm -rf "${tmpdir}"
}

install_paru_helper() {
    if command -v paru >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing paru AUR helper."
    sudo pacman --noconfirm --needed -S base-devel git
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "${tmpdir}/paru"
    (cd "${tmpdir}/paru" && makepkg -si --noconfirm)
    rm -rf "${tmpdir}"
}

set_package_manager() {
    local mgr="$1"
    PACKAGE_MANAGER="${mgr}"
    save_package_manager "${mgr}"
    record_summary "Package manager" "${mgr}"
}

perform_system_update() {
    local mgr="${PACKAGE_MANAGER:-pacman}"
    local status=0
    local cmd=""
    case "${mgr}" in
        pacman)
            cmd="sudo pacman --noconfirm -Syu"
            log_info "[pacman] ${cmd}"
            sudo pacman --noconfirm -Syu | tee -a "${CTF_BOOTSTRAP_LOG_FILE}" || status=$?
            ;;
        yay|paru)
            cmd="${mgr} --noconfirm -Syu"
            log_info "[${mgr}] ${cmd}"
            "${mgr}" --noconfirm -Syu | tee -a "${CTF_BOOTSTRAP_LOG_FILE}" || status=$?
            ;;
        *)
            log_warn "Unknown package manager '${mgr}' for system update; defaulting to pacman."
            PACKAGE_MANAGER="pacman"
            set_package_manager "pacman"
            perform_system_update
            ;;
    esac

    if (( status != 0 )); then
        log_error "System update command failed (exit ${status})."
        return "${status}"
    fi

    if [[ -n "${cmd}" ]]; then
        record_summary "Command (${mgr})" "${cmd}"
    fi
}

ensure_package_manager() {
    if [[ -n "${PACKAGE_MANAGER}" ]]; then
        return
    fi

    if load_package_manager; then
        :
    else
        local available_default="pacman"
        if command -v yay >/dev/null 2>&1; then
            available_default="yay"
        elif command -v paru >/dev/null 2>&1; then
            available_default="paru"
        fi

        local choice=""
        while [[ -z "${choice}" ]]; do
            choice="$(prompt_single_choice \
                "Choose the package manager to use (0 or q to default to pacman):" \
                "${available_default}" \
                "yay:Use yay (AUR helper, handles official repos)" \
                "paru:Use paru (AUR helper, handles official repos)" \
                "pacman:Use pacman only")"

            if (( PROMPT_CHOICES_EXIT_REQUESTED )); then
                log_warn "Defaulting to pacman."
                choice="pacman"
            elif [[ -z "${choice}" ]]; then
                choice="${available_default}"
            fi
        done

        case "${choice}" in
            yay)
                install_yay_helper
                ;;
            paru)
                install_paru_helper
                ;;
            pacman)
                ensure_pacman
                ;;
            *)
                log_warn "Unexpected package manager choice '${choice}', defaulting to pacman."
                choice="pacman"
                ;;
        esac

        set_package_manager "${choice}"
    fi

    if [[ -z "${PACKAGE_MANAGER}" ]]; then
        PACKAGE_MANAGER="pacman"
        save_package_manager "${PACKAGE_MANAGER}"
    fi

    local update_flag
    update_flag="$(update_state_file)"
    if [[ ! -f "${update_flag}" ]]; then
        perform_system_update
        touch "${update_flag}"
    fi
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

    PROMPT_CHOICES_LAST_INPUT=""
    PROMPT_CHOICES_EXIT_REQUESTED=0

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
    PROMPT_CHOICES_LAST_INPUT="${answer}"
    if [[ -z "${answer}" ]]; then
        if [[ -z "${default}" ]]; then
            return 0
        fi
        answer="${default}"
        PROMPT_CHOICES_LAST_INPUT="${default}"
    fi

    declare -A selections=()
    local quit_requested=0
    for token in ${answer}; do
        local lower_token
        lower_token="$(printf "%s" "${token}" | tr '[:upper:]' '[:lower:]')"
        if [[ "${lower_token}" == "q" || "${lower_token}" == "quit" || "${lower_token}" == "exit" || "${token}" == "0" ]]; then
            quit_requested=1
            continue
        fi
        if [[ "${token}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            if (( start == 0 || end == 0 )); then
                quit_requested=1
                continue
            fi
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
            elif (( num == 0 )); then
                quit_requested=1
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

    if (( quit_requested )); then
        PROMPT_CHOICES_EXIT_REQUESTED=1
        return 0
    fi

    PROMPT_CHOICES_EXIT_REQUESTED=0
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
