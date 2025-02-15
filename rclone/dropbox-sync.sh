#!/bin/bash

# Default source and destination for Dropbox sync
DEFAULT_SOURCE="dropbox:"
DEFAULT_REMOTE="$HOME/Dropbox"

# Function to display usage information
usage() {
    echo "Usage: $0 [-s source] [-d destination]"
    echo "  -s    Specify the source directory to sync (default: $DEFAULT_SOURCE)"
    echo "  -d    Specify the rclone remote destination (default: $DEFAULT_REMOTE)"
    exit 1
}

# Parse command-line arguments
while getopts ":s:d:" opt; do
    case ${opt} in
        s ) # Source directory
            SOURCE="$OPTARG"
            ;;
        d ) # Destination remote
            REMOTE="$OPTARG"
            ;;
        \? ) # Invalid option
            usage
            ;;
    esac
done

# Use default values if not provided by the user
SOURCE="${SOURCE:-$DEFAULT_SOURCE}"
REMOTE="${REMOTE:-$DEFAULT_REMOTE}"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed. Please install rclone and try again."
    exit 1
fi

# Sync the specified source to the destination
echo "Syncing from $SOURCE to $REMOTE ..."
rclone sync -vL "$SOURCE" "$REMOTE"

# Check if the sync was successful
if [ $? -eq 0 ]; then
    echo "Sync completed successfully."
else
    echo "Error: Sync failed. Please check your configuration."
fi

