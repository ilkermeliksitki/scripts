#!/bin/bash

# Get battery status from acpi
BATTERY_LEVEL=$(acpi -b | grep -P -o '[0-9]+(?=%)')

# Define the battery percentage threshold
CRITICAL_LEVEL=10
echo "Battery level is ${BATTERY_LEVEL}%"

# Export environment variables for PulseAudio
export XDG_RUNTIME_DIR=/run/user/1000

if [ "$BATTERY_LEVEL" -le "$CRITICAL_LEVEL" ]; then
    # Send notification (with access to the graphical session)
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send -u critical "Battery low!" "Battery level is ${BATTERY_LEVEL}%. Please plug in your charger."

    # Play a warning sound (replace with your preferred sound file) four times
    for i in {1..2}; do
        paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
    done
fi
