# dwl scaffold

This repo uses local runtime config at `~/.config/dwl/`.

- Main file: `~/.config/dwl/config.h`
- Optional patch queue: `~/.config/dwl/patches/*.patch`

Installer behavior:

1. Clones dwl source to `~/.local/src/dwl` if missing.
2. Creates `~/.config/dwl/config.h` from upstream `config.def.h` (VM-tuned defaults).
3. Copies `config.h` into source tree.
4. Applies all patches from `~/.config/dwl/patches/*.patch`.
5. Builds and installs dwl.

You can keep your own patches in this repo under `dotfiles/wayland/dwl/patches/` and copy them into `~/.config/dwl/patches/` when needed.
