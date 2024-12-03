#!/bin/bash

# Export environment variables for PulseAudio
export XDG_RUNTIME_DIR=/run/user/1000

DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    notify-send -u critical "Ventilation reminder" "It's time to open the window for some fresh air."

for _ in {1..5}; do
    paplay /usr/share/sounds/freedesktop/stereo/message.oga
done

