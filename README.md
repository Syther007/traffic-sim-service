# traffic-sim-service

Systemd traffic simulation service based on `lightCons_cron.sh`.

## Features

- Continuous request loop while systemd service is active.
- Writes live runtime status to `statistics.txt`.
- Writes `debug.log` and `error.log`.
- Enforces 20 MB cap for both logs in-script and via logrotate.

## One-command deploy

```bash
curl -fsSL https://raw.githubusercontent.com/Syther007/traffic-sim-service/main/install.sh | sudo bash
```

Optional: override repo URL if needed:

```bash
curl -fsSL https://raw.githubusercontent.com/Syther007/traffic-sim-service/main/install.sh | sudo REPO_URL="https://github.com/Syther007/traffic-sim-service.git" bash
```

## Service control

```bash
sudo systemctl status traffic-sim
sudo systemctl start traffic-sim
sudo systemctl stop traffic-sim
sudo systemctl restart traffic-sim
sudo systemctl enable traffic-sim
```

## Runtime files

- Service install directory: `/opt/traffic-sim-service`
- Status file: `/opt/traffic-sim-service/statistics.txt`
- Debug log: `/opt/traffic-sim-service/logs/debug.log`
- Error log: `/opt/traffic-sim-service/logs/error.log`

## Configure runtime behavior

Edit the unit file and restart the service:

```bash
sudo systemctl edit --full traffic-sim
sudo systemctl daemon-reload
sudo systemctl restart traffic-sim
```

Useful environment values in the unit:

- `DELAY_SECONDS`
- `REQUEST_TIMEOUT_SECONDS`
- `PROXY_ADDR`
- `MAX_LOG_SIZE_BYTES`

## Troubleshooting

- Check service health:
  ```bash
  sudo systemctl status traffic-sim --no-pager
  ```
- Review recent service logs:
  ```bash
  sudo journalctl -u traffic-sim -n 100 --no-pager
  ```
- Validate generated stats and logs:
  ```bash
  sudo cat /opt/traffic-sim-service/statistics.txt
  sudo ls -lh /opt/traffic-sim-service/logs/
  ```

## Uninstall

Preferred:

```bash
curl -fsSL https://raw.githubusercontent.com/Syther007/traffic-sim-service/main/uninstall.sh | sudo bash
```

Local repo method:

```bash
sudo bash ./uninstall.sh
```

Manual method:

```bash
sudo systemctl stop traffic-sim || true
sudo systemctl disable traffic-sim || true
sudo rm -f /etc/systemd/system/traffic-sim.service
sudo rm -f /etc/logrotate.d/traffic-sim
sudo systemctl daemon-reload
sudo userdel trafficsim || true
sudo rm -rf /opt/traffic-sim-service
```
