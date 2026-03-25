#!/usr/bin/env bash
# install_wayland_sway.sh - sway + Wayland desktop tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

pick_first_available_package() {
    local pkg
    for pkg in "$@"; do
        if package_available "${pkg}"; then
            printf "%s\n" "${pkg}"
            return 0
        fi
    done
    return 1
}

install_available_packages() {
    local label="$1"; shift
    local -a pkgs=("$@")
    local -a available=()

    for pkg in "${pkgs[@]}"; do
        if package_available "${pkg}"; then
            available+=("${pkg}")
        else
            log_warn "Package '${pkg}' not found with ${PACKAGE_MANAGER}; skipping."
        fi
    done

    if (( ${#available[@]} )); then
        if install_packages "${available[@]}"; then
            record_summary "Wayland/sway" "${label}: ${available[*]}"
        else
            log_warn "Failed to install ${label} packages with ${PACKAGE_MANAGER}."
        fi
    fi
}

append_file_once() {
    local target="$1"
    local marker="$2"
    local content="$3"

    if [[ ! -f "${target}" ]]; then
        install -Dm644 /dev/null "${target}"
        record_summary "Shell" "Created ${target/#${HOME}/~}"
    fi

    if grep -Fq "${marker}" "${target}"; then
        log_info "Autostart block already present in ${target}."
        return 0
    fi

    printf "\n%s\n" "${content}" >> "${target}"
    record_summary "sway" "Appended sway autostart block to ${target/#${HOME}/~}"
}

install_core() {
    local -a core_pkgs=(
        sway swaybg swayidle swaylock waybar foot wofi
        wayland wayland-protocols xorg-xwayland
        seatd mesa vulkan-swrast
        wl-clipboard xclip jq xdg-user-dirs xdg-utils
        xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    )

    install_available_packages "core" "${core_pkgs[@]}"

    if command -v systemctl >/dev/null 2>&1; then
        ensure_sudo
        sudo systemctl enable --now seatd.service || log_warn "Could not enable/start seatd.service automatically."
    fi

    if id -nG "${USER}" | tr ' ' '\n' | grep -qx "seat"; then
        log_info "User '${USER}' is already in seat group."
    else
        ensure_sudo
        sudo usermod -aG seat "${USER}" || log_warn "Could not add ${USER} to seat group automatically."
        log_warn "You may need to log out and log in again for seat group changes to apply."
    fi

    mkdir -p "${HOME}/.local/bin" "${HOME}/.config/sway"
    cat > "${HOME}/.local/bin/start-sway" <<'LAUNCH'
#!/usr/bin/env bash
if [[ -f "${HOME}/.config/environment.d/90-sway-virtualbox.conf" ]]; then
    # Sway is launched directly from the shell, so import VM-specific env here.
    set -a
    # shellcheck disable=SC1090
    source "${HOME}/.config/environment.d/90-sway-virtualbox.conf"
    set +a
fi
exec dbus-run-session sway
LAUNCH
    chmod +x "${HOME}/.local/bin/start-sway"
    record_summary "sway" "Installed ~/.local/bin/start-sway launcher"

    append_file_once "${HOME}/.bash_profile" "# Auto-start sway on first TTY." '# Auto-start sway on first TTY.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v start-sway >/dev/null 2>&1; then
        exec start-sway
    else
        echo "start-sway is missing; skipping autostart."
    fi
fi'
}

install_media() {
    install_available_packages "media" \
        pipewire pipewire-pulse wireplumber pavucontrol playerctl
}

install_tools() {
    local archive_pkg=""
    local sevenzip_pkg=""
    local -a tool_pkgs=(
        yazi ffmpegthumbnailer poppler ueberzugpp brightnessctl grim slurp jq fzf
    )
    archive_pkg="$(pick_first_available_package unrar unar unarchiver || true)"
    sevenzip_pkg="$(pick_first_available_package 7zip p7zip || true)"
    [[ -n "${archive_pkg}" ]] && tool_pkgs+=("${archive_pkg}")
    [[ -n "${sevenzip_pkg}" ]] && tool_pkgs+=("${sevenzip_pkg}")

    install_available_packages "tools" "${tool_pkgs[@]}"
}

install_apps() {
    install_available_packages "apps" \
        chromium firefox
}

install_theming() {
    install_available_packages "theming" \
        rose-pine-gtk-theme rose-pine-icon-theme
}

configure_virtualbox_compat() {
    local virt
    virt="$(detect_virtualbox)"

    if [[ "${virt}" != "virtualbox" ]]; then
        log_info "Virtualization detected as '${virt}'; no VirtualBox-specific tuning required."
        return
    fi

    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/90-sway-virtualbox.conf" <<'CONF'
WLR_NO_HARDWARE_CURSORS=1
LIBGL_ALWAYS_SOFTWARE=1
WLR_RENDERER_ALLOW_SOFTWARE=1
CONF
    record_summary "VirtualBox" "Wrote compatibility env: ~/.config/environment.d/90-sway-virtualbox.conf"
}

print_sway_hint() {
    local virt
    virt="$(detect_virtualbox)"
    log_info "sway launcher: ~/.local/bin/start-sway"
    record_summary "sway" "Config dir ~/.config/sway"
    if [[ "${virt}" == "virtualbox" ]]; then
        log_info "Enable VirtualBox Shared Clipboard -> Bidirectional on the host for host<->guest clipboard sync."
        record_summary "VirtualBox" "Host shared clipboard should be set to Bidirectional"
    fi
}

run_wayland_sway() {
    local -a available_keys=(core media tools apps theming dotfiles)
    mapfile -t selections < <(prompt_choices \
        "Choose Wayland/sway components to install:" \
        "core media tools dotfiles" \
        "all:Install every Wayland/sway component" \
        "core:sway + Wayland stack for Archinstall minimal desktop" \
        "media:PipeWire, PulseAudio compatibility, and controls" \
        "tools:Desktop helper tools (screenshots, clipboard, file manager)" \
        "apps:Browsers (Chromium + Firefox)" \
        "theming:Rose Pine GTK/icon themes" \
        "dotfiles:Deploy desktop dotfiles and helper scripts")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )) || [[ "${#selections[@]}" -eq 0 ]]; then
        log_info "Skipping Wayland/sway module."
        return
    fi

    if [[ " ${selections[*]} " == *" all "* ]]; then
        selections=("${available_keys[@]}")
    fi

    for item in "${selections[@]}"; do
        case "${item}" in
            core)
                install_core
                configure_virtualbox_compat
                ;;
            media) install_media ;;
            tools) install_tools ;;
            apps) install_apps ;;
            theming) install_theming ;;
            dotfiles) run_module "${SCRIPT_DIR}/../core/install_dotfiles.sh" ;;
        esac
    done

    print_sway_hint
}

run_wayland_sway
