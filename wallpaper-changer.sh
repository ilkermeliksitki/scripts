#!/bin/bash

# directory with wallpapers
wallpaper_dir=~/Pictures/wallpapers

# choose a random image except main.jpg (the current wallpaper)
random_image=$(ls "$wallpaper_dir" | grep -v "main.jpg" | shuf -n 1)

# rename the current wallpaper as a new random name
new_name=$(date +%s).jpg  # Use timestamp for a unique name
mv -v "$wallpaper_dir/main.jpg" "$wallpaper_dir/$new_name"

# rename the random image as main.jpg
mv -v "$wallpaper_dir/$random_image" "$wallpaper_dir/main.jpg"

