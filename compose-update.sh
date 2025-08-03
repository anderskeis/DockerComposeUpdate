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
# The root directory where all your Docker Compose stacks are located.
STACKS_DIR="/opt/stacks"
# The name of the compose file to look for in each directory.
COMPOSE_FILENAME="compose.yaml"

# --- Script Body ---

# Check if the stacks directory exists
if [ ! -d "$STACKS_DIR" ]; then
  echo "Error: Stacks directory not found at '$STACKS_DIR'"
  exit 1
fi

echo "----------------------------------------------------"
echo "Starting update for all Docker Compose stacks..."
echo "Root directory: $STACKS_DIR"
echo "----------------------------------------------------"
echo

# Iterate over each subdirectory in the STACKS_DIR
# The */ ensures we only match directories.
for stack in "$STACKS_DIR"/*/; do
  # Check if the compose file exists in the directory
  if [ -f "${stack}${COMPOSE_FILENAME}" ]; then
    
    # Get the name of the stack from the directory path for logging
    stack_name=$(basename "$stack")
    
    echo "--- Updating stack: $stack_name ---"
    
    # Navigate into the stack's directory
    cd "$stack" || exit
    
    # Pull the latest images for the services defined in the compose file
    echo "Pulling latest images for $stack_name..."
    docker compose pull
    
    # Recreate and restart the services in detached mode
    # This will only recreate containers whose images have been updated.
    echo "Applying updates for $stack_name..."
    docker compose up -d
    
    echo "--- Finished updating stack: $stack_name ---"
    echo
    
  else
    # Optional: Log if a directory doesn't contain a compose file
    echo "--- Skipping $(basename "$stack") (no ${COMPOSE_FILENAME} found) ---"
    echo
  fi
done

echo "----------------------------------------------------"
echo "All stacks have been processed."
echo "----------------------------------------------------"

