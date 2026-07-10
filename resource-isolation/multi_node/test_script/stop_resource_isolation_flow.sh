#!/usr/bin/env bash
set -euo pipefail
# Multi-node orchestrator: stop/teardown flow
# Env overrides: see config.env

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./config.env
source "${SCRIPT_DIR}/config.env"
# shellcheck source=./lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"

main() {
  require_cmd ssh
  require_cmd timeout
  resolve_auth_mode
  info "Auth mode: USE_SSHPASS=$USE_SSHPASS"

  info "Step 1) master: docker compose down"
  run_remote "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" \
    "set -e; cd '$MASTER_NUC_MASTER_DIR'; docker compose down"

  info "Step 2) guest: monitoring stop.sh"
  run_remote "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" \
    "set -e; cd '$GUEST_MONITORING_DIR'; ./stop.sh"

  info "Step 3) master/guest: stop timpani-o, timpani-n processes"
  info "  - master process stop"
  run_remote_sudo "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" "$MASTER_SUDO_PASS" \
    "set -e; pkill -x timpani-o || true; pkill -x timpani-n || true"
  info "  - guest process stop"
  run_remote_sudo "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" "$GUEST_SUDO_PASS" \
    "set -e; pkill -x timpani-o || true; pkill -x timpani-n || true"

  info "Step 4) master: pullpiri runtime uninstall script"
  run_remote_sudo "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" "$MASTER_SUDO_PASS" \
    "set -e; bash '$MASTER_TEST_SCRIPT_DIR/pullpiri/scripts/uninstall-pullpiri.sh' '$GUEST_HOST' '$GUEST_PORT' '$GUEST_USER' '$GUEST_PASS' '$GUEST_SUDO_PASS' '$GUEST_TEST_SCRIPT_DIR'"

  info "Step 5) guest: sudo podman rm -f --all"
  run_remote_sudo "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" "$GUEST_SUDO_PASS" \
    "set -e; podman rm -f --all || true"

  info "Teardown done."
}

main "$@"
