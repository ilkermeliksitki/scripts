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
        echo -n '\dfrac{}{}' | xclip -selection clipboard
        notify_user "Fraction snippet copied to clipboard"
        ;;
    "text")
        echo -n '\text{}' | xclip -selection clipboard
        notify_user "Text snippet copied to clipboard"
        ;;
    "infty")
        echo -n '\int_{-\infty}^{\infty}' | xclip -selection clipboard
        notify_user "Infinity snippet copied to clipboard"
        ;;
    "code_inline")
        echo -n '<span class="codei"></span>' | xclip -selection clipboard
        notify_user "Inline code snippet for anki copied to clipboard"
        ;;
    "code_block")
        echo -en '<div class="code">\n\n</div>' | xclip -selection clipboard
        notify_user "Block code snippet for anki copied to clipboard"
        ;;
    *)
        notify_user "Invalid argument, no action taken"
        ;;
esac

