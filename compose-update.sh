#!/bin/bash

#
# --- IMPORTANT NOTE ON EXECUTION ERRORS ---
# If you see an error like ": not found" or "bad interpreter" on the first line,
# it's likely due to invisible characters (like a carriage return from Windows
# or a Byte Order Mark).
#
# To fix this on a Linux system, you can run one of the following commands:
# sed -i '1s/^\xEF\xBB\xBF//' /path/to/your/script.sh
# or
# dos2unix /path/to/your/script.sh
# ------------------------------------------
#

#
# Docker Compose Updater Script
#
# This script iterates through all subdirectories of a specified root directory,
# assuming each subdirectory contains a compose file.
# For each stack, it pulls the latest images and restarts the services.
#

# --- Configuration ---
STACKS_DIR="/opt/stacks"
DRY_RUN=false
PRUNE_IMAGES=false
TARGET_STACK=""

# --- Helper Functions ---

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d          Dry run (print commands without executing)"
    echo "  -p          Prune unused images after update"
    echo "  -s <name>   Update only a specific stack (directory name)"
    echo "  -h          Show this help message"
    exit 1
}

# --- Argument Parsing ---

while getopts "dps:h" opt; do
    case $opt in
        d) DRY_RUN=true ;;
        p) PRUNE_IMAGES=true ;;
        s) TARGET_STACK="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# --- Script Body ---

if [ ! -d "$STACKS_DIR" ]; then
    error "Stacks directory not found at '$STACKS_DIR'"
    exit 1
fi

log "Starting Docker Compose update..."
log "Root directory: $STACKS_DIR"
[ "$DRY_RUN" = true ] && log "Mode: DRY RUN"

# Define function to update a single stack
update_stack() {
    local stack_path="$1"
    local stack_name=$(basename "$stack_path")
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

    if [ $? -eq 0 ]; then
        log "--- Finished updating stack: $stack_name ---"
    else
        error "Update failed for stack: $stack_name"
    fi
    echo ""
}

# Main execution logic
if [ -n "$TARGET_STACK" ]; then
    # Update specific stack
    target_path="${STACKS_DIR}/${TARGET_STACK}"
    if [ -d "$target_path" ]; then
        update_stack "$target_path"
    else
        error "Stack directory not found: $target_path"
    fi
else
    # Update all stacks
    for stack in "$STACKS_DIR"/*/; do
        [ -d "$stack" ] || continue # Skip if not a directory
        update_stack "${stack%/}"   # Remove trailing slash
    done
fi

# Cleanup
if [ "$PRUNE_IMAGES" = true ] && [ "$DRY_RUN" = false ]; then
    log "Pruning unused images..."
    docker image prune -f
fi

log "All operations completed."

