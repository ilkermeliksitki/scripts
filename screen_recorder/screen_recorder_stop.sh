#!/bin/bash

PID_FILE="/tmp/ffmpeg_screen_recording.pid"
OUT_TRACKER="/tmp/ffmpeg_screen_recording_output.tmp"
SAVE_FLAG_FILE="/tmp/ffmpeg_screen_recording_save_flag.tmp"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  kill -SIGINT "$PID"
  sleep 1  # Give ffmpeg time to finalize the file

  # Check if we should save the recording
  SAVE_RECORDING=false
  if [ -f "$SAVE_FLAG_FILE" ]; then
    SAVE_RECORDING=$(cat "$SAVE_FLAG_FILE")
  fi

  if [ -f "$OUT_TRACKER" ]; then
    FILE=$(cat "$OUT_TRACKER")
    if [ "$SAVE_RECORDING" = true ]; then
      notify-send "Recording stopped" "Saved to: $FILE"
    else
      notify-send "Recording stopped" "No file saved (temporary recording)"
      # Clean up temporary file
      sleep 1  # Give ffmpeg extra time to finish
      rm -f "$FILE"
    fi
  else
    notify-send "Recording stopped" "Output file unknown"
  fi

  rm -f "$PID_FILE" "$OUT_TRACKER" "$SAVE_FLAG_FILE"
else
  notify-send "No active recording found"
fi

# go back to default mode (from screen-recorder mode)
i3-msg mode "default"
