#!/bin/bash

DEVICE_ID=18
STATE=$(xinput list-props $DEVICE_ID | grep "Device Enabled" | awk '{print $NF}')

if [ "$STATE" -eq 1 ]; then
    xinput disable $DEVICE_ID
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "Touchpad Disabled"
else
    xinput enable $DEVICE_ID
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "Touchpad Enabled"
fi

