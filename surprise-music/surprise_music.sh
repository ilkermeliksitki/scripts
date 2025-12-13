#!/bin/bash

# minimum and maximum wait times (in seconds)
MIN_WAIT=240
MAX_WAIT=600
DEFAULT_DIR="$HOME/Music"
PLAY_DURATION=80
FADE_IN_DURATION=30
FADE_OUT_DURATION=30

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

    # Start mpv paused to allow seeking before playback
    mpv --no-video --input-ipc-server="$SOCKET" --volume="$LAST_VOLUME" --pause "$1" &

    MPV_PID=$!

    # wait for socket to be ready
    for i in {1..10}; do
        if [[ -S "$SOCKET" ]]; then
            break
        fi
        sleep 0.5
    done

    # check duration, seek, and apply fade
    SEEK_POS=0
    if [[ -S "$SOCKET" ]]; then
        DURATION=$(echo '{ "command": ["get_property", "duration"] }' | socat - "$SOCKET" 2>/dev/null | jq -r .data)

        # check if DURATION is a valid number
        if [[ "$DURATION" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            # convert float to int for comparison
            DURATION_INT=${DURATION%.*}

            if (( DURATION_INT > PLAY_DURATION )); then
                # calculate max seek position: duration - play_limit
                MAX_SEEK=$(( DURATION_INT - PLAY_DURATION ))
                if (( MAX_SEEK > 0 )); then
                    SEEK_POS=$(( RANDOM % MAX_SEEK ))
                    echo "⏩ Long file detected ($DURATION_INT s). Seeking to $SEEK_POS s."
                    echo '{ "command": ["seek", '$SEEK_POS', "absolute"] }' | socat - "$SOCKET" 2>/dev/null >/dev/null
                fi
            fi
        fi

        # determine playback end time (absolute file time)
        # it stops at SEEK_POS + PLAY_DURATION or DURATION_INT, whichever is smaller
        PLAY_END_TIME=$(( SEEK_POS + PLAY_DURATION ))

        # check against duration (using integer comparison)
        if (( PLAY_END_TIME > DURATION_INT )); then
             PLAY_END_TIME=$DURATION_INT
        fi

        # calculate fade-out start
        FADE_OUT_START=$(( PLAY_END_TIME - FADE_OUT_DURATION ))
        # ensure non-negative
        if (( FADE_OUT_START < 0 )); then FADE_OUT_START=0; fi

        # construct filter string with fade-in and universal fade-out
        FADE_IN_STRING="afade=t=in:st=${SEEK_POS}:d=${FADE_IN_DURATION}"
        FADE_OUT_STRING="afade=t=out:st=${FADE_OUT_START}:d=${FADE_OUT_DURATION}"
        AF_STRING="$FADE_IN_STRING,$FADE_OUT_STRING"

        # apply filters
        echo '{ "command": ["set_property", "af", "'"$AF_STRING"'"] }' | socat - "$SOCKET" 2>/dev/null >/dev/null

        # unpause
        echo '{ "command": ["set_property", "pause", false] }' | socat - "$SOCKET" 2>/dev/null >/dev/null
    fi

    START_TIME=$(date +%s)

    # track volume changes and enforce duration limit
    while kill -0 "$MPV_PID" 2>/dev/null; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$(( CURRENT_TIME - START_TIME ))

        if (( ELAPSED >= PLAY_DURATION )); then
            echo "⏰ Time limit reached ($PLAY_DURATION s). Stopping playback."
            kill "$MPV_PID" 2>/dev/null
            break
        fi

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

