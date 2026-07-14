#!/usr/bin/env bash
set -euo pipefail
# Single-node orchestrator: start flow
# Everything runs locally on this machine. Env overrides: see config.env

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./config.env
source "${SCRIPT_DIR}/config.env"
# shellcheck source=./lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"

main() {
  require_cmd docker

  NODE_IP="$(detect_node_ip)"
  [[ -n "${NODE_IP}" ]] || { err "Could not determine local node IP."; exit 1; }
  info "Node: name='${NODE_NAME}' ip='${NODE_IP}'"

  info "Step 1) docker compose up -d"
  # apiserver binds to NODE_IP (settings.yaml host.ip); pass it so the serial-bridge
  # reaches the apiserver on the same address instead of the docker host gateway.
  ( cd "${SERIAL_BRIDGE_DIR}" && MASTER_IP="${NODE_IP}" docker compose up -d )

  info "Step 2) pullpiri runtime install"
  run_sudo bash "${TEST_SCRIPT_DIR}/pullpiri/scripts/install-pullpiri.sh" "${NODE_IP}"

  info "Step 3) restart nodeagent.service"
  run_sudo systemctl restart nodeagent.service

  info "Step 4) start monitoring script (background)"
  ( cd "${MONITORING_DIR}" && nohup ./start.sh > monitoring_start.log 2>&1 & echo monitoring_started )

  info "Step 5) start timpani-o (background)"
  run_sudo bash -c "cd '${TIMPANI_O_DIR}'; nohup ./timpani-o -c '${NODE_CONFIG_YAML}' > '${TIMPANI_O_LOG}' 2>&1 & echo timpani_o_started"

  echo
  warn "Step 6) After operating the Arduino, proceed with the YAML transmission."
  warn "Watching container '${DATABROKER_CONTAINER}' log for up to ${WAIT_LOG_TIMEOUT_SEC}s:"
  echo "       (regex: ${DATABROKER_LOG_REGEX})"

  set +e
  c="${DATABROKER_CONTAINER}"
  if ! docker ps --format '{{.Names}}' | grep -Fx "${c}" >/dev/null 2>&1; then
    c="$(docker ps --format '{{.Names}}' | grep -m1 -E 'resiso-serial-bridge|databroker|broker' || true)"
  fi
  step6_rc=124
  if [[ -z "${c}" ]]; then
    warn "data broker container not found"
  else
    info "watching container: ${c}"
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    end=$(( $(date +%s) + WAIT_LOG_TIMEOUT_SEC ))
    while [[ $(date +%s) -lt ${end} ]]; do
      if docker logs --since "${ts}" "${c}" 2>&1 | grep -m1 -E "${DATABROKER_LOG_REGEX}" >/dev/null; then
        info "Step 6 pattern matched"
        step6_rc=0
        break
      fi
      sleep 2
    done
  fi
  set -e

  if [[ ${step6_rc} -ne 0 ]]; then
    warn "Step 6 log watch failed/timed out (code: ${step6_rc})."
    read -r -p "Continue with Step 7? [y/N] " ans
    if [[ ! "${ans}" =~ ^[Yy]$ ]]; then
      err "Aborted by user."
      exit 1
    fi
  fi

  info "Step 7) run timpani-n (background)"
  run_sudo bash -c "cd '${TIMPANI_N_DIR}'; nohup ./timpani-n -n '${NODE_NAME}' -s -l 4 -P 80 '${NODE_IP}' > '${TIMPANI_N_LOG}' 2>&1 & echo timpani_n_started"
  info "Step 7) timpani-n runs in background."
  info "Step 7) log file: ${TIMPANI_N_DIR}/${TIMPANI_N_LOG}"

  info "Done."
}

main "$@"
