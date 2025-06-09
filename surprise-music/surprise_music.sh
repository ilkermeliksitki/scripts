#!/bin/bash

# minimum and maximum wait times (in seconds)
MIN_WAIT=5
MAX_WAIT=20

# default music directory
DEFAULT_DIR="$HOME/Music"

# use first argument if provided, else default
TARGET=${1:-$DEFAULT_DIR}

# check if input is a directory or a file
if [[ -f "$TARGET" ]]; then
    while true; do
        echo "▶️ Playing: $(basename "$TARGET")"
        mpv --no-video "$TARGET"

        SLEEP_TIME=$(( RANDOM % (MAX_WAIT - MIN_WAIT + 1) + MIN_WAIT ))
        echo "⏸️ Waiting for $SLEEP_TIME seconds before next surprise..."
        sleep "$SLEEP_TIME"
    done

elif [[ -d "$TARGET" ]]; then
    while true; do
        FILE=$(find "$TARGET" -type f \( -iname "*.mp3" -o -iname "*.webm" -o -iname "*.ogg" \) | shuf -n 1)
        if [[ -n "$FILE" ]]; then
            echo "▶️ Playing: $(basename "$FILE")"
            mpv --no-video "$FILE"

            SLEEP_TIME=$(( RANDOM % (MAX_WAIT - MIN_WAIT + 1) + MIN_WAIT ))
            echo "⏸️ Waiting for $SLEEP_TIME seconds before next surprise..."
            sleep "$SLEEP_TIME"
        else
            echo "❌ No music files found in directory."
            exit 1
        fi
    done
else
    echo "❌ Error: '$TARGET' is neither a valid file nor a folder."
    exit 1
fi

