#!/bin/bash

# Select area with slop
eval $(slop -f "W=%w H=%h X=%x Y=%y")

# Check if selection was made
if [ -z "$W" ]; then
  echo "No area selected. Exiting."
  exit 1
fi

# Print selected area
echo "Selected area: Width=$W, Height=$H, X=$X, Y=$Y"

# Start recording with ffmpeg
ffmpeg -f x11grab -r 30 -s "${W}x${H}" -i :0.0+"$X,$Y" \
-c:v libx264 -preset ultrafast output.mp4

