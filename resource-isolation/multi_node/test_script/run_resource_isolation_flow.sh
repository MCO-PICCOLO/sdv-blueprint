#!/usr/bin/env bash
set -euo pipefail
# Multi-node orchestrator: start flow
# Env overrides: see config.env

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./config.env
source "${SCRIPT_DIR}/config.env"
# shellcheck source=./lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"

main() {
  require_cmd ssh
  resolve_auth_mode
  info "Auth mode: USE_SSHPASS=$USE_SSHPASS"

  # MASTER_NODE_IP / GUEST_NODE_IP are required (set them in config.env).
  [[ -n "${MASTER_NODE_IP}" ]] || { err "MASTER_NODE_IP is not set. Please set it in config.env."; exit 1; }
  [[ -n "${GUEST_NODE_IP}" ]]  || { err "GUEST_NODE_IP is not set. Please set it in config.env."; exit 1; }
  info "Master node IP: ${MASTER_NODE_IP}"
  info "Guest node IP: ${GUEST_NODE_IP}"

  info "Step 1) master: docker compose up -d"
  on_master "cd '$MASTER_SERIAL_BRIDGE_DIR'; MASTER_IP='$MASTER_NODE_IP' docker compose up -d"

  info "Step 2) master: pullpiri runtime install script"
  on_master_sudo "bash '$MASTER_TEST_SCRIPT_DIR/pullpiri/scripts/install-pullpiri.sh' '' '$GUEST_HOST' '$GUEST_PORT' '$GUEST_USER' '$GUEST_PASS' '$GUEST_SUDO_PASS' '$GUEST_NODE_IP' '$GUEST_TEST_SCRIPT_DIR'"

  info "Step 3) guest: restart nodeagent.service"
  on_guest_sudo "systemctl restart nodeagent.service"

  info "Step 4) guest: start monitoring script (background)"
  on_guest "cd '$GUEST_MONITORING_DIR'; nohup ./start.sh > monitoring_start.log 2>&1 & echo monitoring_started"

  info "Step 5) master: start timpani-o (background)"
  on_master_sudo "cd '$MASTER_TIMPANI_O_DIR'; nohup ./timpani-o -c '$NODE_CONFIG_YAML' > timpani-o.log 2>&1 & echo timpani_o_started"

  echo
  warn "Step 6) After operating the Arduino, proceed with the YAML transmission."
  warn "Watching container '${DATABROKER_CONTAINER}' log on master for up to ${WAIT_LOG_TIMEOUT_SEC}s (regex: ${DATABROKER_LOG_REGEX})"

  set +e
  on_master "\
     c='$DATABROKER_CONTAINER'; \
     docker ps --format '{{.Names}}' | grep -Fx \"\$c\" >/dev/null 2>&1 || \
       c=\$(docker ps --format '{{.Names}}' | grep -m1 -E 'resiso-serial-bridge|databroker|broker' || true); \
     [[ -n \"\$c\" ]] || { echo '[WARN] data broker container not found'; exit 124; }; \
     echo \"[INFO] watching container: \$c\"; \
     ts=\$(date -u +%Y-%m-%dT%H:%M:%SZ); \
     end=\$((\$(date +%s) + ${WAIT_LOG_TIMEOUT_SEC})); \
     while [[ \$(date +%s) -lt \$end ]]; do \
       docker logs --since \"\$ts\" \"\$c\" 2>&1 | grep -m1 -E \"$DATABROKER_LOG_REGEX\" >/dev/null && exit 0; \
       sleep 2; \
     done; exit 124"
  step6_rc=$?
  set -e

  if [[ $step6_rc -ne 0 ]]; then
    warn "Step 6 log watch failed/timed out (code: $step6_rc)."
    read -r -p "Continue with Step 7? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { err "Aborted by user."; exit 1; }
  fi

  info "Step 7) guest: run timpani-n (background)"
  on_guest_sudo "cd '$GUEST_TIMPANI_N_DIR'; nohup ./timpani-n -n guest -s -l 4 -P 80 $MASTER_NODE_IP > '$GUEST_TIMPANI_N_LOG' 2>&1 & echo timpani_n_started"
  info "Step 7) log file: $GUEST_TIMPANI_N_DIR/$GUEST_TIMPANI_N_LOG"

  info "Done."
}

main "$@"
