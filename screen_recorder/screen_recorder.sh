#!/bin/bash

# Select area with slop
eval $(slop -f "W=%w H=%h X=%x Y=%y")

# Output file name
OUT_FILE="screencast_$(date +%Y-%m-%d_%H-%M-%S).mp4"

# Output directory
OUT_DIR="$HOME/Videos/screencasts"

# create output directory if it doesn't exist
if [ ! -d "$OUT_DIR" ]; then
  mkdir -p "$OUT_DIR"
fi

# Check if selection was made
if [ -z "$W" ]; then
  echo "No area selected. Exiting."
  exit 1
fi

# Print selected area
echo "Selected area: Width=$W, Height=$H, X=$X, Y=$Y"

# Start recording with ffmpeg
ffmpeg -f x11grab -r 30 -s "${W}x${H}" -i :0.0+"$X,$Y" \
-c:v libx264 -preset ultrafast $OUT_FILE

