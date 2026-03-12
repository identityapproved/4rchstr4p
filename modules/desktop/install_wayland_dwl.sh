#!/usr/bin/env bash
# install_wayland_dwl.sh - dwl + Wayland desktop tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../.."
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

DWL_REPO_URL="${DWL_REPO_URL:-https://codeberg.org/dwl/dwl.git}"
DWL_SOURCE_DIR="${DWL_SOURCE_DIR:-${HOME}/.local/src/dwl}"
DWL_CONFIG_DIR="${DWL_CONFIG_DIR:-${HOME}/.config/dwl}"

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
        foot wayland wayland-protocols
        libinput libxkbcommon pkgconf libxcb xcb-util-wm
        base-devel git
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

    mkdir -p "${HOME}/.local/bin" "${DWL_CONFIG_DIR}/patches"
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

    if [[ ! -f "${DWL_CONFIG_DIR}/README.md" ]]; then
        cat > "${DWL_CONFIG_DIR}/README.md" <<'CONF_README'
# dwl local configuration

- `config.h` is used for local dwl source builds.
- Drop extra patch files into `patches/*.patch` to apply custom dwl patches before each build.
CONF_README
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

prepare_dwl_source() {
    if [[ -d "${DWL_SOURCE_DIR}/.git" ]]; then
        log_info "Using existing dwl source at ${DWL_SOURCE_DIR}."
        return 0
    fi

    mkdir -p "$(dirname "${DWL_SOURCE_DIR}")"
    if ! git clone "${DWL_REPO_URL}" "${DWL_SOURCE_DIR}"; then
        log_error "Failed to clone dwl source from ${DWL_REPO_URL}."
        return 1
    fi

    record_summary "dwl" "Cloned source to ${DWL_SOURCE_DIR}"
}

seed_vm_config_h() {
    local target_config="${DWL_CONFIG_DIR}/config.h"
    local source_default="${DWL_SOURCE_DIR}/config.def.h"

    if [[ -f "${target_config}" ]]; then
        log_info "Using existing dwl config at ${target_config}."
        return 0
    fi

    if [[ ! -f "${source_default}" ]]; then
        log_error "Missing ${source_default}; cannot create config.h."
        return 1
    fi

    cp "${source_default}" "${target_config}"

    # VM-friendly defaults: avoid host Super key capture and use Wayland-native terminal.
    sed -i 's/#define MODKEY[[:space:]].*/#define MODKEY WLR_MODIFIER_ALT/' "${target_config}" || true
    sed -i 's/static const char \\*termcmd\\[\\][[:space:]]*=.*/static const char *termcmd[] = { "foot", NULL };/' "${target_config}" || true

    record_summary "dwl" "Created VM-tuned ${target_config}"
}

apply_local_dwl_patches() {
    local patch
    local patch_dir="${DWL_CONFIG_DIR}/patches"
    shopt -s nullglob
    for patch in "${patch_dir}"/*.patch; do
        if patch -d "${DWL_SOURCE_DIR}" -p1 --forward --dry-run < "${patch}" >/dev/null 2>&1; then
            if patch -d "${DWL_SOURCE_DIR}" -p1 --forward < "${patch}" >/dev/null 2>&1; then
                log_info "Applied dwl patch: $(basename "${patch}")"
                record_summary "dwl patch" "$(basename "${patch}")"
            else
                log_warn "Failed to apply dwl patch: ${patch}"
            fi
        elif patch -d "${DWL_SOURCE_DIR}" -p1 --reverse --dry-run < "${patch}" >/dev/null 2>&1; then
            log_info "Patch already applied: $(basename "${patch}")"
        else
            log_warn "Patch does not apply cleanly: ${patch}"
        fi
    done
    shopt -u nullglob
}

build_install_dwl() {
    local target_config="${DWL_CONFIG_DIR}/config.h"
    if [[ ! -f "${target_config}" ]]; then
        log_error "Missing ${target_config}; cannot build dwl."
        return 1
    fi

    cp "${target_config}" "${DWL_SOURCE_DIR}/config.h"
    apply_local_dwl_patches

    if (cd "${DWL_SOURCE_DIR}" && make clean && make); then
        ensure_sudo
        if (cd "${DWL_SOURCE_DIR}" && sudo make install); then
            record_summary "dwl" "Built + installed from source"
            return 0
        fi
    fi

    log_error "dwl build/install failed."
    return 1
}

install_dwl_from_source() {
    if ! prepare_dwl_source; then
        return 1
    fi

    if ! seed_vm_config_h; then
        return 1
    fi

    build_install_dwl
}

print_dwl_build_hint() {
    log_info "dwl config: ${DWL_CONFIG_DIR}/config.h (patches: ${DWL_CONFIG_DIR}/patches/*.patch)."
    record_summary "dwl" "Config dir ${DWL_CONFIG_DIR}"
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
                install_dwl_from_source || log_warn "dwl source install did not complete; check logs."
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
