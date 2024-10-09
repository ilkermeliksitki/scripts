#!/bin/bash

# Get battery status from acpi
BATTERY_LEVEL=$(acpi -b | grep -P -o '[0-9]+(?=%)')

# Define the battery percentage threshold
CRITICAL_LEVEL=15

# Export environment variables for PulseAudio
export XDG_RUNTIME_DIR=/run/user/1000

# Define the path for AC status (=1 if connected, =0 if disconnected)
AC_STATUS_FILE="/sys/class/power_supply/AC0/online"

if [ "$BATTERY_LEVEL" -le "$CRITICAL_LEVEL" ] && [ "$(cat "$AC_STATUS_FILE")" -eq 0 ] ; then
    # Send notification (with access to the graphical session)
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send -u critical "Battery low!" "Battery level is ${BATTERY_LEVEL}%. Please plug in your charger."

    # Play a warning sound (2 times: suiable with suspend-error.oga sound)
    for _ in {1..2}; do
        paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
    done
fi
