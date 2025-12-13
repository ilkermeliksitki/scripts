#!/bin/bash

# minimum and maximum wait times (in seconds)
MIN_WAIT=240
MAX_WAIT=600
DEFAULT_DIR="$HOME/Music"

# Use last volume or fallback to 50
VOLUME_FILE="/tmp/mpv-volume"
LAST_VOLUME=$(cat "$VOLUME_FILE" 2>/dev/null || echo 50)

# catch Ctrl-C to stop everything
trap "echo -e '\n🛑 Interrupted. Exiting...'; exit 0" SIGINT

# use first argument if provided, else default
TARGET=${1:-$DEFAULT_DIR}

random_sleep() {
    SLEEP_TIME=$(( RANDOM % (MAX_WAIT - MIN_WAIT + 1) + MIN_WAIT ))
    echo "⏸️ Waiting for $SLEEP_TIME seconds before next surprise..."
    sleep "$SLEEP_TIME"
}

# running mpv with ipc to control volume across instances
play_with_tracking() {
    SOCKET="/tmp/mpv-socket"

    # ensuring old socket is removed
    [[ -e "$SOCKET" ]] && rm "$SOCKET"

    mpv --no-video --input-ipc-server="$SOCKET" --volume="$LAST_VOLUME" --af="afade=t=in:st=0:d=10" "$1" &

    MPV_PID=$!

    # wait for socket to be ready
    for i in {1..10}; do
        if [[ -S "$SOCKET" ]]; then
            break
        fi
        sleep 0.5
    done

    # track volume changes periodically
    while kill -0 "$MPV_PID" 2>/dev/null; do
        if [[ -S "$SOCKET" ]]; then
            VOL=$(echo '{ "command": ["get_property", "volume"] }' | socat - "$SOCKET" 2>/dev/null | jq -r .data)
            if [[ "$VOL" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo "$VOL" > "$VOLUME_FILE"
                LAST_VOLUME="$VOL"
            fi
        fi
        sleep 1
    done
}

# check if input is a directory or a file
if [[ -f "$TARGET" ]]; then
    while true; do
        echo "▶️ Playing: $(basename "$TARGET")"
        play_with_tracking "$TARGET"
        random_sleep
    done

elif [[ -d "$TARGET" ]]; then
    while true; do
        FILE=$(find "$TARGET" -type f \( -iname "*.mp3" -o -iname "*.webm" -o -iname "*.ogg" \) | shuf -n 1)
        if [[ -n "$FILE" ]]; then
            echo "▶️ Playing: $(basename "$FILE")"
            play_with_tracking "$FILE"
            random_sleep
        else
            echo "❌ No music files found in directory."
            exit 1
        fi
    done
else
    echo "❌ Error: '$TARGET' is neither a valid file nor a folder."
    exit 1
fi

