#!/bin/bash
set -euo pipefail
# Single-node timpani-n runtime install.
# Downloads the prebuilt timpani-n native package (.deb/.rpm) into DIST_DIR and
# installs it. The package ships /usr/bin/timpani-n and a `timpani-n` systemd
# service that reads its arguments from /etc/default/timpani-n (TIMPANI_N_ARGS).
# This script writes those args (node name, node IP) and starts the service.
#
# Required via environment:
#   NODE_IP     host address timpani-n connects to (positional arg)
# Overridable via environment:
#   NODE_NAME          node id passed with -n (default: hostname)
#   TIMPANI_N_ARGS     full arg string; overrides the composed default if set
#   TIMPANI_N_VERSION  package version to download (default 2.0.0)

NODE_NAME="${NODE_NAME:-$(hostname)}"
TIMPANI_N_VERSION="${TIMPANI_N_VERSION:-2.0.0}"
PKG_BASE_URL="https://raw.githubusercontent.com/MCO-PICCOLO/TIMPANI/development_0.5/sdv_blueprint"
# Directory the package is downloaded to / looked up in.
DIST_DIR="${DIST_DIR:-/tmp}"

log() { echo "[install-timpani-n] $*"; }
die() { echo "[install-timpani-n] ERROR: $*" >&2; exit 1; }

[[ "${EUID}" -eq 0 ]] || die "Please run as root: sudo $0"
[[ -n "${NODE_IP:-}" ]] || die "NODE_IP must be set (host address for timpani-n)"

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        echo "${ID}"
    else
        die "Cannot detect OS — /etc/os-release not found."
    fi
}

OS=$(detect_os)
log "Detected OS: ${OS}"

# ---------------------------------------------------------------------------
# download_package — fetch the prebuilt package into DIST_DIR (cached).
# ---------------------------------------------------------------------------
download_package() {
    local file="$1"
    local dest="${DIST_DIR}/${file}"
    if [[ -f "${dest}" ]]; then
        log "Using cached package at ${dest}"
    else
        log "Downloading ${file} from ${PKG_BASE_URL}/${file}..."
        curl -fL -o "${dest}" "${PKG_BASE_URL}/${file}" \
            || die "Failed to download ${PKG_BASE_URL}/${file}"
    fi
    echo "${dest}"
}

find_package() {
    local pattern="$1"
    local found
    found=$(find "${DIST_DIR}" -maxdepth 1 -name "${pattern}" 2>/dev/null | sort -V | tail -n1)
    if [[ -z "${found}" ]]; then
        die "Package matching '${pattern}' not found in ${DIST_DIR}."
    fi
    echo "${found}"
}

# ---------------------------------------------------------------------------
# timpani-n — download and install native package
# ---------------------------------------------------------------------------
install_timpani_n() {
    local pkg
    case "${OS}" in
        ubuntu|debian)
            download_package "timpani-n-${TIMPANI_N_VERSION}-Linux.deb" >/dev/null
            pkg=$(find_package "timpani-n*.deb")
            log "Installing ${pkg}..."
            # The package marks system dirs (/etc/default, /usr/lib/systemd*) as
            # its own, which can conflict with base packages. --force-overwrite
            # ignores those file/dir ownership conflicts; then resolve any
            # remaining dependencies.
            dpkg -i --force-overwrite "${pkg}" || apt-get install -f -y
            ;;
        centos|rhel|fedora)
            download_package "timpani-n-${TIMPANI_N_VERSION}-Linux.rpm" >/dev/null
            pkg=$(find_package "timpani-n*.rpm")
            log "Installing ${pkg}..."
            # The package marks system dirs (/etc/default, /usr/lib/systemd*) as
            # its own, which conflicts with filesystem/systemd/plymouth under
            # dnf. Install with rpm --replacefiles to ignore those dir/file
            # ownership conflicts.
            rpm -Uvh --replacefiles --replacepkgs "${pkg}" \
                || die "Failed to install ${pkg}"
            ;;
        *)
            die "Unsupported OS for timpani-n package install: ${OS}"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# configure_and_start — write runtime args and (re)start the systemd service.
# Matches the previous manual launch: -n <node> -s -l 4 -P 80 <host ip>
# ---------------------------------------------------------------------------
configure_and_start() {
    local args="${TIMPANI_N_ARGS:--n ${NODE_NAME} -s -l 4 -P 80 ${NODE_IP}}"
    log "Writing /etc/default/timpani-n (TIMPANI_N_ARGS=\"${args}\")"
    mkdir -p /etc/default
    printf 'TIMPANI_N_ARGS="%s"\n' "${args}" > /etc/default/timpani-n

    log "Enabling and starting timpani-n service..."
    systemctl daemon-reload
    systemctl enable timpani-n.service
    systemctl restart timpani-n.service

    sleep 2
    if systemctl is-active --quiet timpani-n; then
        log "timpani-n service is running."
    else
        journalctl -u timpani-n -n 40 --no-pager || true
        die "timpani-n service failed to start. Check: journalctl -u timpani-n"
    fi
}

install_timpani_n
configure_and_start

log "Done. Status: systemctl status timpani-n | Logs: journalctl -u timpani-n -f"
