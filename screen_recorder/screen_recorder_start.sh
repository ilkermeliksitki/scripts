#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-s] [-h]"
    echo "  -s    Save the recording to file (default: no save)"
    echo "  -h    Show this help message"
    exit 1
}

# Default behavior: don't save
SAVE_RECORDING=false

# Parse command-line arguments
while getopts ":sh" opt; do
    case ${opt} in
        s ) # Save recording
            SAVE_RECORDING=true
            ;;
        h ) # Help
            usage
            ;;
        \? ) # Invalid option
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done

# prompt the user for the duration in minutes using a popup
DURATION_MINUTES=$(zenity --entry --title="Screen Recorder Duration" --text="Enter recording duration in minutes (default infinity):")

# check if the user canceled the popup
if [ $? -ne 0 ]; then
    notify-send "Recording canceled"
    exit 1
fi

# validate that the input is a positive number
if [[ -n "$DURATION_MINUTES" ]]; then
    # check if input is a valid positive number (integer only for bash arithmetic)
    if ! [[ "$DURATION_MINUTES" =~ ^[0-9]+$ ]] || [[ "$DURATION_MINUTES" -eq 0 ]]; then
        notify-send "Invalid input: '$DURATION_MINUTES' is not a valid positive number. Using default duration."
        DURATION_MINUTES=""
    fi
fi

# Get selected area
eval "$(slop -f "W=%w H=%h X=%x Y=%y")"
[ -z "$W" ] && notify-send "No area selected" && exit 1

# Prepare output paths
OUT_DIR="$HOME/Videos/screencasts"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
PID_FILE="/tmp/ffmpeg_screen_recording.pid"
OUT_TRACKER="/tmp/ffmpeg_screen_recording_output.tmp"
LOG_FILE="/tmp/ffmpeg_recording.log"

# Set output file based on save flag
if [ "$SAVE_RECORDING" = true ]; then
    # Create output directory if it doesn't exist
    mkdir -p "$OUT_DIR"
    TMP_FILE="$OUT_DIR/screencast_${TIMESTAMP}.mp4"
    notify-send "Recording will be saved to: $TMP_FILE"
else
    # Use temporary file that will be deleted
    TMP_FILE="/tmp/screencast_temp_${TIMESTAMP}.mp4"
    notify-send "Recording without saving (use -s flag to save)"
fi

# default is 16666666 minutes (about 30 years)
DURATION_MINUTES=${DURATION_MINUTES:-16666666}
DURATION_SECONDS=$((DURATION_MINUTES * 60))

# Run ffmpeg recording vidoe and voice of screen
ffmpeg -y \
  -f x11grab -r 30 -s "${W}x${H}" -i ":0.0+$X,$Y" \
  -f pulse -i "$(pactl list short sources | grep monitor | awk '{print $2}')" \
  -c:v libx264 -preset ultrafast -movflags +faststart "$TMP_FILE" \
  &> "$LOG_FILE" &

FFMPEG_PID=$!

# Check if it actually started
sleep 1
if ps -p "$FFMPEG_PID" > /dev/null; then
    echo "$FFMPEG_PID" > "$PID_FILE"
    echo "$TMP_FILE" > "$OUT_TRACKER"
    echo "$SAVE_RECORDING" > "/tmp/ffmpeg_screen_recording_save_flag.tmp"
    notify-send "Recording started"

    # wait for the specified duration and then stop the recording
    sleep "$DURATION_SECONDS"
    if [ "$SAVE_RECORDING" = true ]; then
        kill -SIGINT "$FFMPEG_PID" && notify-send "Recording stopped after $DURATION_MINUTES minutes" "Saved to: $TMP_FILE"
    else
        kill -SIGINT "$FFMPEG_PID" && notify-send "Recording stopped after $DURATION_MINUTES minutes" "No file saved (temporary recording)"
        # Clean up temporary file
        sleep 2  # Give ffmpeg time to finish
        rm -f "$TMP_FILE"
    fi
else
    notify-send "Failed to start recording. Check $LOG_FILE"
    rm -f "$TMP_FILE"
fi

