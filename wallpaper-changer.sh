#!/bin/bash

# Directory with wallpapers
wallpaper_dir=~/Pictures/wallpapers

# Choose a random image except main.jpg (the current wallpaper)
random_image=$(ls "$wallpaper_dir" | grep -v "main.jpg" | shuf -n 1)
echo $random_image

# Move the current wallpaper to a new random name
new_name=$(date +%s).jpg  # Use timestamp for a unique name
mv "$wallpaper_dir/main.jpg" "$wallpaper_dir/$new_name"

# Copy the random image to main.jpg
cp "$wallpaper_dir/$random_image" "$wallpaper_dir/main.jpg"

