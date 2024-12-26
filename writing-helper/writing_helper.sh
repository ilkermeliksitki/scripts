#!/bin/bash

# create a function to notify the user
notify_user() {
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "$1"
}

case "$1" in
    "mathjax_block")
        echo -n '<anki-mathjax block="true"></anki-mathjax>' | xclip -selection clipboard
        notify_user "anki-mathjax snippet copied to clipboard"
        ;;
    "mathjax_inline")
        echo -n '<anki-mathjax></anki-mathjax>' | xclip -selection clipboard
        notify_user "anki-mathjax snippet copied to clipboard"
        ;;
    "frac")
        echo -n '\frac{}{}' | xclip -selection clipboard
        notify_user "Fraction snippet copied to clipboard"
        ;;
    *)
        notify_user "Invalid argument, no action taken"
        ;;
esac

