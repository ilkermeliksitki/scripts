#!/bin/bash

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
else
    notify-send "Failed to start recording. Check $LOG_FILE"
    rm -f "$TMP_FILE"
fi

