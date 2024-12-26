#!/bin/bash

# create a function to notify the user
notify_user() {
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "$1"
}

case "$1" in
    "mathjax")
        # without a newline character
        echo -n '<anki-mathjax block="true">...</anki-mathjax>' | xclip -selection clipboard
        notify_user "anki-mathjax snippet copied to clipboard"
        ;;
    "frac")
        echo -n '\frac{}{}' | xclip -selection clipboard
        notify_user "Fraction snippet copied to clipboard"
        ;;
    *)
        echo "Usage: $0 {mathjax|example2}"
        ;;
esac

