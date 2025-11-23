# Docker Compose Updater Script

A robust bash script to automate the update process for Docker Compose-managed applications.

The script iterates through a specified root directory, finds subdirectories containing Docker Compose files (auto-detecting `compose.yaml`, `docker-compose.yml`, etc.), pulls the latest images, and restarts the services.

It includes features for dry-runs, targeting specific stacks, and cleaning up unused images.

---

## 1. Initial Setup

### Download the Script

Use `curl` to download the script and place it in `/usr/local/bin`.

```bash
sudo curl -o /usr/local/bin/docker-update.sh https://raw.githubusercontent.com/anderskeis/DockerComposeUpdate/main/compose-update.sh
```

### Make it Executable

```bash
sudo chmod +x /usr/local/bin/docker-update.sh
```

---

## 2. Configuration

You can configure the default root directory by editing the top of the script:

```bash
sudo nano /usr/local/bin/docker-update.sh
```

```bash
# --- Configuration ---
STACKS_DIR="/opt/stacks"
```

- `STACKS_DIR`: The default path where your stack folders are located.

The script automatically looks for the following files in priority order:
1. `compose.yaml`
2. `compose.yml`
3. `docker-compose.yaml`
4. `docker-compose.yml`

---

## 3. Usage

```bash
sudo /usr/local/bin/docker-update.sh [options]
```

### Options

| Flag | Description |
|------|-------------|
| `-d` | **Dry Run**: Print commands without executing them. Useful for testing. |
| `-p` | **Prune**: Remove unused "dangling" images after the update completes. |
| `-s <name>` | **Specific Stack**: Update only the specified directory name (e.g., `-s web-server`). |
| `-h` | **Help**: Show usage information. |

### Examples

**Update all stacks:**
```bash
sudo /usr/local/bin/docker-update.sh
```

**Check what would happen (Dry Run):**
```bash
sudo /usr/local/bin/docker-update.sh -d
```

**Update all stacks and remove old images:**
```bash
sudo /usr/local/bin/docker-update.sh -p
```

**Update only the `my-app` stack:**
```bash
sudo /usr/local/bin/docker-update.sh -s my-app
```

---

## 4. Scheduling with Cron

You can automate the update process using `cron`.

### Edit Crontab
```bash
sudo crontab -e
```

### Example Cron Job
Run every Sunday at 3:00 AM, update all stacks, prune old images, and log output:

```cron
0 3 * * 0 /usr/local/bin/docker-update.sh -p >> /var/log/docker-update.log 2>&1
```
