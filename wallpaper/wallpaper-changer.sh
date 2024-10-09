#!/bin/bash

# directory with wallpapers
wallpaper_dir=~/Pictures/wallpapers

# check if the directory exists
if [ ! -d "$wallpaper_dir" ]; then
    echo "Wallpaper directory not found: $wallpaper_dir" >&2
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "Wallpaper directory not found: $wallpaper_dir"
    exit 1
fi

# choose a random image except main.jpg (the current wallpaper)
random_image=$(ls "$wallpaper_dir" | grep -v "main.jpg" | shuf -n 1)

if [ -z "$random_image" ]; then
    echo "No suitable wallpapers found in $wallpaper_dir" >&2
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "No wallpapers found in $wallpaper_dir"
    exit 1
fi

# rename the current wallpaper as a new random name
new_name=$(date +%s).jpg  # Use timestamp for a unique name
mv -v "$wallpaper_dir/main.jpg" "$wallpaper_dir/$new_name" || exit 1

# rename the random image as main.jpg
mv -v "$wallpaper_dir/$random_image" "$wallpaper_dir/main.jpg" || exit 1

