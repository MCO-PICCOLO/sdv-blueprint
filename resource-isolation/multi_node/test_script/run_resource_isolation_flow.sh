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

  info "Step 1) master: docker compose up -d"
  run_remote "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" \
    "set -e; cd '$MASTER_NUC_MASTER_DIR'; docker compose up -d"

  info "Step 2) master: pullpiri runtime install script"
  run_remote_sudo "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" "$MASTER_SUDO_PASS" \
    "set -e; bash '$MASTER_TEST_SCRIPT_DIR/pullpiri/scripts/install-pullpiri.sh' '' '$GUEST_HOST' '$GUEST_PORT' '$GUEST_USER' '$GUEST_PASS' '$GUEST_SUDO_PASS' '$GUEST_NODE_IP' '$GUEST_TEST_SCRIPT_DIR'"

  info "Step 3) guest: sudo systemctl restart nodeagent.service"
  run_remote_sudo "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" "$GUEST_SUDO_PASS" \
    "set -e; systemctl restart nodeagent.service"

  info "Step 4) guest: start monitoring script (background)"
  run_remote "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" \
    "set -e; cd '$GUEST_MONITORING_DIR'; nohup ./start.sh > monitoring_start.log 2>&1 & echo monitoring_started"

  info "Step 5) master: start timpani-o (background)"
  run_remote_sudo "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" "$MASTER_SUDO_PASS" \
    "set -e; cd '$MASTER_TIMPANI_O_DIR'; nohup ./timpani-o -c '$NODE_CONFIG_YAML' > timpani-o.log 2>&1 & echo timpani_o_started"

  echo
  warn "Step 6) After operating the Arduino, proceed with the YAML transmission."
  warn "Watching the following log for up to ${WAIT_LOG_TIMEOUT_SEC}s:"
  echo "       $DATABROKER_LOG_PATTERN"
  echo "       (regex fallback: $DATABROKER_LOG_REGEX)"

  # Wait for expected data broker log pattern on master
  set +e
  run_remote "$MASTER_HOST" "$MASTER_PORT" "$MASTER_USER" "$MASTER_PASS" \
    "set -e; \
     c='$DATABROKER_CONTAINER'; \
     docker ps --format '{{.Names}}' | grep -Fx \"$DATABROKER_CONTAINER\" >/dev/null 2>&1 || \
       c=\$(docker ps --format '{{.Names}}' | grep -m1 -E 'failop-serial-bridge|databroker|broker' || true); \
     if [[ -z \"\$c\" ]]; then \
       echo '[WARN] data broker container not found'; \
       exit 124; \
     fi; \
     echo \"[INFO] watching container: \$c\"; \
     ts=\$(date -u +%Y-%m-%dT%H:%M:%SZ); \
     end=\$((\$(date +%s) + ${WAIT_LOG_TIMEOUT_SEC})); \
     while [[ \$(date +%s) -lt \$end ]]; do \
       if docker logs --since \"\$ts\" \"\$c\" 2>&1 | grep -m1 -E \"$DATABROKER_LOG_REGEX\" >/dev/null; then \
         echo '[INFO] Step 6 pattern matched'; \
         exit 0; \
       fi; \
       sleep 2; \
     done; \
     exit 124"
  step6_rc=$?
  set -e

  if [[ $step6_rc -ne 0 ]]; then
    warn "Step 6 log watch failed/timed out (code: $step6_rc)."
    read -r -p "Continue with Step 7? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
      err "Aborted by user."
      exit 1
    fi
  fi

  info "Step 7) guest: run timpani-n"
  run_remote_sudo "$GUEST_HOST" "$GUEST_PORT" "$GUEST_USER" "$GUEST_PASS" "$GUEST_SUDO_PASS" \
    "set -e; cd '$GUEST_TIMPANI_N_DIR'; nohup ./timpani-n -n guest -s -l 4 -P 80 192.168.0.3 > '$GUEST_TIMPANI_N_LOG' 2>&1 & echo timpani_n_started"
  info "Step 7) timpani-n runs in background on guest."
  info "Step 7) log file: $GUEST_TIMPANI_N_DIR/$GUEST_TIMPANI_N_LOG"

  info "Done."
}

main "$@"
