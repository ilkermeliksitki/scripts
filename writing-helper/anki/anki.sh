#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# create a function to notify the user
notify_user() {
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
    "backtick_formatter")
        bash "$HOME/Documents/projects/scripts/writing-helper/helper-scripts/backtick-formatter/backtick_formatter.sh"
        notify_user "Clipboard updated with formatted HTML."
        ;;
    *)
        notify_user "Invalid argument, no action taken"
        ;;
esac

