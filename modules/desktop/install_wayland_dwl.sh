#!/usr/bin/env bash
# install_wayland_dwl.sh - dwl + Wayland desktop tooling.

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
            record_summary "Wayland/dwl" "${label}: ${available[*]}"
        else
            log_warn "Failed to install ${label} packages with ${PACKAGE_MANAGER}."
        fi
    fi
}

install_core() {
    local wlroots_pkg=""
    local -a core_pkgs=(
        dwl foot wayland wayland-protocols
        libinput libxkbcommon pkgconf libxcb xcb-util-wm
        seatd mesa vulkan-swrast xorg-xwayland
        wofi wl-clipboard swaybg xdg-user-dirs
        xdg-utils xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    )
    if wlroots_pkg="$(pick_first_available_package wlroots wlroots0.18 wlroots0.17)"; then
        core_pkgs+=("${wlroots_pkg}")
    else
        log_warn "No wlroots package variant found (tried: wlroots, wlroots0.18, wlroots0.17)."
    fi

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

    mkdir -p "${HOME}/.local/bin"
    cat > "${HOME}/.local/bin/start-dwl" <<'LAUNCH'
#!/usr/bin/env bash
exec dbus-run-session dwl
LAUNCH
    chmod +x "${HOME}/.local/bin/start-dwl"
    record_summary "dwl" "Installed ~/.local/bin/start-dwl launcher"

    local bashrc="${HOME}/.bashrc"
    if [[ ! -f "${bashrc}" ]]; then
        touch "${bashrc}"
        record_summary "Shell" "Created ~/.bashrc"
    fi

    if ! grep -Fq 'dbus-run-session dwl' "${bashrc}"; then
        cat >> "${bashrc}" <<'BASHRC_BLOCK'

# Auto-start dwl on first TTY.
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v dwl >/dev/null 2>&1 && command -v dbus-run-session >/dev/null 2>&1; then
        WLR_NO_HARDWARE_CURSORS=1 dbus-run-session dwl || echo "dwl exited; staying in shell for troubleshooting."
    else
        echo "dwl or dbus-run-session is missing; skipping autostart."
    fi
fi
BASHRC_BLOCK
        record_summary "dwl" "Appended dwl autostart block to ~/.bashrc"
    else
        log_info "dwl autostart block already present in ~/.bashrc."
    fi
}

install_media() {
    install_available_packages "media" \
        pipewire pipewire-pulse wireplumber pavucontrol playerctl
}

install_tools() {
    local archive_pkg=""
    local sevenzip_pkg=""
    local -a tool_pkgs=(
        yazi ffmpegthumbnailer poppler ueberzugpp brightnessctl
    )
    archive_pkg="$(pick_first_available_package unrar unar unarchiver || true)"
    sevenzip_pkg="$(pick_first_available_package 7zip p7zip || true)"
    [[ -n "${archive_pkg}" ]] && tool_pkgs+=("${archive_pkg}")
    [[ -n "${sevenzip_pkg}" ]] && tool_pkgs+=("${sevenzip_pkg}")

    install_available_packages "tools" "${tool_pkgs[@]}"
}

install_apps() {
    install_available_packages "apps" \
        chromium vivaldi
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
    cat > "${HOME}/.config/environment.d/90-dwl-virtualbox.conf" <<'CONF'
WLR_NO_HARDWARE_CURSORS=1
LIBGL_ALWAYS_SOFTWARE=1
CONF
    record_summary "VirtualBox" "Wrote compatibility env: ~/.config/environment.d/90-dwl-virtualbox.conf"
}

print_dwl_build_hint() {
    log_info "For ALT as dwl MODKEY, rebuild dwl from source with '#define MODKEY WLR_MODIFIER_ALT' in config.h."
    record_summary "dwl" "Set ALT MODKEY via source build (config.h)"
}

run_wayland_dwl() {
    local -a available_keys=(core media tools apps theming dotfiles)
    mapfile -t selections < <(prompt_choices \
        "Choose Wayland/dwl components to install:" \
        "core media tools" \
        "all:Install every Wayland/dwl component" \
        "core:dwl + Wayland stack for Archinstall minimal desktop" \
        "media:PipeWire, PulseAudio compatibility, and controls" \
        "tools:Desktop helper tools (no screenshot stack)" \
        "apps:Browsers (Chromium + Vivaldi)" \
        "theming:Rose Pine GTK/icon themes" \
        "dotfiles:Deploy desktop dotfiles")

    if (( PROMPT_CHOICES_EXIT_REQUESTED )) || [[ "${#selections[@]}" -eq 0 ]]; then
        log_info "Skipping Wayland/dwl module."
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

    print_dwl_build_hint
}

run_wayland_dwl
