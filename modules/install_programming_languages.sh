#!/usr/bin/env bash
# install_programming_languages.sh - language runtimes and tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
ensure_environment "${ROOT_DIR}"
ensure_package_manager

ensure_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        install_packages pipx
    fi
}

install_python() {
    log_info "Installing Python tooling."
    install_packages python python-pip python-virtualenv
    ensure_pipx
    record_summary "Languages" "Python + pipx"
}

install_go() {
    install_packages go
    record_summary "Languages" "Go"
}

install_rust() {
    if ! command -v rustup >/dev/null 2>&1; then
        install_packages rustup
    fi
    rustup toolchain install stable --profile default
    rustup default stable
    record_summary "Languages" "Rust"
}

install_node() {
    install_packages fnm
    if command -v fnm >/dev/null 2>&1; then
        fnm install --lts
        fnm use --lts
    fi
    record_summary "Languages" "Node.js (fnm managed)"
}

install_ruby() {
    install_packages ruby rubygems bundler
    record_summary "Languages" "Ruby"
}

install_perl() {
    install_packages perl perl-libwww perl-json
    record_summary "Languages" "Perl"
}

install_java() {
    install_packages jdk-openjdk
    record_summary "Languages" "OpenJDK"
}

install_languages() {
    mapfile -t langs < <(prompt_choices \
        "Select languages/runtimes to install:" \
        "python go rust node" \
        "python:Python + pipx" \
        "go:Go toolchain" \
        "rust:Rust via rustup" \
        "node:Node.js via fnm" \
        "ruby:Ruby & bundler" \
        "perl:Perl" \
        "java:OpenJDK")

    for lang in "${langs[@]}"; do
        case "${lang}" in
            python) install_python ;;
            go) install_go ;;
            rust) install_rust ;;
            node) install_node ;;
            ruby) install_ruby ;;
            perl) install_perl ;;
            java) install_java ;;
        esac
    done
}

install_languages
