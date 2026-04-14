# traffic-sim-service

Systemd traffic simulation service based on `lightCons_cron.sh`.

## Features

- Continuous request loop while systemd service is active.
- Writes live runtime status to `statistics.txt`.
- Writes `debug.log` and `error.log`.
- Enforces 20 MB cap for both logs in-script and via logrotate.

## One-command deploy

Default delay is 5 seconds.

```bash
curl -fsSL https://raw.githubusercontent.com/Syther007/traffic-sim-service/main/install.sh | sudo bash
```

Set custom delay during install:

```bash
curl -fsSL https://raw.githubusercontent.com/Syther007/traffic-sim-service/main/install.sh | sudo DELAY_SECONDS=10 bash
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

Simple post-install delay update:

```bash
sudo /opt/traffic-sim-service/set_delay.sh 10
```

Manual method:

```bash
sudo mkdir -p /etc/systemd/system/traffic-sim.service.d
printf "[Service]\nEnvironment=DELAY_SECONDS=10\n" | sudo tee /etc/systemd/system/traffic-sim.service.d/override.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl restart traffic-sim
```

Useful environment values:

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
