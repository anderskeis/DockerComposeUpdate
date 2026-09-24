#!/bin/bash

set -u

#
# Docker Compose Updater Script
#
# This script iterates through all subdirectories of a specified root directory,
# assuming each subdirectory contains a compose file.
# For each stack, it pulls the latest images and restarts the services.
#

# --- Configuration ---
# Override per run without editing the script, e.g.:
#   sudo STACKS_DIR=/srv/stacks /usr/local/bin/docker-update.sh
STACKS_DIR="${STACKS_DIR:-/opt/stacks}"
DRY_RUN=false
PRUNE_IMAGES=false
PRUNE_UNUSED=false
TARGET_STACK=""
TARGET_STACK_SET=false

# --- Helper Functions ---

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d          Dry run (print commands without executing)"
    echo "  -p          Prune dangling (untagged) images after successful updates"
    echo "  -a          Prune all unused images after successful updates (includes -p)"
    echo "  -s <name>   Update only a specific stack (directory name)"
    echo "  -h          Show this help message"
    exit "${1:-1}"
}

# --- Argument Parsing ---

while getopts "dpas:h" opt; do
    case $opt in
        d) DRY_RUN=true ;;
        p) PRUNE_IMAGES=true ;;
        a) PRUNE_UNUSED=true ;;
        s) TARGET_STACK="$OPTARG"; TARGET_STACK_SET=true ;;
        h) usage 0 ;;
        *) usage ;;
    esac
done

shift $((OPTIND - 1))
if [ "$#" -gt 0 ]; then
    error "Unexpected argument: $1"
    usage
fi

if [ "$TARGET_STACK_SET" = true ] && [ -z "$TARGET_STACK" ]; then
    error "Stack name must not be empty"
    exit 1
fi

# --- Script Body ---

if ! command -v docker >/dev/null 2>&1; then
    error "docker not found in PATH"
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    error "Docker Compose plugin not available"
    exit 1
fi

if [ "$DRY_RUN" = false ] && ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not reachable"
    exit 1
fi

if [ ! -d "$STACKS_DIR" ]; then
    error "Stacks directory not found at '$STACKS_DIR'"
    exit 1
fi

# Prevent overlapping runs (e.g. a slow update overlapping the next cron trigger).
# Dry runs are read-only and skip locking.
LOCK_FILE="${LOCK_FILE:-/var/lock/docker-update.lock}"
if [ "$DRY_RUN" = false ]; then
    if ! { exec 9>"$LOCK_FILE"; } 2>/dev/null; then
        error "Cannot create lock file: $LOCK_FILE (run as root, or set LOCK_FILE)"
        exit 1
    fi
    if ! flock -n 9; then
        error "Another instance is already running (lock: $LOCK_FILE)"
        exit 1
    fi
fi

log "Starting Docker Compose update..."
log "Root directory: $STACKS_DIR"
[ "$DRY_RUN" = true ] && log "Mode: DRY RUN"

# Define function to update a single stack
FAILED_STACKS=""

update_stack() {
    local stack_path="$1"
    local stack_name
    stack_name=$(basename "$stack_path")
    local compose_file=""

    # Check for various compose filenames
    for file in "compose.yaml" "compose.yml" "docker-compose.yaml" "docker-compose.yml"; do
        if [ -f "${stack_path}/${file}" ]; then
            compose_file="$file"
            break
        fi
    done

    if [ -z "$compose_file" ]; then
        log "Skipping $stack_name: No compose file found."
        return
    fi

    log "--- Updating stack: $stack_name (File: $compose_file) ---"

    # Use a subshell to isolate directory changes
    (
        cd "$stack_path" || exit 1

        if [ "$DRY_RUN" = true ]; then
            echo "  [DRY-RUN] cd $stack_path"
            echo "  [DRY-RUN] docker compose -f $compose_file pull"
            echo "  [DRY-RUN] docker compose -f $compose_file up -d"
        else
            # Pull latest images
            if ! docker compose -f "$compose_file" pull; then
                error "Failed to pull images for $stack_name"
                exit 1
            fi

            # Restart services
            if ! docker compose -f "$compose_file" up -d; then
                error "Failed to bring up $stack_name"
                exit 1
            fi
        fi
    )

    local update_status=$?
    if [ "$update_status" -eq 0 ]; then
        log "--- Finished updating stack: $stack_name ---"
    else
        error "Update failed for stack: $stack_name"
        FAILED_STACKS="$FAILED_STACKS $stack_name"
    fi
    echo ""
    return "$update_status"
}

# Main execution logic
UPDATE_FAILED=false
if [ -n "$TARGET_STACK" ]; then
    # Update specific stack
    case "$TARGET_STACK" in
        .|..|*/*)
            error "Stack name must be a single directory name: $TARGET_STACK"
            exit 1
            ;;
    esac

    target_path="${STACKS_DIR}/${TARGET_STACK}"
    if [ ! -d "$target_path" ]; then
        error "Stack directory not found: $target_path"
        exit 1
    fi

    update_stack "$target_path" || UPDATE_FAILED=true
else
    # Update all stacks
    for stack in "$STACKS_DIR"/*/; do
        [ -d "$stack" ] || continue # Skip if not a directory
        update_stack "${stack%/}" || UPDATE_FAILED=true # Remove trailing slash
    done
fi

# Cleanup
if [ "$UPDATE_FAILED" = false ] && { [ "$PRUNE_UNUSED" = true ] || [ "$PRUNE_IMAGES" = true ]; }; then
    if [ "$PRUNE_UNUSED" = true ]; then
        prune_cmd="docker image prune -af"
    else
        prune_cmd="docker image prune -f"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] $prune_cmd"
    else
        log "Pruning images..."
        if ! $prune_cmd; then
            error "Failed to prune images"
            UPDATE_FAILED=true
        fi
    fi
fi

if [ "$UPDATE_FAILED" = true ]; then
    if [ -n "$FAILED_STACKS" ]; then
        error "Failed stacks:$FAILED_STACKS"
    fi
    error "One or more operations failed."
    exit 1
fi

log "All operations completed."

