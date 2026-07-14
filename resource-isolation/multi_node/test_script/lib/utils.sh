# =============================================================
# lib/utils.sh  ─  Shared shell functions
# Source after config.env so SSH_CONNECT_TIMEOUT_SEC etc. are set.
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

# ── SSH options (uses vars from config.env) ───────────────────
SSH_COMMON_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="${HOME}/.ssh/known_hosts"
  -o LogLevel=ERROR
  -o ConnectTimeout="${SSH_CONNECT_TIMEOUT_SEC:-10}"
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=2
)

# ── SSH auth mode resolution ──────────────────────────────────
resolve_auth_mode() {
  if [[ "${USE_SSHPASS:-auto}" == "auto" ]]; then
    if command -v sshpass >/dev/null 2>&1; then
      USE_SSHPASS="1"
    else
      USE_SSHPASS="0"
      warn "sshpass not installed: falling back to SSH key authentication mode."
    fi
  fi
  [[ "${USE_SSHPASS}" == "1" ]] && require_cmd sshpass
}

# ── Remote command execution ──────────────────────────────────
run_remote() {
  local host="$1" port="$2" user="$3" pass="$4" remote_cmd="$5"
  local rc=0
  local timeout_sec="${REMOTE_CMD_TIMEOUT_SEC:-180}"

  if [[ "${USE_SSHPASS}" == "1" ]]; then
    timeout "${timeout_sec}s" \
      sshpass -p "$pass" ssh "${SSH_COMMON_OPTS[@]}" \
        -o NumberOfPasswordPrompts=1 -p "$port" "$user@$host" "$remote_cmd"
  else
    set +e
    timeout "${timeout_sec}s" \
      ssh "${SSH_COMMON_OPTS[@]}" -o BatchMode=yes -p "$port" "$user@$host" "$remote_cmd"
    rc=$?
    set -e
    if [[ $rc -eq 255 && -n "$pass" ]] && command -v sshpass >/dev/null 2>&1; then
      warn "Key authentication failed ($user@$host:$port). Retrying with password authentication."
      timeout "${timeout_sec}s" \
        sshpass -p "$pass" ssh "${SSH_COMMON_OPTS[@]}" \
          -o NumberOfPasswordPrompts=1 -p "$port" "$user@$host" "$remote_cmd"
      return
    fi
    return "$rc"
  fi
}

# ── Remote sudo execution ─────────────────────────────────────
run_remote_sudo() {
  local host="$1" port="$2" user="$3" pass="$4" sudo_pass="$5" remote_cmd="$6"
  local wrapped qpass qcmd
  printf -v qpass '%q' "$sudo_pass"
  printf -v qcmd  '%q' "$remote_cmd"
  wrapped="printf '%s\\n' $qpass | sudo -S -p '' bash -lc $qcmd"
  run_remote "$host" "$port" "$user" "$pass" "$wrapped"
}

# ── Per-node convenience wrappers ─────────────────────────────
# Use the node credentials from config.env and prepend `set -e` to every
# remote command, so callers only pass the command itself.
on_master()      { run_remote      "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS"                    "set -e; $1"; }
on_master_sudo() { run_remote_sudo "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" "$MASTER_SUDO_PASS" "set -e; $1"; }
on_guest()       { run_remote      "$GUEST_HOST"  "$GUEST_PORT"  "$GUEST_USER"  "$GUEST_PASS"                     "set -e; $1"; }
on_guest_sudo()  { run_remote_sudo "$GUEST_HOST"  "$GUEST_PORT"  "$GUEST_USER"  "$GUEST_PASS"  "$GUEST_SUDO_PASS"  "set -e; $1"; }

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
