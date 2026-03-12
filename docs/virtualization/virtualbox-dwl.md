# VirtualBox + Arch + dwl

This guide is tuned for running a wlroots compositor (`dwl`) inside VirtualBox.

## 1. VirtualBox VM settings

- RAM: `2-4 GB`
- CPU: `2 cores`
- Graphics Controller: `VMSVGA`
- Video Memory: `128 MB`
- Enable `3D Acceleration`
- Disk: `20 GB` (or larger)

## 2. archinstall baseline

Use a minimal desktop baseline and let this bootstrap install Wayland/dwl stack.

- Profile: `Desktop`
- Desktop type: `Minimal`
- Audio: `pipewire`
- Kernel: `linux`
- Network: `NetworkManager`
- Graphics: `Mesa / open-source`
- Additional packages: `git base-devel`

## 3. Run bootstrap

```bash
./bootstrap.sh
```

Select category `wayland`, then select at least:

- `core`

`core` installs the main stack (`dwl`, `wlroots`, `seatd`, `mesa`, `vulkan-swrast`, `xorg-xwayland`, `foot`, `wofi`, etc).

## 4. Start dwl

From TTY:

```bash
start-dwl
```

or:

```bash
dbus-run-session dwl
```

## 5. VirtualBox stability fallback

When `core` runs in VirtualBox, the script writes `~/.config/environment.d/90-dwl-virtualbox.conf` with:

- `WLR_NO_HARDWARE_CURSORS=1`
- `LIBGL_ALWAYS_SOFTWARE=1`

For a one-off manual run:

```bash
WLR_NO_HARDWARE_CURSORS=1 LIBGL_ALWAYS_SOFTWARE=1 dbus-run-session dwl
```

## 6. MODKEY = ALT

To use `ALT` as dwl mod key, rebuild dwl with:

```c
#define MODKEY WLR_MODIFIER_ALT
```

Then compile/install dwl from source.
