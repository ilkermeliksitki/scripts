#!/bin/bash

# prompt the user for the duration in minutes using a popup
DURATION_MINUTES=$(zenity --entry --title="Screen Recorder Duration" --text="Enter recording duration in minutes (default infinity):")

# check if the user canceled the popup
if [ $? -ne 0 ]; then
    notify-send "Recording canceled"
    exit 1
fi

# Get selected area
eval "$(slop -f "W=%w H=%h X=%x Y=%y")"
[ -z "$W" ] && notify-send "No area selected" && exit 1

# Prepare output paths
OUT_DIR="$HOME/Videos/screencasts"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
TMP_FILE="$OUT_DIR/screencast_${TIMESTAMP}.mp4"
PID_FILE="/tmp/ffmpeg_screen_recording.pid"
OUT_TRACKER="/tmp/ffmpeg_screen_recording_output.tmp"
LOG_FILE="/tmp/ffmpeg_recording.log"

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
    notify-send "Recording started"

    # wait for the specified duration and then stop the recording
    sleep "$DURATION_SECONDS"
    kill -SIGINT "$FFMPEG_PID" && notify-send "Recording stopped after $DURATION_MINUTES minutes"
else
    notify-send "Failed to start recording. Check $LOG_FILE"
    rm -f "$TMP_FILE"
fi

