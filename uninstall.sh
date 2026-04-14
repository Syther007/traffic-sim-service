#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="traffic-sim"
SERVICE_USER="trafficsim"
INSTALL_DIR="/opt/traffic-sim-service"
SYSTEMD_UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
LOGROTATE_PATH="/etc/logrotate.d/${SERVICE_NAME}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run uninstaller as root (sudo)."
    exit 1
  fi
}

remove_service() {
  systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
  systemctl disable "${SERVICE_NAME}" 2>/dev/null || true
  rm -f "${SYSTEMD_UNIT_PATH}"
  systemctl daemon-reload
}

remove_logrotate() {
  rm -f "${LOGROTATE_PATH}"
}

remove_runtime_files() {
  rm -rf "${INSTALL_DIR}"
}

remove_service_user() {
  if id -u "${SERVICE_USER}" >/dev/null 2>&1; then
    userdel "${SERVICE_USER}" || true
  fi
}

print_summary() {
  cat <<'EOF'
Uninstall complete.

Removed:
  - systemd unit: /etc/systemd/system/traffic-sim.service
  - logrotate config: /etc/logrotate.d/traffic-sim
  - install directory: /opt/traffic-sim-service
  - service user: trafficsim (if present)
EOF
}

require_root
remove_service
remove_logrotate
remove_runtime_files
remove_service_user
print_summary
