#!/bin/bash

# Export environment variables for PulseAudio
export XDG_RUNTIME_DIR=/run/user/1000

DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    notify-send "Ventilation reminder" "That's enough ventilation for now. Please close the window."

for _ in {1..3}; do
    paplay /usr/share/sounds/freedesktop/stereo/message.oga
done
