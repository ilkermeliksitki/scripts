#!/bin/bash

PID_FILE="/tmp/ffmpeg_screen_recording.pid"
OUT_TRACKER="/tmp/ffmpeg_screen_recording_output.tmp"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  kill -SIGINT "$PID"
  sleep 1  # Give ffmpeg time to finalize the file

  if [ -f "$OUT_TRACKER" ]; then
    FILE=$(cat "$OUT_TRACKER")
    notify-send "Recording stopped" "Saved to: $FILE"
  else
    notify-send "Recording stopped" "Output file unknown"
  fi

  rm -f "$PID_FILE" "$OUT_TRACKER"
else
  notify-send "No active recording found"
fi

# go back to default mode (from screen-recorder mode)
i3-msg mode "default"
