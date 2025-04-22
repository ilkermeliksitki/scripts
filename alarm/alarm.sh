#!/usr/bin/bash

# alarm.sh - Set an alarm with optional message

if [ -z "$1" ]; then
    echo "Usage: $0 <duration (e.g., 5*60)> [optional message]"
    exit 1
fi

# evaluate time by using bc in seconds and catch error
time_secs=$(echo "$1" | bc 2>/dev/null)
if [ $time_secs -le 0 ]; then
    echo "Error: Invalid duration, please use a number bigger than 0."
    exit 1
fi

# message
# remove the first argument with shift
shift
msg="${*:-⏰ Time\'s up!}"

echo "alarm set for $time_secs seconds..."
sleep "$time_secs"

# notify
notify-send "⏰ Alarm" "$msg" &
paplay /home/melik/Documents/projects/scripts/alarm/voice.mp3 2>/dev/null

