#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="traffic-sim"
OVERRIDE_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run as root (sudo)."
    exit 1
  fi
}

require_delay_arg() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: sudo /opt/traffic-sim-service/set_delay.sh <delay_seconds>"
    exit 1
  fi

  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "delay_seconds must be a non-negative integer."
    exit 1
  fi
}

write_override() {
  local delay_seconds="$1"
  mkdir -p "${OVERRIDE_DIR}"
  cat > "${OVERRIDE_FILE}" <<EOF
[Service]
Environment=DELAY_SECONDS=${delay_seconds}
EOF
}

reload_and_restart() {
  systemctl daemon-reload
  systemctl restart "${SERVICE_NAME}"
}

print_summary() {
  local delay_seconds="$1"
  echo "Updated DELAY_SECONDS=${delay_seconds} for ${SERVICE_NAME}."
  echo "Check: sudo systemctl status ${SERVICE_NAME}"
}

require_root
require_delay_arg "$@"
write_override "$1"
reload_and_restart
print_summary "$1"
