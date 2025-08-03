# Docker Compose Updater Script

A simple  bash script to automate the update process for all your Docker Compose-managed applications, if they are all in one directory

The script iterates through a specified directory, finds all subdirectories containing a `compose.yaml` (or similarly named, path and filename is configurable in the script ) file, pulls the latest images for each service, and restarts the containers with the new images.

---

## 1. Initial Setup

Before you can use the script, you need to download it from GitHub and make it executable.

### Download the Script

Use `curl` to download the script from its GitHub repository and place it in `/usr/local/bin`, a standard directory for user-installed executables.

```bash
sudo curl -o /usr/local/bin/docker-update.sh https://raw.githubusercontent.com/anderskeis/DockerComposeUpdate/compose-update.sh
```

> **Note:** Replace the URL with the actual raw link to your script on GitHub.

### Make it Executable

Grant execute permissions to the script file:

```bash
sudo chmod +x /usr/local/bin/docker-update.sh
```

---

## 2. Configuration

The script has two variables at the top that you can configure to match your environment by editing the file:

```bash
sudo nano /usr/local/bin/docker-update.sh
```

```bash
# --- Configuration ---
# The root directory where all your Docker Compose stacks are located.
STACKS_DIR="/opt/stacks"

# The name of the compose file to look for in each directory.
COMPOSE_FILENAME="compose.yaml"
```

- `STACKS_DIR`: This is the absolute path to the directory where all your application stack folders are located. Default is `/opt/stacks`.

- `COMPOSE_FILENAME`: This is the name of your compose file. Common names are `compose.yaml`, `docker-compose.yml`, or `compose.yml`. The script will look for this exact filename in each subdirectory of `STACKS_DIR`.

---

## 3. Usage

To run the script and update all your applications:

```bash
sudo /usr/local/bin/docker-update.sh
```

The script will provide detailed output, showing which stack it is currently processing and skipping any directories that do not contain the specified compose file.

---

## Scheduling with Cron (Optional)

You can automate the update process by scheduling the script with `cron` (e.g., weekly).

### Edit Crontab

```bash
sudo crontab -e
```

### Add a Cron Job

To run the script every Sunday at 3:00 AM:

```cron
0 3 * * 0 /usr/local/bin/docker-update.sh > /var/log/docker-update.log 2>&1
```

This will run the script and save its output to a log file for later review.
