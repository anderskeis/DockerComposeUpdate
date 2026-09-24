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

- `STACKS_DIR` defaults to `/opt/stacks` and can be overridden per run without editing the script:

```bash
sudo STACKS_DIR=/srv/stacks /usr/local/bin/docker-update.sh
```

- The lock file (see Cron) defaults to `/var/lock/docker-update.lock` and can be overridden the same way with `LOCK_FILE`.
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
- `-p`: Prune dangling (untagged) images after successful updates.
- `-a`: Prune all unused images after successful updates (includes dangling). If `-p` is also given, `-a` wins.
- `-s <name>`: Update one stack directory, for example `-s web-server`.
- `-h`: Show help.

The script exits nonzero when a stack is missing, an unexpected argument is given, or an operation fails. Pruning runs only after all updates succeed. A failing stack does not stop the others; failed stack names are listed in the final error.

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

A lock file prevents overlapping runs, so a slow update cannot pile up on the next cron trigger. Dry runs skip the lock.

The log file grows without bound. Rotate it with logrotate, or log to the journal instead:

```cron
0 3 * * 0 /usr/local/bin/docker-update.sh -p 2>&1 | logger -t docker-update
```

```bash
journalctl -t docker-update
```

---

## Troubleshooting

If you see an error like `: not found` or `bad interpreter` on the first line, the script likely contains invisible characters (a carriage return from Windows line endings or a Byte Order Mark). Fix it on Linux with one of:

```bash
sudo sed -i '1s/^\xEF\xBB\xBF//' /usr/local/bin/docker-update.sh
sudo dos2unix /usr/local/bin/docker-update.sh
```
