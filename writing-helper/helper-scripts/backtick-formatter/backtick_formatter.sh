#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# create a function to notify the user
notify_user() {
    notify-send "$1"
}

# Check if xclip or xsel is available
if command -v xclip >/dev/null 2>&1; then
    CLIP_GET="xclip -selection clipboard -o"
    CLIP_SET="xclip -selection clipboard"
else
    notify_user "xclip not found, please install it."
    exit 1
fi

# read from clipboard
original=$($CLIP_GET)

# replace backticks with <span class='codei'>...</span>
formatted=$(echo "$original" | sed -E "s/\`([^\\\`]+)\`/<span class='codei'>\1<\/span>/g")

# output to clipboard
echo "$formatted" | $CLIP_SET

