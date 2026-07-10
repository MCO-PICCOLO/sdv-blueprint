#!/usr/bin/env bash
set -euo pipefail
# Guest preflight: build images, compile/upload Arduino sketches
# Run directly on the guest node.
# Env overrides: see ../config.env  (SKIP_ARDUINO=1, SKIP_IMAGE=1)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../config.env
source "${SCRIPT_DIR}/../config.env"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

main() {
  require_cmd sudo
  require_cmd podman
  require_cmd arduino-cli

  info "=== Guest preflight ==="
  info "NUC_GUEST_DIR=$GUEST_NUC_GUEST_DIR"
  [[ -d "$GUEST_NUC_GUEST_DIR" ]] || { err "missing dir: $GUEST_NUC_GUEST_DIR"; exit 1; }

  if [[ "$SKIP_ARDUINO" != "1" ]]; then
    ensure_arduino_lib "Adafruit NeoPixel"
    info "Compile/upload Arduino sketches"
    cd "$GUEST_ARDUINO_DIR"
    bash ./compile.sh
    bash ./install.sh
  else
    warn "Skip Arduino step (SKIP_ARDUINO=1)"
  fi

  if [[ "$SKIP_IMAGE" != "1" ]]; then
    info "Build guest images"
    cd "$GUEST_NUC_GUEST_DIR/led-timpani-controller"
    sudo podman build -t localhost/led-timpani-controller:latest .

    cd "$GUEST_NUC_GUEST_DIR/led-normal-controller"
    sudo podman build -t localhost/led-normal-controller:latest .

    cd "$GUEST_NUC_GUEST_DIR/kuksa-bridge"
    sudo podman build -t localhost/failop-kuksa-bridge-guest:latest .

    info "Ensure stress-ng image"
    if ! sudo podman image exists localhost/stress-ng:latest; then
      sudo podman build -t localhost/stress-ng:latest - <<'EOF'
FROM alpine:latest
RUN apk add --no-cache stress-ng
ENTRYPOINT ["stress-ng"]
EOF
    fi
  else
    warn "Skip image step (SKIP_IMAGE=1)"
  fi

  [[ -f "$GUEST_MONITORING_DIR/docker-compose.yml" ]] || warn "monitoring compose file not found"

  info "=== Guest preflight done ==="
}

main "$@"
