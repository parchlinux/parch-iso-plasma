#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Build the Parch Linux Plasma ISO.
#
# Requirements: an Arch-based host (pacman) with root privileges.
# The profile that is built lives next to this script in ./iso.
# Output artifacts are written to ./out.

set -Eeuo pipefail

# Custom archiso package maintained in the Parch package repository (ppr).
ARCHISO_PKG_URL="https://git.parchlinux.com/repos/ppr/raw/branch/main/x86_64/archiso-99-1-any.pkg.tar.zst"

# Packages required before the ISO can be built.
BUILD_DEPS=(git wget github-cli p7zip reflector rsync)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
ISO_PROFILE_DIR="${SCRIPT_DIR}/iso"
REPO_NAME="${SCRIPT_DIR##*/}"

# Terminal colors, disabled when output is not a TTY.
if [[ -t 1 ]]; then
    RED=$'\e[0;31m'
    GREEN=$'\e[0;32m'
    YELLOW=$'\e[0;33m'
    BLUE=$'\e[0;34m'
    RESET=$'\e[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

log_info() {
    printf '%s\n' "${BLUE}[ INFO  ]${RESET} $*"
}

log_ok() {
    printf '%s\n' "${GREEN}[  OK   ]${RESET} $*"
}

log_warn() {
    printf '%s\n' "${YELLOW}[ WARN  ]${RESET} $*"
}

log_error() {
    printf '%s\n' "${RED}[ ERROR ]${RESET} $*" >&2
}

usage() {
    cat <<EOF
Usage: ${0} [options]

Build the Parch Linux Plasma ISO with mkarchiso.

Options:
  -h, --help      Show this help text and exit.
EOF
}

# Downloads the custom archiso package and prints the path of the
# downloaded artifact. The caller receives the path via stdout.
download_archiso() {
    local dest
    dest="$(mktemp -d -t parch-archiso.XXXXXX)"
    log_info "Downloading custom archiso package from Parch repository ..."
    curl --fail --silent --show-error --location --retry 3 --retry-delay 2 \
        --output "${dest}/${ARCHISO_PKG_URL##*/}" "${ARCHISO_PKG_URL}"
    printf '%s\n' "${dest}/${ARCHISO_PKG_URL##*/}"
    # Remember for the exit trap.
    DOWNLOAD_DIR="${dest}"
}

DOWNLOAD_DIR=""

cleanup_downloads() {
    if [[ -n "${DOWNLOAD_DIR}" && -d "${DOWNLOAD_DIR}" ]]; then
        rm -rf -- "${DOWNLOAD_DIR}"
    fi
}

trap cleanup_downloads EXIT

# Verifies that the host can build the ISO.
check_environment() {
    log_info "Checking build environment for ${REPO_NAME} ..."

    if ! command -v pacman >/dev/null 2>&1; then
        log_error "pacman not found. This ISO can only be built on an Arch-based system."
        exit 1
    fi

    if (( EUID != 0 )); then
        log_error "root privileges required. Run as root."
        exit 1
    fi

    if [[ ! -f "${ISO_PROFILE_DIR}/profiledef.sh" ]]; then
        log_error "no ISO profile found next to build.sh (expected ${ISO_PROFILE_DIR})."
        exit 1
    fi

    log_ok "Build environment is ready."
}

# Installs every required build dependency in a full, single transaction.
# A partial upgrade (-Sy <pkg> without -u) is an unsupported state on
# rolling-release systems like Arch and can break the system.
install_dependencies() {
    log_info "Installing packages needed to build ${REPO_NAME} ..."
    pacman -Syu --noconfirm --needed "${BUILD_DEPS[@]}"
    log_info "Installing custom archiso package ..."
    local archiso_pkg
    archiso_pkg="$(download_archiso)"
    pacman -U --noconfirm "${archiso_pkg}"

    if ! command -v mkarchiso >/dev/null 2>&1; then
        log_error "mkarchiso is not available even after installing the custom archiso package."
        exit 1
    fi
    log_ok "Install complete."
}

# builds the actual image with mkarchiso.
build_iso() {
    log_info "Building ${REPO_NAME} ISO with archiso ..."
    mkarchiso -v "${ISO_PROFILE_DIR}"
}

main() {
    local arg
    for arg in "$@"; do
        case "${arg}" in
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_warn "unsupported argument: ${arg}"
                usage
                exit 1
                ;;
        esac
    done

    check_environment
    install_dependencies
    build_iso
    log_ok "Build complete. Artifacts: ${SCRIPT_DIR}/out/"
}

main "$@"
