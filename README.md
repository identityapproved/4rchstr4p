# Arch Linux Web Pentest Bootstrap Scripts

These scripts bootstrap an Arch Linux system for web pentesting/bug bounty workflows with modular, repeatable installers.
<u>Current focus: web hacking, web pentesting, bug bounty, and hash cracking only.</u>

The desktop flow is now focused on **Wayland + dwl** via `modules/desktop/install_wayland_dwl.sh`.

## Structure

- `bootstrap.sh` - main orchestrator with interactive category menus.
- `lib/common.sh` - shared helpers for logging, prompts, package operations, and summaries.
- `modules/core/` - base system, shell, language, extras, and dotfiles modules.
- `modules/desktop/install_wayland_dwl.sh` - dwl/Wayland desktop module with TTY autostart and VirtualBox helpers.
- `modules/ctf/` - focused security modules:
  - `install_ctf_web.sh`
  - `install_ctf_hashcracking.sh`
  - `install_ctf_suite.sh` (dispatcher)
- `docs/virtualization/virtualbox-dwl.md` - older virtualization notes.

Logs are written to `logs/bootstrap_<timestamp>.log` and `logs/summary_<timestamp>.txt`.

## Requirements

- Arch Linux with `pacman` and `sudo` configured.
- If using `archinstall`, use a **minimal desktop** baseline so Wayland/dwl packages are installed by this repo.
- Keep Archinstall additional packages minimal: `git` and `base-devel` (for cloning/build workflows).
- Optional menu UX tools: `whiptail`, `dialog`, or `fzf`.

### Recommended archinstall baseline

- `Profile -> Type -> Desktop`
- Desktop profile: `Minimal`
- Audio: `pipewire`
- Network: `NetworkManager`
- Graphics: `Mesa / open-source`
- Additional packages: `git base-devel`

All Wayland/dwl desktop packages are installed by `modules/desktop/install_wayland_dwl.sh`, including:

- `dwl`
- `foot`
- `wayland`, `wayland-protocols`, `wlroots`
- `libinput`, `libxkbcommon`, `pkgconf`
- `libxcb`, `xcb-util-wm`
- `seatd`
- `mesa`, `vulkan-swrast`
- `xorg-xwayland`
- `wofi`, `wl-clipboard`, `swaybg`, `xdg-user-dirs`

## Usage

1. Make scripts executable:
   ```bash
   chmod +x bootstrap.sh modules/core/*.sh modules/desktop/*.sh modules/ctf/*.sh lib/common.sh
   ```
2. Run:
   ```bash
   ./bootstrap.sh
   ```
3. Choose category `wayland` and select components (`core`, `media`, `tools`, etc).

`core` also ensures `~/.bashrc` has a TTY autostart block:

```bash
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec WLR_NO_HARDWARE_CURSORS=1 dbus-run-session dwl
fi
```

Re-running is safe; installs use `--needed` and modules are designed to be repeatable.

## VirtualBox Notes (dwl)

For VirtualBox VMs, recommended host settings:

- Graphics controller: `VMSVGA`
- Video memory: `128 MB`
- 3D acceleration: enabled

When the `core` component runs inside a VirtualBox VM, it writes:

- `~/.config/environment.d/90-dwl-virtualbox.conf` with:
  - `WLR_NO_HARDWARE_CURSORS=1`
  - `LIBGL_ALWAYS_SOFTWARE=1`

These defaults improve wlroots compositor stability in VirtualBox.

## dwl Mod Key (ALT)

To use `ALT` as dwl `MODKEY`, build dwl from source and set this in `config.h`:

```c
#define MODKEY WLR_MODIFIER_ALT
```

Example commands:

```bash
git clone https://codeberg.org/dwl/dwl
cd dwl
# edit config.h or config.def.h to set MODKEY to WLR_MODIFIER_ALT
make
sudo make install
```
