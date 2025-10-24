# Arch Linux CTF Bootstrap Scripts \(ﾉ◕ヮ◕\)ﾉ*:･ﾟ✧

These scripts automate bootstrapping an Arch Linux system for CTF competitions and pentesting. They remain modular, idempotent, and give you control over what gets installed.

## Structure

- `bootstrap.sh` — main orchestrator; wires interactive menus to modular installers, handles logging and summaries.
- `lib/common.sh` — shared helper library for logging, package operations, menu abstraction, and summary reporting.
- `modules/` — category-specific installers:
  - `install_arch_essentials.sh`
  - `install_programming_languages.sh`
  - `install_shell_tools.sh`
  - `install_ctf_suite.sh` (dispatches to submodules)
  - `install_optional_extras.sh`
  - `install_dotfiles.sh`
  - `install_zsh_plugins.sh`
  - `install_ctf_reversing.sh`
  - `install_ctf_web.sh`
  - `install_ctf_osint.sh`
  - `install_ctf_pwn.sh`
  - `install_ctf_crypto_forensics.sh`

Logs are stored under `logs/` with timestamped files for the main run and the summary.

## Requirements

- Arch Linux with `pacman` and `sudo` configured.
- Ability to build AUR packages if you opt into AUR tools (Git, base-devel).
- Optional: `whiptail`, `dialog`, or `fzf` for richer menus (fallback prompts are provided).

## Usage

1. Clone or copy this directory onto the target machine.
2. Make sure scripts are executable:
   ```bash
   chmod +x bootstrap.sh modules/*.sh lib/common.sh
   ```
3. Run the orchestrator:
   ```bash
   ./bootstrap.sh
   ```
4. Follow the numeric prompts to pick the categories and tools you want (type selections like `1 3 5` or ranges such as `1-3`; press Enter to accept the defaults shown).
5. Inspect `logs/bootstrap_<timestamp>.log` and `logs/summary_<timestamp>.txt` after completion for details.

Re-running the scripts is safe: all package installs use `--needed`, and pipx installs are idempotent.

## Customization Tips

- Update defaults in each module if you prefer different selections to be pre-checked.
- Extend the `modules/` scripts or add new ones; each entry simply sources `lib/common.sh` and records results.
- Drop replacement configs into `dotfiles/` to have them copied into place (existing files are backed up automatically).
- LazyVim setup relies on `fnm` to supply Node.js; adjust the helper in `install_shell_tools.sh` if you prefer a different runtime manager.
- For offline or repetitive setups, consider caching `/var/cache/pacman/pkg` and `~/.cache/yay` (or your AUR helper of choice).
- If you plan to import dotfiles or configure shells further, chain them from `bootstrap.sh` or add new modules.

Happy hacking ヽ\(^o^\)丿
