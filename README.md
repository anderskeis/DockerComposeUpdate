# Docker Compose Updater

Updates Docker Compose stacks in subdirectories of `STACKS_DIR`: it detects a Compose file, pulls images, and runs `docker compose up -d`. It is intended for root's crontab and requires Docker Engine with the Compose plugin.

---

## Installation

### Download the Script

```bash
sudo curl -o /usr/local/bin/docker-update.sh https://raw.githubusercontent.com/anderskeis/DockerComposeUpdate/main/compose-update.sh
sudo chmod +x /usr/local/bin/docker-update.sh
```

---

## Configuration

Set the directory containing one subdirectory per stack:

```bash
sudo nano /usr/local/bin/docker-update.sh
```

```bash
# --- Configuration ---
STACKS_DIR="/opt/stacks"
```

- `STACKS_DIR` defaults to `/opt/stacks`.
- Compose files are checked in this order:

1. `compose.yaml`
2. `compose.yml`
3. `docker-compose.yaml`
4. `docker-compose.yml`

---

## Usage

```bash
sudo /usr/local/bin/docker-update.sh [options]
```

### Options

- `-d`: Print commands without running them.
- `-p`: Prune unused images after successful updates.
- `-s <name>`: Update one stack directory, for example `-s web-server`.
- `-h`: Show help.

The script exits nonzero when a stack is missing or an operation fails. With `-p`, pruning runs only after all updates succeed.

### Examples

```bash
sudo /usr/local/bin/docker-update.sh
```

```bash
sudo /usr/local/bin/docker-update.sh -d
```

```bash
sudo /usr/local/bin/docker-update.sh -p
```

```bash
sudo /usr/local/bin/docker-update.sh -s my-app
```

---

## Cron

```bash
sudo crontab -e
```

Run weekly on Sunday at 03:00, with pruning and a log file:

```cron
0 3 * * 0 /usr/local/bin/docker-update.sh -p >> /var/log/docker-update.log 2>&1
```
