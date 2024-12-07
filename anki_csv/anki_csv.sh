#!/bin/bash

# CSV file name
CSV_FILE="/home/melik/Documents/projects/scripts/anki_csv/anki_items.csv"

# create a function to add the anki item
add_anki_item() {
    local front=$1
    local back=$2
    local topic=$3
    # check if the file exists
    if [[ ! -f "$CSV_FILE" ]]; then
        # create the file and add the header
        echo "front,back,topic" > "$CSV_FILE"
    fi

    echo "\"$front\",\"$back\",\"$topic\"" >> "$CSV_FILE"
}

# prompting for the word and definition
read -p "Enter front: " front
read -p "Enter back: " back
read -p "Enter topic: " topic

# call the function
add_anki_item "$front" "$back" "$topic"

echo "Front: $front, Back: $back, Topic: $topic are added to the CSV file."
