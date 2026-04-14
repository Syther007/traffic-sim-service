#!/usr/bin/env bash

set -euo pipefail

SERVICE_NAME="traffic-sim"
SERVICE_USER="trafficsim"
INSTALL_DIR="/opt/traffic-sim-service"
SYSTEMD_UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
SYSTEMD_OVERRIDE_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
SYSTEMD_OVERRIDE_FILE="${SYSTEMD_OVERRIDE_DIR}/override.conf"
LOGROTATE_PATH="/etc/logrotate.d/${SERVICE_NAME}"
REPO_URL="${REPO_URL:-https://github.com/Syther007/traffic-sim-service.git}"
DELAY_SECONDS="${DELAY_SECONDS:-5}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run installer as root (sudo)."
    exit 1
  fi
}

install_dependencies() {
  apt-get update
  apt-get install -y curl bash coreutils gawk logrotate ca-certificates git
}

create_service_user() {
  if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
    useradd --system --home-dir "${INSTALL_DIR}" --create-home --shell /usr/sbin/nologin "${SERVICE_USER}"
  fi
}

fetch_repo() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  git clone "${REPO_URL}" "${temp_dir}/repo"
  mkdir -p "${INSTALL_DIR}"
  cp "${temp_dir}/repo/lightCons_cron.sh" "${INSTALL_DIR}/lightCons_cron.sh"
  cp "${temp_dir}/repo/set_delay.sh" "${INSTALL_DIR}/set_delay.sh"
  cp "${temp_dir}/repo/traffic-sim.service" "${INSTALL_DIR}/traffic-sim.service"
  cp "${temp_dir}/repo/traffic-sim.logrotate" "${INSTALL_DIR}/traffic-sim.logrotate"
  rm -rf "${temp_dir}"
}

setup_permissions() {
  mkdir -p "${INSTALL_DIR}/logs"
  touch "${INSTALL_DIR}/statistics.txt" "${INSTALL_DIR}/logs/debug.log" "${INSTALL_DIR}/logs/error.log"
  chmod 0755 "${INSTALL_DIR}/lightCons_cron.sh"
  chmod 0755 "${INSTALL_DIR}/set_delay.sh"
  chown -R "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}"
}

write_systemd_override() {
  mkdir -p "${SYSTEMD_OVERRIDE_DIR}"
  cat > "${SYSTEMD_OVERRIDE_FILE}" <<EOF
[Service]
Environment=DELAY_SECONDS=${DELAY_SECONDS}
EOF
}

install_system_files() {
  cp "${INSTALL_DIR}/traffic-sim.service" "${SYSTEMD_UNIT_PATH}"
  cp "${INSTALL_DIR}/traffic-sim.logrotate" "${LOGROTATE_PATH}"
  chmod 0644 "${SYSTEMD_UNIT_PATH}" "${LOGROTATE_PATH}"
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}"
  systemctl restart "${SERVICE_NAME}"
}

print_summary() {
  cat <<'EOF'
Install complete.

Service control:
  sudo systemctl status traffic-sim
  sudo systemctl restart traffic-sim
  sudo systemctl stop traffic-sim
  sudo systemctl start traffic-sim

Runtime files:
  /opt/traffic-sim-service/statistics.txt
  /opt/traffic-sim-service/logs/debug.log
  /opt/traffic-sim-service/logs/error.log

Configured delay:
  DELAY_SECONDS=${DELAY_SECONDS}

Update delay after install:
  sudo /opt/traffic-sim-service/set_delay.sh 10
EOF
}

require_root
install_dependencies
create_service_user
fetch_repo
setup_permissions
write_systemd_override
install_system_files
print_summary
