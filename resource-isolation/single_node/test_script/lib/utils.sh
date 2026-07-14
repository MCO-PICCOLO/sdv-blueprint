# =============================================================
# lib/utils.sh  ─  Shared shell functions (single-node, local only)
# Source after config.env.
# =============================================================

# ── Log helpers ──────────────────────────────────────────────
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err()  { echo "[ERROR] $*" >&2; }

# ── Command existence check ───────────────────────────────────
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

# ── Local node IP detection ───────────────────────────────────
# Prints an explicit NODE_IP if set, otherwise the first non-loopback
# IPv4 address of this machine.
detect_node_ip() {
  if [[ -n "${NODE_IP:-}" ]]; then
    echo "${NODE_IP}"
    return
  fi
  hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^127\.' | head -n1
}

# ── Local sudo execution ──────────────────────────────────────
# Uses SUDO_PASS via `sudo -S` when provided, otherwise a normal sudo.
run_sudo() {
  if [[ -n "${SUDO_PASS:-}" ]]; then
    printf '%s\n' "${SUDO_PASS}" | sudo -S -p '' "$@"
  else
    sudo "$@"
  fi
}

# ── Arduino library check/install ────────────────────────────
ensure_arduino_lib() {
  local lib="${1:-Adafruit NeoPixel}"
  if arduino-cli lib list | grep -qF "$lib"; then
    info "Arduino lib already installed: $lib"
  else
    info "Installing Arduino lib: $lib"
    arduino-cli lib install "$lib"
  fi
}
