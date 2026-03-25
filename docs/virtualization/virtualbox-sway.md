# VirtualBox + Arch + sway

This guide is tuned for running `sway` inside VirtualBox.

## 1. VirtualBox VM settings

- RAM: `2-4 GB`
- CPU: `2 cores`
- Graphics Controller: `VMSVGA`
- Video Memory: `128 MB`
- Enable `3D Acceleration`
- Shared Clipboard: `Bidirectional`
- Disk: `20 GB` (or larger)

## 2. archinstall baseline

Use a minimal desktop baseline and let this bootstrap install the sway stack.

- Profile: `Desktop`
- Desktop type: `Minimal`
- Audio: `pipewire`
- Kernel: `linux`
- Network: `NetworkManager`
- Graphics: `Mesa / open-source`

## 3. Run bootstrap

```bash
./bootstrap.sh
```

Select category `wayland`, then select at least:

- `core`
- `dotfiles`

Add `media` and `tools` if you want the full VM desktop flow.

## 4. Start sway

The installer writes `~/.local/bin/start-sway` and also appends an auto-start block to `~/.bash_profile` for TTY1.

For a manual launch:

```bash
start-sway
```

## 5. VirtualBox stability + clipboard

When `core` runs in VirtualBox, the script writes `~/.config/environment.d/90-sway-virtualbox.conf` with:

- `WLR_NO_HARDWARE_CURSORS=1`
- `LIBGL_ALWAYS_SOFTWARE=1`
- `WLR_RENDERER_ALLOW_SOFTWARE=1`

When `dotfiles` is deployed, sway also starts:

- `dbus-sway-environment`
- `wayland-clipboard-bridge`

The clipboard bridge mirrors Wayland clipboard data to the X clipboard and back. In VirtualBox guests, that gives `VBoxClient --clipboard` a path to sync text clipboard content with the host.
