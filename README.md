# Arch Linux Web Pentest Bootstrap Scripts

These scripts bootstrap an Arch Linux system for web pentesting/bug bounty workflows with modular, repeatable installers.
<u>Current focus: web hacking, web pentesting, bug bounty, and hash cracking only.</u>

The desktop flow is now focused on **Wayland + sway** via `modules/desktop/install_wayland_sway.sh`.

## Structure

- `bootstrap.sh` - main orchestrator with interactive category menus.
- `lib/common.sh` - shared helpers for logging, prompts, package operations, and summaries.
- `modules/core/` - base system, shell, language, and dotfiles modules.
- `modules/desktop/install_wayland_sway.sh` - sway/Wayland desktop module with TTY autostart, VM tuning, and clipboard helpers.
- `modules/ctf/` - focused security modules:
  - `install_ctf_web.sh`
  - `install_ctf_hashcracking.sh`
  - `install_ctf_suite.sh` (dispatcher)
- `dotfiles/wayland/sway/` - sway config used by the desktop bootstrap flow.
- `docs/virtualization/virtualbox-sway.md` - VirtualBox notes for the sway VM flow.

Logs are written to `logs/bootstrap_<timestamp>.log` and `logs/summary_<timestamp>.txt`.

## Requirements

- Arch Linux with `pacman` and `sudo` configured.
- If using `archinstall`, use a **minimal desktop** baseline so Wayland/sway packages are installed by this repo.
- Keep Archinstall additional packages minimal.
- Optional menu UX tools: `whiptail`, `dialog`, or `fzf`.

### Recommended archinstall baseline

- `Profile -> Type -> Desktop`
- Desktop profile: `Minimal`
- Audio: `pipewire`
- Network: `NetworkManager`
- Graphics: `Mesa / open-source`
- Additional packages: `git base-devel`

All Wayland/sway desktop dependencies are installed by `modules/desktop/install_wayland_sway.sh`, including:

- `foot`
- `sway`, `swaybg`, `swayidle`, `swaylock`, `waybar`, `wofi`
- `wayland`, `wayland-protocols`
- `seatd`
- `mesa`, `vulkan-swrast`
- `xorg-xwayland`
- `wl-clipboard`, `xclip`, `xdg-user-dirs`

## Usage

1. Make scripts executable:
   ```bash
   chmod +x bootstrap.sh modules/core/*.sh modules/desktop/*.sh modules/ctf/*.sh lib/common.sh
   ```
2. Run:
   ```bash
   ./bootstrap.sh
   ```
3. Choose category `wayland` and select components (`core`, `media`, `tools`, `dotfiles`).

`core` also ensures `~/.bash_profile` has a TTY autostart block:

```bash
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v sway >/dev/null 2>&1 && command -v dbus-run-session >/dev/null 2>&1; then
        exec dbus-run-session sway
    fi
fi
```

Re-running is safe; installs use `--needed` and modules are designed to be repeatable.

## VirtualBox Notes (sway)

For VirtualBox VMs, recommended host settings:

- Graphics controller: `VMSVGA`
- Video memory: `128 MB`
- 3D acceleration: enabled
- **Do not forget to enable 3D acceleration in VirtualBox.**

When the `core` component runs inside a VirtualBox VM, it writes:

- `~/.config/environment.d/90-sway-virtualbox.conf` with:
  - `WLR_NO_HARDWARE_CURSORS=1`
  - `LIBGL_ALWAYS_SOFTWARE=1`
  - `WLR_RENDERER_ALLOW_SOFTWARE=1`

These defaults improve sway stability in VirtualBox. For host<->guest clipboard, enable VirtualBox Shared Clipboard as `Bidirectional` on the host and deploy the repo dotfiles so the clipboard bridge starts with sway.
