#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# create a function to notify the user
notify_user() {
    notify-send "$1"
}

case "$1" in
    "frac")
        echo -n '\dfrac{}{}' | xclip -selection clipboard
        notify_user "Fraction snippet copied to clipboard"
        ;;
    "text")
        echo -n '\text{}' | xclip -selection clipboard
        notify_user "Text snippet copied to clipboard"
        ;;
    "infty")
        echo -n '\int \limits_{-\infty}^{\infty}' | xclip -selection clipboard
        notify_user "Infinity snippet copied to clipboard"
        ;;
    "sum")
        echo -n '\sum \limits_{i=1}^{n}' | xclip -selection clipboard
        notify_user "Summation snippet copied to clipboard"
        ;;
    *)
        notify_user "Invalid argument, no action taken"
        ;;
esac

