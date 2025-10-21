#!/usr/bin/env bash
# install_ctf_suite.sh - CTF tooling dispatcher.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="${SCRIPT_DIR}"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

CTF_MODULES=(
    "install_ctf_reversing.sh:Reversing tools (Ghidra, Cutter, radare2...)"
    "install_ctf_web.sh:Web exploitation (Burp, ZAP, dirsearch...)"
    "install_ctf_osint.sh:OSINT (Maltego, Spiderfoot, Sherlock)"
    "install_ctf_pwn.sh:Pwn (Pwntools, ROP, GDB helpers, QEMU)"
    "install_ctf_crypto_forensics.sh:Crypto & Forensics (CyberChef, binwalk, volatility)"
)

run_ctf_suite() {
    mapfile -t picks < <(multi_select \
        --title "CTF Tooling" \
        --prompt "Select CTF tool categories to install:" \
        --default "install_ctf_reversing.sh install_ctf_web.sh install_ctf_pwn.sh" \
        --options "${CTF_MODULES[@]}")

    for module in "${picks[@]}"; do
        run_module "${MODULE_ROOT}/${module}"
    done
}

run_ctf_suite
